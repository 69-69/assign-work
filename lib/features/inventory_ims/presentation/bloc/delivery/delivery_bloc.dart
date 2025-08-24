import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/delivery_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/sale_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryBloc extends InventoryBloc<Delivery> {
  final FirebaseFirestore _firestore;

  DeliveryBloc({required super.firestore})
    : _firestore = firestore,
      super(
        collectionPath: deliveryDBCollectionPath,
        fromFirestore: (data, id) => Delivery.fromMap(data, id),
        toFirestore: (delivery) => delivery.toMap(),
        toCache: (delivery) => delivery.toCache(),
      );

  // Process Delivery Status and Update Order
  Future<void> isDelivered(String orderNumber) async {
    // Updates order status and records sales based on delivery information
    _updateOrderAndItemAndRecordSales(orderNumber);

    // Emits an event to update internal state or trigger UI refresh with updated delivery data
    add(GetInventories<Delivery>());
  }

  /// If the delivery status is changed to "delivered",
  /// then update the order status to "completed", update product quantity and record new Sales [updateOrderAndProductAndRecordSales]
  Future<void> _updateOrderAndItemAndRecordSales(String orderNumber) async {
    try {
      // Get a reference to the 'orders' collection in Firestore
      final orderColRef = _firestore.collection(ordersDBCollectionPath);

      // Query Firestore for documents where the 'orderNumber' matches the provided order number
      final querySnapshot = await orderColRef
          .where('orderNumber', isEqualTo: orderNumber.trim())
          .get();

      // Check if any documents were returned by the query
      if (querySnapshot.docs.isNotEmpty) {
        // Execute parallel operations for each document
        final futures = querySnapshot.docs.map((docSnapshot) async {
          final docId = docSnapshot.id;
          final orderToMap = docSnapshot.data();

          // Update the order status to 'completed'
          final updateOrderStatusFuture = orderColRef.doc(docId).update({
            'status': 'completed',
          });

          // Update Item Stock Quantity and record sales
          final updateItemQtyAndRecordSalesFuture =
              _updateItemQtyAndRecordSales(orderToMap); /*querySnapshot.size*/

          // Wait for both operations to complete
          await Future.wait([
            updateOrderStatusFuture,
            updateItemQtyAndRecordSalesFuture,
          ]);
        }).toList();

        // Await completion of all futures
        await Future.wait(futures);
      }
    } catch (e) {
      // Handle any errors that occur during the process
      // print('Error updating order and product: $e');
    }
  }

  // Function to update the item quantity and trigger record new sales
  Future<void> _updateItemQtyAndRecordSales(Map<String, dynamic> order) async {
    try {
      int orderQuantity = order['quantity'];

      // Construct a reference to the document of the product in Firestore
      final docRef = _firestore
          .collection(itemsDBCollectionPath)
          .doc(order['itemId']);

      // Retrieve the current data of the product document from Firestore
      final docSnapshot = await docRef.get();

      // Check if the document exists and has data
      if (docSnapshot.exists) {
        final itemData = docSnapshot.data();
        if (itemData != null) {
          // Convert the Firestore data into a Product object using a factory method
          final fromItem = Item.fromMap(itemData, docSnapshot.id);

          if (fromItem.quantity > 0) {
            // Calculate the new outStock & quantity after updating
            final newQty = fromItem.quantity - orderQuantity;
            final newOutStock = fromItem.outOfStock + orderQuantity;

            // Execute parallel operations: update product quantity and create a new sale record
            await Future.wait([
              // Update product quantity & out of Stock in Firestore-DB
              docRef.update({'quantity': newQty, 'outOfStock': newOutStock}),

              // Add a new sale record with updated order details
              _addNewSales(order, fromItem.costPrice),
            ]);
          } else {
            // print('Product quantity is not sufficient for the update.');
          }
        } else {
          // print('Product data is null.');
        }
      } else {
        // print('Document does not exist.');
      }
    } catch (e) {
      // Handle any errors that occur during the process
      // print('Error updating product quantity and recording sales: $e');
    }
  }

  Future<void> _addNewSales(
    Map<String, dynamic> order,
    double costPrice,
  ) async {
    try {
      // Create a new Sale object with the given data
      final fromSale = Sale.fromMap(order, '');
      final profit = fromSale.calculateProfit(costPrice);

      // Create a new Sale object with updated status and profit
      final newSale = fromSale.copyWith(status: 'completed', profit: profit);

      // Convert the new Sale object to a Map format for Firestore
      final saleData = newSale.toMap();

      // Get a reference to the 'sales' collection in Firestore
      final colRef = _firestore.collection(salesDBCollectionPath);

      // Query Firestore to check if a sale with the same invoice number already exists
      final querySnap = await colRef
          .where('invoiceNumber', isEqualTo: fromSale.invoiceNumber)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        // Update existing sale if found
        final existingDocRef = querySnap.docs.first.reference;
        await existingDocRef.update(saleData);
      } else {
        // Create a new sale record if no matching document is found
        await colRef.add(saleData);
      }
    } catch (e) {
      // Log or handle any errors that occur during the process
      // print('Error adding or updating sale: $e');
    }
  }

  /*
  Future<void> _addNewSales(Map<String, dynamic> data, double costPrice) async {
    // Create a new Sale object by combining the existing document data with the new status
    final fromSale = Sale.fromMap(data, '');
    final profit = fromSale.calculateProfit(costPrice);

    // update sales object/model
    final newSale = fromSale.copyWith(status: 'completed', profit: profit);

    // Convert the new Sale object back to a Map format for use in Firestore
    final toMap = newSale.toMap();

    final colRef = _firestore.collection(salesDBCollectionPath);
    QuerySnapshot querySnap = await colRef
        .where('invoiceNumber', isEqualTo: fromSale.invoiceNumber)
        .limit(1)
        .get();

    // Check if there are any documents that match the query
    if (querySnap.size > 0) {
      // Update existing sale
      DocumentSnapshot docSnap = querySnap.docs.first;
      await docSnap.reference.set(toMap);
    } else {
      // Create / Add New Sale
      await colRef.add(toMap);
    }
  }

  Future<void> _updateProductQtyAndRecordSales(Map<String, dynamic> data, int newStockQuantity) async {
    // Construct a reference to the document of the product in Firestore
    DocumentReference<Map<String, dynamic>> docRef =
    _firestore.collection(productsDBCollectionPath).doc(data['itemId']);

    // Check if the document ID is not empty (document exists in Firestore)
    if (docRef.id.isNotEmpty) {
      // Retrieve the current data of the product document from Firestore
      final doc = await docRef.get();

      // Convert the Firestore data into a Product object using a factory method
      final fromProduct = Product.fromMap(doc.data()!, doc.id);

      if (fromProduct.quantity > 0) {
        // Calculate the new stock quantity after updating
        final newQty = fromProduct.quantity - newStockQuantity;

        // Execute parallel operations: update product quantity and create a new sale record
        Future.wait([
          // Update the quantity of the product in Firestore with the new quantity
          docRef.update({'quantity': newQty}),

          // Add a new sale record with updated order details
          _addNewSales(data, fromProduct.costPrice),
        ]);
      }
    }
  }

  Future<void> _updateOrderAndProductAndRecordSales2(String orderNumber) async {
    try {
      // Get a reference to the 'orders' collection in Firestore
      final orderColRef = _firestore.collection(ordersDBCollectionPath);

      // Query Firestore for documents where the 'orderNumber' matches the delivery's order number
      final querySnapshot = await orderColRef
          .where('orderNumber', isEqualTo: orderNumber.trim())
          .get();

      // Check if any documents were returned by the query
      if (querySnapshot.size > 0) {
        // Iterate through each document in the query snapshot
        for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
          // Retrieve the document ID which will be used to update the document
          String docId = docSnapshot.id;

          // Retrieve the data of the document as a Map from the Firestore snapshot
          final orders = docSnapshot.data() as Map<String, dynamic>;

          // Execute parallel operations: update the order status, Product Quantity and create a new sale
          Future.wait([
            // Update the order status to 'completed'
            orderColRef.doc(docId).update({'status': 'completed'}),

            // Update Product Stock Quantity
            _updateProductQtyAndRecordSales(orders, querySnapshot.size),
          ]);
        }
      }
    } catch (e) {
      // Handle any errors that occur during the process
      Exception(e);
    }
  }
*/
}
