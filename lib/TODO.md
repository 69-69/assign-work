# @TODO for Tomorrow

-
    1. CRM - Customer
- --------------------------
    2. Workflow Approval Rules
    3. My Approvals
    4. Printouts
    5. Inventory
    6. Saved all CRUD operation ERRORS in
        `final errorLogCache = ErrorLogCache();
            errorLogCache.setError()`

-------------------------

# @Continue
    - Inform user when Generating Full BIN Locations
- ChatGPT QA:
    "im generating Full Bin Locations based on select ranges of 
    zone, aisle, racks, shelf. However, after user selection of the 
    ranges from the sublevels or sub-locations. 
    since the for-loop is still permutating or creating the list of ranges. 
    user needs to be prompted to so that user can wait before cling save button? how to do that?"
     
# 1- Refactor code `openStoresForm(` to check for 
# Store-Branches existingCodes in `lib/features/system_admin/presentation/screen/switch_store_locations/switch_store_locations_screen.dart`

# Master Data (BIN Location Code,UOM, PriceList, Payment Method&Type,)
- Connect Item Master to:
  - Stock Management
  - 
  - Procurement (PR,RFQ,PO)
  - POS
  - 
  - Sales & Distribution
    - Sales Quote
    - Sales Order
    - 
  - Inventory System
    - Stock management
      - Goods Receipt
      - Goods Issue
      - Goods Transfer
      - Stock Adjustment
      - Returns from Customer
      - Reserve Stock
      - 
# @TODO OLD Modules (These below modules will be remove entirely)
  - Inventory Module
    - stocking tab
    - orders tab
    - misc tab
    - deliveries tab
    - sales tab
    - payments tab
    - reports tab
    - finance tab
    - tracking tab
    - 
  - Warehouse Module





```shell
git init
git add .
git commit -m "resolved Creating and Saving Bin."
git branch -M main
git push -u origin main
```
