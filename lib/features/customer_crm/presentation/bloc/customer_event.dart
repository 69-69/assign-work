part of 'customer_bloc.dart';

/// Events
///
sealed class CustomerEvent<T> extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class GetCustomers<T> extends CustomerEvent<T> {}

class RefreshCustomers<T> extends CustomerEvent<T> {}

class GetCustomersByIds<T> extends CustomerEvent<T> {
  final List<String> documentIDs;

  const GetCustomersByIds({required this.documentIDs});

  @override
  List<Object?> get props => [documentIDs];
}

class GetCustomerById<T> extends CustomerEvent<T> {
  final Object? field;
  final String documentId;

  const GetCustomerById({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

class GetCustomersWithSameId<T> extends CustomerEvent<T> {
  final Object? field;
  final String documentId;

  const GetCustomersWithSameId({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

/*/// For Generating Short UID [GetShortIDEvent]
class GetShortIDEvent<T> extends CustomerEvent<T> {}*/

class SearchCustomers<T> extends CustomerEvent<T> {
  /// Query_Term / Search_Term [query]
  final String query;

  /// First_Field_Name[primaryField]
  final Object? primaryField;

  /// Second_Field_Name [optionalField]
  final Object? optionalField;

  /// Third_Field_Name[secondaryField]
  final Object? secondaryField;

  /// Fourth_Field_Name[tertiaryField]
  final Object? tertiaryField;

  const SearchCustomers({
    this.primaryField,
    this.optionalField,
    this.secondaryField,
    this.tertiaryField,
    required this.query,
  });

  @override
  List<Object?> get props => [
    primaryField,
    optionalField,
    secondaryField,
    tertiaryField,
    query,
  ];
}

class AddCustomer<T> extends CustomerEvent<T> {
  final T data;

  ///NOTE: If not provided, Firestore will assign a unique ID (documentId) [documentId]
  final String? documentId;

  const AddCustomer({this.documentId, required this.data});

  @override
  List<Object?> get props => [documentId, data];
}

/// T data: Generic Data Update: using Model-Class
///   --OR-- Note:: use Generic or Map data update
/// Map? mapData: `Map<String, dynamic>` Data Update
class UpdateCustomer<T> extends CustomerEvent<T> {
  final T? data;
  final Map<String, dynamic>? mapData;
  final String documentId;

  const UpdateCustomer({required this.documentId, this.data, this.mapData});

  @override
  List<Object?> get props => [data, documentId];
}

class DeleteCustomer<T> extends CustomerEvent<T> {
  final String documentId;

  const DeleteCustomer({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

/// Internal events for state updates
class _CustomersLoaded<T> extends CustomerEvent<T> {
  final List<T> data;

  const _CustomersLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _ShortIDLoaded<T> extends CustomerEvent<T> {
  final T shortID;

  const _ShortIDLoaded(this.shortID);

  @override
  List<Object?> get props => [shortID];
}

class _CustomerLoaded<T> extends CustomerEvent<T> {
  final T data;

  const _CustomerLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _CustomerError extends CustomerEvent {
  final String error;

  const _CustomerError(this.error);

  @override
  List<Object?> get props => [error];
}
