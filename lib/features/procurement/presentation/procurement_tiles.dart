import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/permission/procurement_permission.dart';
import 'package:flutter/material.dart';

/// Procurement & Supplier Management System App(PSM) Dashboard tiles [ProcurementTiles]
extension ProcurementTiles on dynamic {
  List<DashboardTile> get supplierManagementTiles {
    final tilesData = [
      {
        'label': 'suppliers - account',
        'icon': Icons.account_balance,
        'action': RouteNames.supplierAccount,
        'param': {},
        'access': _getValue(ProcurementPermission.createSuppliers),
        'description': 'create and manage supplier accounts',
      },
      {
        'label': 'suppliers - evaluation',
        'icon': Icons.star_half_outlined,
        'action': RouteNames.supplierEvaluation,
        'param': {},
        'access': _getValue(ProcurementPermission.evaluateSuppliers),
        'description':
            'track and rate supplier performance: quality, delivery, and communication',
      },
      {
        'label': 'contract - management',
        'icon': Icons.assignment_outlined,
        'action': RouteNames.contractManagement,
        'param': {},
        'access': _getValue(ProcurementPermission.manageContracts),
        'description':
            'manage supplier contracts, pricing terms, and service-level agreements',
      },

      /* {
        'label': 'quotation - comparison',
        'icon': Icons.compare_arrows_outlined,
        'action': RouteNames.rfqComparison,
        'param': {},
        'access': _getValue(ProcurementPermission.compareQuotations),
        'description': 'compare supplier quotations side by side before converting to a PO',
      },
      {
        'label': 'approval - workflow',
        'icon': Icons.verified_outlined,
        'action': RouteNames.procurementApprovals,
        'param': {},
        'access': _getValue(ProcurementPermission.approveProcurements),
        'description': 'manage and approve requisitions, RFQs, and POs according to rules',
      },
      {
        'label': 'procurement - reports',
        'icon': Icons.bar_chart,
        'action': RouteNames.procurementReports,
        'param': {},
        'access': _getValue(ProcurementPermission.viewProcurementReports),
        'description': 'analyze procurement trends, spending, supplier performance, and more',
      },*/
    ];

    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }

  List<DashboardTile> get procurementTiles {
    final tilesData = [
      {
        'label': 'purchase - requisition',
        'icon': Icons.request_page_outlined,
        'action': RouteNames.purchaseRequisition,
        'param': {},
        'access': _getValue(ProcurementPermission.managePRs),
        'description':
            'manage internal request by departments for needed items before a PO is created',
      },
      {
        'label': 'request - for quotes',
        'icon': Icons.request_page_outlined,
        'action': RouteNames.proRequestForQuote,
        'param': {},
        'access': _getValue(ProcurementPermission.manageRFQs),
        'description':
            'manage quotation requests to suppliers for pricing and terms',
      },
      {
        'label': 'purchase - order',
        'icon': Icons.paypal,
        'action': RouteNames.proPurchaseOrders,
        'param': {},
        'access': _getValue(ProcurementPermission.managePOs),
        'description': 'generate POs to suppliers to request goods or services',
      },
      {
        'label': 'suppliers - management',
        'icon': Icons.store_mall_directory_outlined,
        // local_shipping
        'action': RouteNames.supplierManagement,
        'param': {},
        'access': _getValue(ProcurementPermission.manageSuppliers),
        'description':
            'register, approve, and manage suppliers and vendor profiles',
      },
    ];

    final defaultTiles = tilesData
        .map((e) => DashboardTile.fromMap(e))
        .toList();

    return defaultTiles;
  }

