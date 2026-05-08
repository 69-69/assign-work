/// [businessTypeToIndustries] List of Business Types and their industries
Map<String, List<String>> businessTypeToIndustries = {
  'Select Business type': [],
  'Manufacturer': [
    'Automotive',
    'Pharmaceuticals / Life Sciences',
    'Food & Beverage',
    'Electronics & High Tech',
    'Apparel / Textiles',
    'Chemicals',
    'Aerospace & Defense',
    'Construction',
    'Agriculture',
    'Mining & Metals',
    'Food Production',
    'Energy and Utilities',
    'Furniture',
    'Packaging',
    'Medical Devices',
    'Personal Care & Cosmetics',
  ],
  'Distributor': [
    'Retail Stores',
    'Pharmaceuticals / Life Sciences',
    'Food & Beverage',
    'Apparel / Textiles',
    'Chemicals',
    'Electronics & High Tech',
    'Automotive',
    'Logistics, Supply Chain',
    'E-commerce',
    'Furniture',
    'Construction Materials',
    'Medical Devices',
    'Books & Media',
    'Luxury Goods',
  ],
  'Wholesaler': [
    'Food & Beverage',
    'Apparel / Textiles',
    'Electronics & High Tech',
    'Retail Stores',
    'E-commerce',
    'Luxury Goods',
    'Furniture',
    'Sports & Fitness',
  ],
  'Retailer': [
    'Retail Stores',
    'Apparel / Textiles',
    'Food & Beverage',
    'Consumer Electronics',
    'Healthcare',
    'E-commerce',
    'Pharmacies',
    'Luxury Goods',
    'Home Goods',
    'Sports & Fitness',
    'Toys & Games',
  ],
  'Service Provider': [
    'Healthcare',
    'Education',
    'IT, Telecommunications',
    'Financial Services',
    'Hospitality',
    'Professional Services',
    'Media & Entertainment',
    'Insurance',
    'Transportation',
    'Legal Services',
    'Advertising / Marketing',
    'Real Estate',
    'Architecture / Design',
    'Security / Risk Management',
  ],
  'Contract Manufacturer': [
    'Pharmaceuticals / Life Sciences',
    'Electronics & High Tech',
    'Apparel / Textiles',
    'Automotive',
    'Food Production',
    'Furniture',
    'Medical Devices',
    'Personal Care & Cosmetics',
  ],
  'Franchisee': [
    'Food & Beverage',
    'Retail Stores',
    'Hospitality',
    'Healthcare',
    'E-commerce',
    'Education',
    'Fitness',
    'Cleaning Services',
    'Entertainment',
  ],
  'Dropshipper': [
    'Retail Stores',
    'Consumer Goods',
    'Apparel / Textiles',
    'E-commerce',
    'Health & Beauty',
    'Home & Garden',
    'Pet Supplies',
  ],
  'Importer / Exporter': [
    'Agriculture',
    'Apparel / Textiles',
    'Electronics & High Tech',
    'Food & Beverage',
    'Chemicals',
    'Retail Stores',
    'Luxury Goods',
    'Furniture',
    'Medical Devices',
    'Construction Materials',
  ],
  'Project-Based Business': [
    'Construction',
    'Engineering',
    'Aerospace & Defense',
    'Oil & Gas / Energy',
    'Energy and Utilities',
    'Architecture / Design',
    'Environmental Services',
    'Renewable Energy',
    'Technology & Software Development',
  ],
  'Technology Company': [
    'Software',
    'Hardware',
    'Cloud Services',
    'Artificial Intelligence',
    'Cybersecurity',
    'Internet of Things (IoT)',
  ],
  'Non-Profit Organization': [
    'Healthcare',
    'Education',
    'Environment',
    'Social Services',
    'Relief & Aid',
  ],
};

