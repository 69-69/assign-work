import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final String id; // Firestore doc ID or unique identifier
  final String companyName;
  final String supplierCode;
  final String businessType; // e.g., "manufacturer", "distributor"
  final String industry;

  final ContactInfo contactInfo;
  final AddressInfo addressInfo;

  final BankTaxInfo bankTaxInfo;
  final List<String> documents; // file paths or URLs

  final SupplierStatus status; // approved, blacklisted
  final List<String> productsOrServices;

  final RatingInfo rating;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.companyName,
    required this.supplierCode,
    required this.businessType,
    required this.industry,
    required this.contactInfo,
    required this.addressInfo,
    required this.bankTaxInfo,
    required this.documents,
    required this.status,
    required this.productsOrServices,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    companyName,
    supplierCode,
    businessType,
    industry,
    contactInfo,
    addressInfo,
    bankTaxInfo,
    documents,
    status,
    productsOrServices,
    rating,
    createdAt,
    updatedAt,
  ];
}

enum SupplierStatus { approved, blacklisted }

class ContactInfo extends Equatable {
  final String email;
  final String phone;
  final String contactPerson;

  const ContactInfo({
    required this.email,
    required this.phone,
    required this.contactPerson,
  });

  @override
  List<Object?> get props => [email, phone, contactPerson];
}

class BankTaxInfo extends Equatable {
  final String bankName;
  final String accountNumber;
  final String taxId;

  const BankTaxInfo({
    required this.bankName,
    required this.accountNumber,
    required this.taxId,
  });

  @override
  List<Object?> get props => [bankName, accountNumber, taxId];
}

class RatingInfo extends Equatable {
  final double? autoRating; // system-generated
  final double? manualRating; // user-assigned
  final String? notes;

  const RatingInfo({this.autoRating, this.manualRating, this.notes});

  @override
  List<Object?> get props => [autoRating, manualRating, notes];
}