  /*
Yes — **each of those modules** in your procurement system **requires its own form info (data capture)** to fulfill its role effectively. Below is a detailed explanation of **what kind of form data you need for each module**:

---

## ✅ **1. Purchase Orders**

**Purpose**: Finalize and send orders to suppliers.

### 🧾 Form Info:

* PO Number (auto-generated or manual)
* Supplier (selected from approved list)
* Delivery address
* Order date
* Delivery date
* Currency
* Payment terms
* Line items:

  * Product
  * Quantity
  * Unit price
  * Total price
* Taxes, Discounts
* Notes or special instructions
* Attachments (e.g., specifications)
* Approval status
* Created by / Approved by

---

## ✅ **2. Request for Quotation (RFQ)**

**Purpose**: Collect pricing info from suppliers.

### 🧾 Form Info:

* RFQ Number
* Products/services requested
* Quantity
* Target price (optional)
* Required delivery time
* List of invited suppliers
* RFQ issued date
* Quotation deadline
* Terms & conditions
* Attachments (drawings/specs)
* Status (draft, sent, closed)
* Responses (linked or stored in sub-table)

---

## ✅ **3. Purchase Requisition (PR)**

**Purpose**: Internal request from departments.

### 🧾 Form Info:

* Requisition Number
* Requested by (employee/department)
* Request date
* Priority (urgent, normal)
* Needed by date
* Purpose of request
* Line items:

  * Item name or category
  * Estimated quantity
  * Reason
* Attachments (e.g., memos, specs)
* Approval status
* Linked RFQ or PO (after processing)

---

## ✅ **4. Supplier Management**

**Purpose**: Register and manage vendors.

### 🧾 Form Info:

* Company name
* Supplier code
* Business type (manufacturer, distributor)
* Industry
* Contact info (email, phone, person)
* Address info
* Bank & tax details
* Products or services offered
* Documents (certifications, licenses)
* Approved/Blacklisted status
* Rating info (auto or manual)

\[📌 Already detailed earlier in our chat.]

---

## ✅ **5. Supplier Evaluation**

**Purpose**: Monitor supplier performance.

### 🧾 Form Info:

* Supplier name
* Evaluation period (date range)
* Categories:

  * Delivery time
  * Product/service quality
  * Communication
  * Compliance
* Score per category (slider or 1–5 stars)
* Overall score (average)
* Comments / notes
* Evaluated by (user/role)
* Linked POs or RFQs (optional)

---

## ✅ **6. Contract Management**

**Purpose**: Store and manage supplier terms & agreements.

### 🧾 Form Info:

* Contract number
* Supplier
* Contract title or summary
* Contract type (pricing, SLA, MOU)
* Start and end date
* Auto-renewal (yes/no)
* Contract amount/value
* Payment terms
* Scope of work / Deliverables
* Uploaded contract files
* Compliance flags (e.g., signed, notarized)
* Assigned manager
* Status (active, expired, terminated)

---

## ✅ **7. Quotation Comparison**

**Purpose**: Help select the best offer.

### 🧾 Form Info:

* RFQ reference
* List of responding suppliers
* Price per item
* Delivery timeline
* Discounts or offers
* Evaluation criteria

  * Cost
  * Value
  * Lead time
* Selected supplier
* Justification / Notes
* Approver comments

👉 This form is usually **auto-populated** from RFQ responses but includes **manual comparison fields and decision-making**.

---

## ✅ **8. Approval Workflow**

**Purpose**: Enforce multi-step authorization.

### 🧾 Form Info:

* Document type (PR, RFQ, PO, Contract)
* Document reference number
* Submitted by
* Approval steps:

  * Approver name/role
  * Status (pending, approved, rejected)
  * Comments
  * Approval date/time
* Current step & overall status
* Escalation route (optional)

👉 Often managed via **workflow engine or settings**, but each instance has a form log.

---

## ✅ **9. Procurement Reports**

**Purpose**: View procurement KPIs and trends.

### 🧾 Report Filters (Input Form):

* Date range
* Supplier name/category
* Product/service category
* Procurement type (PR, PO, RFQ)
* Department
* Status (approved, rejected, pending)
* Region / branch (if multi-location)

### 📊 Report Outputs (No form, but generated based on filters):

* Spend per supplier
* Number of RFQs vs. POs
* Average lead time
* PO cycle time
* Top-performing suppliers
* Blacklisted or expired suppliers

---

## 📝 Summary: Form Requirement Overview

| Module                | Has Form?   | Key Fields?   | Form Type           |
| --------------------- | ----------- | ------------- | ------------------- |
| Purchase Orders       | ✅           | Many          | Transaction form    |
| Request for Quotation | ✅           | Many          | Transaction form    |
| Purchase Requisition  | ✅           | Many          | Internal request    |
| Supplier Management   | ✅           | Extensive     | Master data form    |
| Supplier Evaluation   | ✅           | Focused       | Performance review  |
| Contract Management   | ✅           | Extensive     | Legal/attachment    |
| Quotation Comparison  | ✅           | Auto + Manual | Analysis form       |
| Approval Workflow     | ✅           | Structured    | Log form or process |
| Procurement Reports   | ✅ (filters) | Light         | Filter → Output     |

---

Let me know if you'd like a **Flutter UI wireframe**, **data model (Firestore or SQL)**, or form validation rules for any of these!

* */

