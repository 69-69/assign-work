import 'package:assign_erp/core/constants/unit_of_measure.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/// [ProLineItem] Represents an individual line item in Procurement
/// [ServiceLine] Represents an individual service line item in Procurement (e.g., for service POs)
class ServiceLine extends Equatable {
  static get _today => DateTime.now();

  final String serviceName;

  /// [quantity] represents the amount of service being procured (such as 3 hours, 2 days, u4 nits, etc.).
  final int quantity;
  final UnitOfMeasure unitOfMeasure;
  final double serviceRate; // $150 per hour

  /// Use Case [limitAmount]:
  /// Imagine a service contract where a vendor will provide consulting services, but the total
  /// value for the service cannot exceed $10,000. In this case, the limitAmount would be set to $10,000.
  /// If the service rate is $500 per day, and the service is billed daily,
  /// you can calculate how many days can be billed before the limit is reached.
  final double? limitAmount;

  /// Use Case [limitQuantity]:
  /// A service agreement states that the vendor will provide maintenance for up to 100 hours.
  /// In this case, the limitQuantity would be set to 100 hours.
  /// If the service is billed based on the number of hours worked,
  /// once the limitQuantity is reached, no more service can be provided under that PO.
  final int? limitQuantity;
  final DateTime expectedDate;
  final bool
  isServiceEntrySheetRequired; // Whether a service entry sheet is required for this line

  const ServiceLine({
    required this.serviceName,
    required this.quantity,
    this.unitOfMeasure = UnitOfMeasure.unknown,
    this.serviceRate = 0.0,
    this.limitAmount,
    this.limitQuantity,
    required this.expectedDate,
    this.isServiceEntrySheetRequired = true,
  });

  factory ServiceLine.fromMap(Map<String, dynamic> map) {
    return ServiceLine(
      serviceName: map['serviceName'] ?? '',
      quantity: int.tryParse('${map['quantity']}') ?? 0,
      unitOfMeasure: UOMHelper.fromString(map['unitOfMeasure']),
      serviceRate: double.tryParse('${map['serviceRate']}') ?? 0.0,
      limitAmount: map['limitAmount'] != null
          ? double.tryParse('${map['limitAmount']}')
          : null,
      limitQuantity: map['limitQuantity'],
      expectedDate: DateTime.tryParse(map['expectedDate']) ?? DateTime.now(),
      isServiceEntrySheetRequired: map['isServiceEntrySheetRequired'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'serviceName': serviceName,
    'quantity': quantity,
    'unitOfMeasure': getUnitOfMeasure,
    'serviceRate': serviceRate,
    'limitAmount': limitAmount,
    'limitQuantity': limitQuantity,
    'expectedDate': expectedDate.toIso8601String(),
    'isServiceEntrySheetRequired': isServiceEntrySheetRequired,
  };

  bool filterByAny(String filter) => serviceName.contains(filter);

  ServiceLine copyWith({
    String? serviceName,
    int? quantity,
    double? serviceRate,
    UnitOfMeasure? unitOfMeasure,
    double? limitAmount,
    int? limitQuantity,
    DateTime? expectedDate,
    bool? isServiceEntrySheetRequired,
  }) => ServiceLine(
    serviceName: serviceName ?? this.serviceName,
    quantity: quantity ?? this.quantity,
    serviceRate: serviceRate ?? this.serviceRate,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
    limitAmount: limitAmount ?? this.limitAmount,
    limitQuantity: limitQuantity ?? this.limitQuantity,
    expectedDate: expectedDate ?? this.expectedDate,
    isServiceEntrySheetRequired:
        isServiceEntrySheetRequired ?? this.isServiceEntrySheetRequired,
  );

  /// A singleton instance representing an empty/default ServiceLine.
  /// Used as a fallback when no matching service line is found.
  static final ServiceLine empty = ServiceLine(
    serviceName: '',
    quantity: 0,
    expectedDate: _today,
    serviceRate: 0.0,
    isServiceEntrySheetRequired: false,
  );

  /// Returns true if this instance is the singleton [empty] ServiceLine.
  bool get isEmpty => identical(this, ServiceLine.empty);

  bool get isNotEmpty => serviceName.isNotEmpty;

  String get getUnitOfMeasure => unitOfMeasure.getLabel;

  /// Calculate how many days can be billed
  int get maxDays => (limitAmount! / serviceRate).floor();

  /// Calculate remaining hours
  int get remainingHours => limitQuantity! - quantity;

  String get getExpectedDate => expectedDate.dateOnly;

  List<String> get serviceLineAsList => [
    serviceName.toTitle,
    '$quantity',
    getUnitOfMeasure.toTitle,
    '$serviceRate',
    limitAmount != null ? 'Limit: $limitAmount' : '',
    getExpectedDate,
    isServiceEntrySheetRequired ? 'Yes' : 'No',
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => const [
    'Service',
    'Qty',
    'UOM',
    'Rate',
    'Limit Amount',
    'Service Date',
    'Entry Sheet Required',
  ];

  @override
  List<Object?> get props => [
    serviceName,
    quantity,
    unitOfMeasure,
    serviceRate,
    limitAmount,
    limitQuantity,
    expectedDate,
    isServiceEntrySheetRequired,
  ];
}
