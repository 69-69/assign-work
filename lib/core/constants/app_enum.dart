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

/// [paymentTerms] When the payment is due and if any discounts apply
const paymentTerms = [
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
];

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

const currencyType = [
  'Select currency',
  'GHC',
  'USD',
  'EUR',
  'GBP',
  'CAD',
  'AUD',
  'CHF',
  'JPY',
  'NZD',
  'SGD',
];

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

const itemCategory = [
  'Select category',
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

/// Request For Quotation & Purchase Requisition Statuses
const _rFqPrStatus = [
  'draft',
  'submitted',
  'open',
  'closed',
  'under-review',
  'awarded',
  'rejected',
  'cancelled',
];

/// Request For Quotation Statuses
const requestForQuoteStatus = ['Select Quote status', ..._rFqPrStatus];

/// Purchase Requisition Statuses
const requisitionStatus = ['Select Requisition status', ..._rFqPrStatus];

/// Orders Sources
const orderSources = ['order source', 'website', 'in store', 'mobile app'];

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

/// User Guide Categories
final List<String> userGuideCategories = [
  'agent',
  'setup',
  'pos',
  'crm',
  'inventory',
  'procurement',
  'warehouse',
];