/// [paymentTerms] When the payment is due and if any discounts apply
/// Open (Credit) Account - 3days Net
const paymentTerms = [
  {'id': 'select', 'term': 'Select Payment terms'},
  {
    'id': 'net_15',
    'term': 'Net 15 – Full payment due within 15 days of invoice',
  },
  {
    'id': 'net_30',
    'term': 'Net 30 – Full payment due within 30 days of invoice',
  },
  {
    'id': 'net_45',
    'term': 'Net 45 – Full payment due within 45 days of invoice',
  },
  {
    'id': 'net_60',
    'term': 'Net 60 – Full payment due within 60 days of invoice',
  },
  {
    'id': 'net_10_2_30',
    'term':
        '2/10 Net 30 – 2% discount if paid within 10 days; full due in 30 days',
  },
  {
    'id': 'open_3',
    'term': 'Open Account – Full payment due within 3 days of invoice',
  },
  {
    'id': 'advance_delivery',
    'term':
        '50% Advance, 50% on Delivery – Partial upfront payment, remainder on delivery',
  },
  {'id': 'cod', 'term': 'Cash on Delivery (COD) – Full payment upon delivery'},
  {
    'id': 'due_on_receipt',
    'term': 'Due on Receipt – Full payment due immediately upon invoicing',
  },
  {
    'id': 'cash_in_advance',
    'term': 'Cash in Advance (CIA) – Full payment before delivery',
  },
  {
    'id': 'milestone',
    'term': 'Milestone Payments – Based on project phases or deliverables',
  },
  {'id': 'other', 'term': 'Other – Specify in Notes'},
];
/*const paymentTerms2 = [
  'Select Payment terms',
  'Net 15 – Full payment due within 15 days of invoice',
  'Net 30 – Full payment due within 30 days of invoice',
  'Net 45 – Full payment due within 45 days of invoice',
  'Net 60 – Full payment due within 60 days of invoice',
  '2/10 Net 30 – 2% discount if paid within 10 days; full due in 30 days',
  '50% Advance, 50% on Delivery – Partial upfront payment, remainder on delivery',
  'Cash on Delivery (COD) – Full payment upon delivery',
  'Due on Receipt – Full payment due immediately upon invoicing',
  'Cash in Advance (CIA) – Full payment before delivery',
  'Milestone Payments – Based on project phases or deliverables',
  'Other – Specify in Notes',
];*/

/// Get Specific Payment term by pay id [getPayTerm]
String? getPayTerm(String id) =>
    paymentTerms.firstWhere((p) => p['id'] == id)['term'];

/// [paymentMethod] How the payment is made (the financial instrument or channel)
const paymentMethod = [
  'Select Payment method',
  'cash',
  'credit',
  'cheque',
  'gift cards',
  'mobile money',
  'bank transfer',
  'cash in advance',
  'partial payment',
  'letter of credit',
  'payment upon delivery',
];

/*const currencyType = [
  {'code': 'Select currency', 'symbol': '-'},
  {'code': 'GHC', 'symbol': '₵'},
  {'code': 'USD', 'symbol': '\$'},
  {'code': 'EUR', 'symbol': '€'},
  {'code': 'GBP', 'symbol': '£'},
  {'code': 'CAD', 'symbol': 'C\$'},
  {'code': 'AUD', 'symbol': 'A\$'},
  {'code': 'CHF', 'symbol': 'CHF'},
  {'code': 'JPY', 'symbol': '¥'},
  {'code': 'NZD', 'symbol': 'NZ\$'},
  {'code': 'SGD', 'symbol': 'S\$'},
];*/

const List<({String code, String symbol, String country})> currencyType = [
  // Default
  (code: 'Select currency', symbol: '-', country: 'placeholder'),

  // Major global
  (code: 'USD', symbol: r'$', country: 'United States'),
  (code: 'EUR', symbol: '€', country: 'Eurozone'),
  (code: 'GBP', symbol: '£', country: 'United Kingdom'),
  (code: 'CAD', symbol: r'C$', country: 'Canada'),
  (code: 'AUD', symbol: r'A$', country: 'Australia'),
  (code: 'CHF', symbol: 'CHF', country: 'Switzerland'),
  (code: 'JPY', symbol: '¥', country: 'Japan'),
  (code: 'NZD', symbol: r'NZ$', country: 'New Zealand'),
  (code: 'SGD', symbol: r'S$', country: 'Singapore'),

  // Africa
  (code: 'GHS', symbol: '₵', country: 'Ghana'),
  (code: 'NGN', symbol: '₦', country: 'Nigeria'),
  (code: 'ZAR', symbol: 'R', country: 'South Africa'),
  (code: 'KES', symbol: 'KSh', country: 'Kenya'),
  (code: 'UGX', symbol: 'USh', country: 'Uganda'),
  (code: 'TZS', symbol: 'TSh', country: 'Tanzania'),
  (code: 'EGP', symbol: '£', country: 'Egypt'),
  (code: 'MAD', symbol: 'DH', country: 'Morocco'),
  (code: 'XOF', symbol: 'CFA', country: 'West Africa'),
  (code: 'XAF', symbol: 'CFA', country: 'Central Africa'),
  (code: 'RWF', symbol: 'FRw', country: 'Rwanda'),
  (code: 'ETB', symbol: 'Br', country: 'Ethiopia'),
  (code: 'ZMW', symbol: 'ZK', country: 'Zambia'),
  (code: 'MWK', symbol: 'MK', country: 'Malawi'),
  (code: 'BWP', symbol: 'P', country: 'Botswana'),
  (code: 'MUR', symbol: '₨', country: 'Mauritius'),
  (code: 'SCR', symbol: '₨', country: 'Seychellois'),
  (code: 'SLL', symbol: 'Le', country: 'Sierra Leon'),
  (code: 'GMD', symbol: 'D', country: 'Gambia'),
];