  /*
 Common Subfeatures under the Procurement Module:| **Subfeature**                  | **Description**                                                          |
| ------------------------------- | ------------------------------------------------------------------------ |
| **Purchase Orders (POs)**       | Creating and managing orders for suppliers.                              |
| **Request for Quotation (RFQ)** | Sending quotation requests to vendors for pricing and terms.             |
| **Supplier/Vendor Management**  | Managing supplier information, performance, and communication.           |
| **Purchase Requisition**        | Internal request by departments for needed items before a PO is created. |
| **Approval Workflow**           | Custom rules for approval based on PO amount, department, or requester.  |
| **Contract Management**         | Maintaining supplier contracts and negotiated terms.                     |
| **Procurement Reports**         | Analytics for purchase history, supplier performance, cost savings, etc. |
| **Budget Check & Control**      | Ensuring procurement activities comply with budget constraints.          |

✅ Sub-Modules (Features) Under Supplier/Vendor Management
| **Sub-Module / Feature**                | **Description**                                                                                                    |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Supplier Registration / Onboarding**  | Capturing all necessary information about new vendors (company details, contacts, bank info, tax info, etc.).      |
| **Supplier Approval Workflow**          | Internal workflow to review and approve suppliers before they can be used. May include legal or compliance checks. |
| **Supplier Profile Management**         | Managing supplier records including contact info, products/services offered, certifications, compliance documents. |
| **Supplier Categorization**             | Grouping suppliers based on type (e.g., raw materials, services, logistics) or risk level.                         |
| **Supplier Qualification / Compliance** | Tracking documents like ISO certifications, licenses, tax documents, and expiration dates.                         |
| **Supplier Product Linking**            | Associating suppliers with the products or services they provide (used when generating POs or RFQs).               |
| **Supplier Rating & Performance**       | Evaluating suppliers based on delivery time, quality, price, responsiveness, etc. Often includes scoring.          |
| **Supplier Contracts / Agreements**     | Managing terms and conditions, pricing agreements, service-level agreements (SLAs), contract durations.            |
| **Blacklisting / Deactivation**         | Mechanism to deactivate or blacklist underperforming or non-compliant suppliers.                                   |
| **Communication & Messaging**           | Logs or features for tracking emails, negotiations, and notes between buyers and suppliers.                        |
| **Audit Trail / History**               | Keeping a record of changes to supplier profiles and performance over time.                                        |

*/

