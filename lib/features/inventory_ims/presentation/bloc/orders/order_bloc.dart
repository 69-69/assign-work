import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/delivery_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/order_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderBloc extends InventoryBloc<Orders> {
  final FirebaseFirestore _firestore;

  OrderBloc({required super.firestore})
    : _firestore = firestore,
      super(
        collectionPath: ordersDBColPath,
        fromFirestore: (data, id) => Orders.fromMap(data, id),
        toFirestore: (so) => so.toMap(),
        toCache: (so) => so.toCache(),
      );

  // Create New Delivery for Order
  Future<void> createNewDeliveryForOrder(
    String orderNumber,
    String storeNumber,
  ) async {
    // Creates a new Delivery object with initial data and adds it to Firestore
    final fromDelivery = Delivery.fromMap({
      'orderNumber': orderNumber,
      'storeNumber': storeNumber,
      'status': 'pending',
      'deliveryType': 'in-person',
      'remarks': 'assign delivery person to deliver these orders',
    }, '');

    // Converts the Delivery object to a Map format for Firestore
    final toDelivery = fromDelivery.toMap();

    // Adds the new delivery information to Firestore
    await _firestore.collection(deliveryDBColPath).add(toDelivery);

    // Triggers an event to update the state or UI with the new order data
    add(GetInventories<Orders>());
  }
}

/*class OrdersBloc extends InventoryBloc<Orders> {
  final FirebaseFirestore _firestore;

  OrdersBloc({required super.firestore})
      : _firestore = firestore,
        super(
          collectionPath: ordersDBCollectionPath,
          fromFirestore: (data, id) => Orders.fromMap(data, id),
          toFirestore: (order) => order.toMap(),
          toCache: (order) => order.toCache(),
        ) {
    /// Subscribe to events
    EventBusService.instance.on<DeliveryStatusUpdatedEvent>().listen((event) {
      _updateOrderStatus(event.orderNumber, event.deliveryStatus);
      debugPrint('Order-status: ${event.deliveryStatus}');
    });
  }

  Future<void> _updateOrderStatus(String orderNumber, String deliveryStatus) async {
    // Define your logic for updating order status based on delivery status
    String newOrderStatus =
        (deliveryStatus == 'delivered') ? 'completed' : 'pending';

    // Query for documents where 'orderNumber' equals the given orderNumber
    final querySnapshot = await _firestore
        .collection(ordersDBCollectionPath)
        .where('orderNumber', isEqualTo: orderNumber)
        .get();

    // Loop through the documents in the snapshot
    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      // Get the document ID for reference
      String docId = docSnapshot.id;

      // Update the 'status' field of each document
      await _firestore.collection(ordersDBCollectionPath).doc(docId).update({
        'status': newOrderStatus,
      });
    }

    /// Emit the updated state
    add(GetDataEvent<Orders>());
  }
}*/