String formatCurrency(({String code, String symbol, String country}) c) {
  return '${c.code} ${c.symbol} - ${c.country}';
}

/// Get Specific Currency Symbol (Sign) by Code [getCurrencySign]
String? getCurrencySign(String code) =>
    currencyType.firstWhere((c) => c.code == code).symbol;
// currencyType.firstWhere((c) => c['code'] == code)['symbol'];

const paymentStatus = [
  'Select Payment status',
  'unpaid',
  'fully paid',
  'installment',
  'partially paid',
];

const invoiceType = [
  'Select Invoice type',
  'proforma invoice',
  'final invoice',
  'purchase order',
  'way bill',
  'receipt',
];

const sizeCategory = [
  'Select size',
  'small',
  'medium',
  'large',
  'x-large',
  'general',
];

/// Sales Statuses
const saleStatus = ['Select Sale status', 'pending', 'completed', 'returned'];

const deliveryTypes = [
  'Select Delivery type',
  'in-person',
  'car',
  'motor rider',
  'mini-van',
  'truck',
  'standard',
  'express',
  'scheduled',
  'curb-side',
  'same-day',
  'on-demand',
  'shipping',
];

/// Delivery Statuses
const deliveryStatus = [
  'Select Delivery status',
  'pending',
  'packed',
  'shipped / dispatched', // dispatched
  'in-transit',
  'delivered',
  'cancelled',
  'delayed',
];

/// Request For Quotation Statuses
const _rFqPrStatus = [
  'draft',
  'submitted',
  'open',
  'closed',
  'under-review',
  'awarded',
  'approved',
  'rejected',
  'cancelled',
];

/// Request For Quotation Statuses
const requestForQuoteStatus = ['Select Quote status', ..._rFqPrStatus];

/// Purchase Requisition Statuses
const requisitionStatus = ['Select Requisition status', ..._rFqPrStatus];

/// Variant Attribute Priorities
const attributePriorities = {
  'Model': 0,

  // Core variant drivers
  'Gender': 1,
  'Color': 2,
  'Size': 3,
  'Style': 4,
  'Brand': 5,

  // Secondary attributes
  'Material': 6,
  'Pattern': 7,
  'Flavor': 8,
  'Edition': 9,
  'Collection': 10,

  // Technical / optional
  'Weight': 11,
  'Dimension': 12,
  'Volume': 13,
  'Configuration': 14,
  'Compatibility': 15,

  // Misc
  'Season': 16,
  'Condition': 17,
  'Grade': 18,
  'Packaging': 19,
  'Group': 20,
};

/// Variant Attribute Types
List<String> variantAttributes = [ 'Select Attribute', ...attributePriorities.keys];

/// Orders Sources
const orderSources = [
  'Select order source',
  'website',
  'in store',
  'mobile app',
];

/// Orders (SO) Statuses
const orderStatus = [
  'Select Order status',
  'pending',
  'processing',
  'production',
  'shipped / dispatched', // dispatched
  'completed',
  'cancelled',
  'returned',
];

/// Purchase Order (PO) Statuses
const purchaseOrderStatus = [
  'Select Order status',
  'draft',
  'pending approval',
  'approved',
  'sent to supplier',
  'confirmed by supplier',
  'partially fulfilled',
  'fulfilled',
  'received',
  'invoiced',
  'paid',
  'closed',
  'cancelled',
];

/// Sale Order: SO
final List<String> orderTypes = [
  'Select Order type',
  'sales order',
  'return order',
];

/// Miscellaneous Orders: any types of orders
final List<String> miscOrderTypes = [
  'Select Order type',
  'return order',
  'transfer order',
  'work order',
  'service order',
  'back order',
  'consignment order',
  'drop ship order',
  'replacement order',
  'subscription order',
];

/// [departmentsList] List of Departments in the company
final List<String> departmentsList = [
  'Select Internal departments',
  'Bakery',
  'Produce',
  'Butchery / Meat',
  'Seafood',
  'Grocery',
  'Dairy',
  'Frozen Foods',
  'Beverages',
  'Health & Beauty',
  'Pharmacy',
  'Household Supplies',
  'Maintenance',
  'Facilities',
  'Warehouse / Stockroom',
  'Receiving',
  'Cash Office',
  'Customer Service',
  'IT / Technical',
  'Finance / Accounting',
  'HR / Admin',
  'Security',
  'Store Management',
  'other',
];

const workspaceCategories = [
  'Select Business type',
  'Retail Stores',
  'Pharmacies',
  'Healthcare',
  'Manufacturing',
  'Wholesale',
  'Hospitality',
  'Construction',
  'Transportation',
  'Financial Services',
  'Insurance',
  'E-commerce',
  'Real Estate Firms',
  'IT, Telecommunications',
  'Logistics, Supply Chain',
  'Education',
  'Professional Services',
  'Agriculture',
  'Food Production',
  'Energy and Utilities',
];