  /*
To build a **Supplier/Vendor Management form** in your **Flutter ERP system**, you'll want to capture all essential details needed for procurement, compliance, payments, and relationship tracking.

Here’s a complete breakdown of the **form info (fields)** grouped into **logical sections** for better UX and database structure:

---

## 🧾 **1. General Information**

| Field               | Field Name     | Type              | Notes                                             |
| ------------------- | -------------- | ----------------- | ------------------------------------------------- |
| Supplier Name       | `name`         | Text              | Required                                          |
| Supplier Code / ID  | `supplierCode` | Auto/Text         | Unique, may be auto-generated                     |
| Business Type       | `businessType` | Dropdown          | e.g., Manufacturer, Distributor, Service Provider |
| Industry            | `industry`     | Dropdown          | Optional (e.g., Construction, FMCG)               |
| Status              | `status`       | Toggle / Dropdown | Active / Inactive / Blacklisted                   |
| Description / Notes | `description`  | TextArea          | Optional notes about the supplier                 |

---

## 📞 **2. Contact Information**

| Field               | Field Name      | Type  |
| ------------------- | --------------- | ----- |
| Contact Person Name | `contactPerson` | Text  |
| Email Address       | `email`         | Email |
| Phone Number        | `phone`         | Text  |
| Alternative Phone   | `altPhone`      | Text  |
| Website             | `website`       | URL   |

---

## 🏢 **3. Address Details**

| Field            | Field Name     | Type             |
| ---------------- | -------------- | ---------------- |
| Country          | `country`      | Dropdown         |
| State / Province | `state`        | Dropdown or Text |
| City             | `city`         | Text             |
| Street Address   | `addressLine1` | Text             |
| Postal Code      | `postalCode`   | Text             |

---

## 💰 **4. Financial & Banking Details**

| Field               | Field Name      | Type     |                               |
| ------------------- | --------------- | -------- | ----------------------------- |
| Tax ID / VAT Number | `taxId`         | Text     |                               |
| Currency            | `currency`      | Dropdown | e.g., USD, EUR                |
| Bank Name           | `bankName`      | Text     |                               |
| Bank Account Number | `bankAccount`   | Text     |                               |
| IBAN / SWIFT Code   | `ibanSwiftCode` | Text     |                               |
| Payment Terms       | `paymentTerms`  | Dropdown | e.g., Net 30, Net 60, Advance |

---

## 📦 **5. Products / Services Offered**

| Field                  | Field Name          | Type                        |
| ---------------------- | ------------------- | --------------------------- |
| Product Categories     | `productCategories` | Multi-select                |
| Products Offered       | `productsSupplied`  | Multi-select / linked table |
| Minimum Order Quantity | `moq`               | Number                      |
| Lead Time (Days)       | `leadTimeDays`      | Number                      |
| Delivery Areas         | `deliveryZones`     | Multi-select / text         |

---

## 📂 **6. Compliance & Documents**

| Field                 | Field Name       | Type        |
| --------------------- | ---------------- | ----------- |
| Business License      | `licenseFile`    | File upload |
| ISO / Certifications  | `certifications` | Multi-file  |
| License Expiry Date   | `licenseExpiry`  | Date        |
| Insurance Certificate | `insuranceFile`  | File upload |
| NDA / Contracts       | `contracts`      | Multi-file  |

---

## ⭐ **7. Ratings / Performance**

| Field               | Field Name            | Type                |
| ------------------- | --------------------- | ------------------- |
| Overall Rating      | `rating`              | Star / Slider (0–5) |
| Delivery Timeliness | `deliveryRating`      | Slider              |
| Product Quality     | `qualityRating`       | Slider              |
| Communication       | `communicationRating` | Slider              |
| Review Notes        | `reviewNotes`         | TextArea            |

---

## 📜 **8. Internal Use (Optional)**

| Field                        | Field Name        | Type                   |
| ---------------------------- | ----------------- | ---------------------- |
| Internal Notes               | `internalNotes`   | TextArea               |
| Assigned Procurement Officer | `assignedOfficer` | Dropdown / user picker |
| Created By                   | `createdBy`       | System/User ID         |
| Created Date                 | `createdAt`       | Auto-filled            |
| Last Modified                | `updatedAt`       | Auto-filled            |

---

## 🧩 Optional Toggles / Checkboxes

| Label              | Field Name      | Purpose                                 |
| ------------------ | --------------- | --------------------------------------- |
| Approved Supplier  | `isApproved`    | Used to filter for RFQs/POs             |
| Preferred Supplier | `isPreferred`   | Used for auto-suggestion in procurement |
| Blacklisted        | `isBlacklisted` | Disables supplier from new orders       |

---

## 📝 Summary: Main Form Sections

1. **General Info**
2. **Contact Info**
3. **Address**
4. **Bank & Financial Details**
5. **Products/Services**
6. **Compliance/Documents**
7. **Ratings & Reviews**
8. **Internal/Administrative Info**

---

Let me know if you'd like:

* A **Flutter UI form layout**
* A **Firestore/SQL schema**
* A **validation ruleset**
* Or integration ideas with PO and RFQ modules.

* */
}

// Get name from enum
String _getValue(e) => getEnumName<ProcurementPermission>(e);
