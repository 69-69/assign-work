// Goods Receipt → adds quantity to stock (Inventory)
/*Inventory/Stocking Table:
* Inventory
    ---------
    id (PK)
    itemId (FK → Item.id)           // links to item definition
    warehouseId (FK → Warehouse.id) // where the item is
    locationId (FK → Location.id)   // optional, sub-location
    binId (FK → Bin.id)             // optional, bin/slot
    quantityOnHand                  // current stock available
    quantityReserved                // reserved for orders
    quantityOrdered                 // incoming GRs not yet received
    batchNumber (optional)          // if batches/lots are used
    expiryDate (optional)           // for perishable items
    lastUpdated                     // last stock change date/time */

class GoodsReceipt {}
