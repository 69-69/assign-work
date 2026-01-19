import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

import 'crm_customer_helper.dart';

class Customer extends Equatable {
  static get _today => DateTime.now();

  final String id; // Firestore will assign a unique ID (documentId)
  final String storeNumber; // FK CompanyStore.storeNumber
  final String customerId;
  final String name;
  final String phone;
  final String altPhone;
  final String email;
  final String address;
  final String companyName;
  final DateTime? birthDay;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  Customer({
    this.id = '',
    required this.storeNumber,
    required this.customerId,
    required this.name,
    required this.phone,
    this.altPhone = '',
    this.address = '',
    this.email = '',
    this.companyName = '',
    DateTime? birthDay,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       birthDay = birthDay ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [Customer.fromMap]
  factory Customer.fromMap(Map<String, dynamic> data, String documentId) {
    return Customer(
      id: documentId,
      storeNumber: data['storeNumber'] ?? '',
      customerId: data['customerId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      altPhone: data['altPhone'] ?? '',
      address: data['address'] ?? '',
      email: data['email'] ?? '',
      companyName: data['companyName'] ?? '',
      birthDay: toDateTimeFn(data['birthDay']),
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'customerId': customerId,
    'name': name,
    'phone': phone,
    'altPhone': altPhone,
    'email': email,
    'address': address,
    'companyName': companyName,
    'birthDay': birthDay,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
  };

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['birthDay'] = birthDay?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['birthDay'] = birthDay?.toMilliseconds;
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  static get empty => Customer(
    customerId: '',
    storeNumber: '',
    name: '',
    phone: '',
    createdBy: '',
  );

  /// Use this to check if the Customer is the empty (e.g., not found).
  bool get isEmpty => identical(this, Customer.empty);

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Date Only in String [getBirthDay]
  String get getBirthDay => birthDay.dateOnly;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Customers
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  String get itemAsString => '$name - $customerId'.toTitle;

  /// [findCustomerById]
  static Iterable<Customer> findCustomerById(
    List<Customer> customers,
    String customerId,
  ) => customers.where((customer) => customer.customerId == customerId);

  /// [filterCustomersByDate]
  static List<Customer> filterCustomersByDate(
    List<Customer> customers, {
    bool isSameDay = true,
  }) {
    // If customer-name isNotEqual Auto-ID, & isToday or not isToday
    return customers
        .where(
          (c) =>
              !c.name.contains(autoID) && (isSameDay ? c.isToday : !c.isToday),
        )
        .toList();
  }

  /// Filter/search
  bool filterByAny(String filter) =>
      itemAsList.filterAny(filter) || id.filterAny(filter);

  /// copyWith method
  Customer copyWith({
    String? id,
    String? storeNumber,
    String? name,
    String? phone,
    String? altPhone,
    String? email,
    String? address,
    String? companyName,
    DateTime? birthDay,
    String? customerId,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      storeNumber: storeNumber ?? this.storeNumber,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      birthDay: birthDay ?? this.birthDay,
      companyName: companyName ?? this.companyName,
      customerId: customerId ?? this.customerId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    storeNumber,
    name,
    phone,
    altPhone,
    email,
    address,
    companyName,
    customerId,
    birthDay,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for Customers [itemAsList]
  List<String> get itemAsList => [
    id,
    customerId,
    storeNumber,
    name.toTitle,
    phone,
    altPhone,
    email,
    getBirthDay,
    address.toTitle,
    companyName.toTitle,
    createdBy.toTitle,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Customer ID',
    'Store Number',
    'Name',
    'Phone',
    'Alt-Phone',
    'Email',
    'Birth day',
    'Address / Location',
    'Company Name',
    'Created By',
    'Updated By',
    'Updated At',
  ];
}

class Customers extends Equatable {
  static get _today => DateTime.now();

  /// 1. Identification: These identify the customer.
  final String id;
  final String storeNumber; // FK CompanyStore.storeNumber
  final String customerId;
  final String name; // Company name or Individual name
  final CustomerType type;
  final CustomerStatus status;
  final String industry;
  final CustomerCategory category;

  /// 2. Contact Information Fields: How the company communicates with the customer.
  final String contactName; // Primary Contact Name
  final String phone;
  final String mobile;
  final String email;
  final String website;

  /// 3. Address Fields: Often multiple addresses are supported.
  final List<AddressInfo> addresses;

  /// 4. Relationship & Sales Fields: Used by sales and account managers.
  final String
  salesRepId; // Account Owner / Sales Representative handling this customer
  final LeadSource leadSource;
  final CustomerPriority priority;

  /// 5. Financial & ERP-Linked Fields: These connect CRM with ERP functions.
  final double creditLimit;
  final String paymentTerms;
  final String currency;
  final String taxId;

  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  Customers({
    this.id = '',
    required this.storeNumber,
    required this.customerId,
    required this.name,
    required this.type,
    required this.status,
    this.industry = '',
    required this.category,
    this.contactName = '',
    required this.phone,
    required this.mobile,
    required this.email,
    this.website = '',
    required this.addresses,
    required this.salesRepId,
    required this.leadSource,
    required this.priority,
    this.creditLimit = 0.0,
    this.paymentTerms = '',
    required this.currency,
    this.taxId = '',
    required this.createdBy,
    DateTime? createdAt,
    required this.updatedBy,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  factory Customers.fromMap(Map<String, dynamic> data, {String? docId}) {
    return Customers(
      id: docId ?? data['id'] ?? '',
      storeNumber: data['storeNumber'] ?? '',
      customerId: data['customerId'] ?? '',
      name: data['name'] ?? '',
      type: CrmCustomerUtil.typeFromString(data['type']),
      status: CrmCustomerUtil.statusFromString(data['status']),
      industry: data['industry'] ?? '',
      category: CrmCustomerUtil.categoryFromString(data['category']),
      phone: data['phone'] ?? '',
      mobile: data['mobile'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      addresses: AddressInfo.addresses(data['addresses']),
      salesRepId: data['salesRepId'] ?? '',
      leadSource: CrmCustomerUtil.leadSourceFromString(data['leadSource']),
      priority: CrmCustomerUtil.priorityFromString(data['priority']),
      creditLimit: '${data['creditLimit']}'.asDouble,
      paymentTerms: data['paymentTerms'] ?? '',
      currency: data['currency'] ?? '',
      taxId: data['taxId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt']),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'customerId': customerId,
    'name': name,
    'type': type.getName,
    'status': status.getName,
    'industry': industry,
    'category': category.getName,
    'phone': phone,
    'mobile': mobile,
    'email': email,
    'website': website,
    'addresses': addresses,
    'salesRepId': salesRepId,
    'leadSource': leadSource.getName,
    'priority': priority.getName,
    'creditLimit': creditLimit,
    'paymentTerms': paymentTerms,
    'currency': currency,
    'taxId': taxId,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
  };

  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  bool get isEmpty => customerId.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// [findCustomerById]
  static Iterable<Customer> findCustomerById(
    List<Customer> customers,
    String customerId,
  ) => customers.where((customer) => customer.customerId == customerId);

  /// [filterCustomersByDate]
  static List<Customer> filterCustomersByDate(
    List<Customer> customers, {
    bool isSameDay = true,
  }) {
    // If customer-name isNotEqual Auto-ID, & isToday or not isToday
    return customers
        .where(
          (c) =>
              !c.name.contains(autoID) && (isSameDay ? c.isToday : !c.isToday),
        )
        .toList();
  }

  /// Filter
  bool filterByAny(String filter) => {
    name,
    storeNumber,
    customerId,
    phone,
    mobile,
    email,
    name,
  }.contains(filter);

  Customers copyWith({
    String? id,
    String? storeNumber,
    String? customerId,
    String? name,
    CustomerType? type,
    CustomerStatus? status,
    String? industry,
    CustomerCategory? category,
    String? contactName,
    String? phone,
    String? mobile,
    String? email,
    String? website,
    List<AddressInfo>? addresses,
    String? salesRepId,
    LeadSource? leadSource,
    CustomerPriority? priority,
    double? creditLimit,
    String? paymentTerms,
    String? currency,
    String? taxId,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Customers(
      id: id ?? this.id,
      storeNumber: storeNumber ?? this.storeNumber,
      name: name ?? this.name,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      status: status ?? this.status,
      industry: industry ?? this.industry,
      category: category ?? this.category,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      website: website ?? this.website,
      addresses: addresses ?? this.addresses,
      salesRepId: salesRepId ?? this.salesRepId,
      leadSource: leadSource ?? this.leadSource,
      priority: priority ?? this.priority,
      creditLimit: creditLimit ?? this.creditLimit,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      currency: currency ?? this.currency,
      taxId: taxId ?? this.taxId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ToList for Customers [itemAsList]
  List<String> get itemAsList => [
    id,
    customerId,
    storeNumber,
    name.toTitle,
    phone,
    mobile,
    email,
    createdBy.toTitle,
    updatedBy.toTitle,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Customer ID',
    'Store Number',
    'Name',
    'Phone',
    'Mobile',
    'Email',
    'Created By',
    'Updated By',
  ];

  @override
  List<Object?> get props => [
    id,
    storeNumber,
    name,
    customerId,
    type,
    status,
    industry,
    category,
    phone,
    mobile,
    email,
    website,
    addresses,
    salesRepId,
    leadSource,
    priority,
    creditLimit,
    paymentTerms,
    currency,
    taxId,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];
}

/*In a **CRM system**, the **Customer (or Account) model** stores all key information needed to manage a customer relationship. The exact fields vary by CRM (Salesforce, SAP CRM, Dynamics, Odoo, etc.), but most systems share common core fields.

Below is a **standard, ERP/CRM-agnostic view**.

---

## 1. Basic / Identification Fields

These identify the customer.

* Customer ID / Account ID
* Customer Name (Company name or Individual name)
* Customer Type (Individual / Company)
* Status (Lead, Prospect, Active, Inactive)
* Industry
* Customer Category / Segment

---

## 2. Contact Information Fields

How the company communicates with the customer.

* Primary Contact Name
* Email Address
* Phone Number
* Mobile Number
* Website
* Fax (less common now)

---

## 3. Address Fields

Often multiple addresses are supported.

* Billing Address
* Shipping Address
* Street
* City
* State / Province
* Postal Code
* Country

---

## 4. Relationship & Sales Fields

Used by sales and account managers.

* Account Owner / Sales Representative
* Lead Source (Referral, Website, Campaign, etc.)
* Account Priority
* Customer Lifetime Value (CLV)
* Opportunity History (linked records)
* Last Contact Date

---

## 5. Financial & ERP-Linked Fields

These connect CRM with ERP functions.

* Credit Limit
* Payment Terms
* Currency
* Tax ID / VAT Number
* Price List
* Customer Group (Retail, Wholesale, Corporate)
* Linked ERP Customer Number

---

## 6. Marketing Fields

Used for campaigns and segmentation.

* Marketing Preferences (Email/SMS consent)
* Campaign Membership
* Communication Preferences
* Newsletter Subscription

---

## 7. Support & Service Fields

Used for after-sales service.

* Support Level / SLA
* Open Cases / Tickets (linked)
* Customer Satisfaction Score
* Warranty Information

---

## 8. System & Audit Fields

Automatically managed by the system.

* Created Date
* Last Modified Date
* Created By
* Last Updated By
* Notes / Activity History

---

## Simple summary
**Customer model =**
> Identity + Contact info + Relationship data + Financial link + Support history

---

## If you want, I can:
* Map these fields to a **specific CRM** (like Salesforce or SAP)
* Draw a **simple data model diagram**
* Explain the difference between **Lead vs Customer vs Account** in CRM systems
*/
