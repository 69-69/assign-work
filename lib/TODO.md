# @TODO - 
LINKEDIN-MSG: "Thank you for being our SMU panelist during the AT&T tour on Friday, 
April 17. It was an incredible experience, and we truly appreciate the effort 
you and your team put into making it happen."

## @Continue Tomorrow (Next Sprint)
    ## Reference master 
        - Item master
        - Item Variance & Attributes
    
    ##  Master Data (BIN Location Code, UOM, PriceList, Payment Method&Type,)
    - Item Master: adding taxes, warehouse and linking Item Master to
        - Procurement, Inventory, POS, Sales & Distribution
    > NOTE: watch item master link to warehouse on YouTube.com
    > REF Doc: lib/features/system_admin/presentation/setup_tiles.dart

-
- Workflow Approval Rules
- 
- My Approvals
- 
- Printouts
- 
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
- CRM - Customer
  - 
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

Item Master

### 🧾 Basic Information

* **Item Code / SKU** – Unique identifier
* **Item Name / Description**
* **Item Type** – Finished goods, raw material, service, etc.
* **Product Category / Group**

### 📦 Inventory Details

* **Unit of Measure (UOM)** – e.g., pieces, kg, liters
* **Stock Quantity**
* **Reorder Level / Safety Stock**
* **Warehouse / Storage Location**
* **Lot/Batch Number (if applicable)**
* **Serial Number (if applicable)**

### 💰 Pricing & Costing

* **Standard Cost / Purchase Cost**
* **Selling Price**
* **Currency**
* **Discount rules (optional)**

### 🏭 Procurement & Production

* **Preferred Supplier / Vendor**
* **Lead Time**
* **Bill of Materials (BOM)** (for manufactured items)
* **Make or Buy Indicator**

### 📊 Accounting Information

* **GL Accounts (Inventory, COGS, Revenue)**
* **Tax Category / Tax Code**

### 🚚 Sales & Distribution

* **Sales Unit**
* **Minimum Order Quantity**
* **Shipping Details / Weight / Dimensions**

### ⚙️ Other Fields

* **Status (Active/Inactive)**
* **Barcode**
* **Country of Origin**
* **Compliance / Regulatory info**

---


