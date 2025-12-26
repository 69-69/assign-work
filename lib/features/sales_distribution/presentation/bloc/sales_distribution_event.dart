part of 'sales_distribution_bloc.dart';

/// Events
///
sealed class SalesDistributionEvent<T> extends Equatable {
  const SalesDistributionEvent();

  @override
  List<Object?> get props => [];
}

class GetSalesDistributions<T> extends SalesDistributionEvent<T> {}

class RefreshSalesDistributions<T> extends SalesDistributionEvent<T> {}

class GetSalesDistributionsByIds<T> extends SalesDistributionEvent<T> {
  final List<String> documentIDs;

  const GetSalesDistributionsByIds({required this.documentIDs});

  @override
  List<Object?> get props => [documentIDs];
}

class GetSalesDistributionById<T> extends SalesDistributionEvent<T> {
  final Object? field;
  final String documentId;

  const GetSalesDistributionById({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

class GetSalesDistributionsWithSameId<T> extends SalesDistributionEvent<T> {
  final Object? field;
  final String documentId;

  const GetSalesDistributionsWithSameId({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

class SearchSalesDistribution<T> extends SalesDistributionEvent<T> {
  /// Query_Term / Search_Term [query]
  final String query;

  /// First_Field_Name[field]
  final Object? field;

  /// Second_Field_Name [optField]
  final Object? optField;

  /// Third_Field_Name[auxField]
  final Object? auxField;

  const SearchSalesDistribution({
    this.field,
    this.optField,
    this.auxField,
    required this.query,
  });

  @override
  List<Object?> get props => [field, optField, auxField, query];
}

class AddSalesDistribution<T> extends SalesDistributionEvent<T> {
  final T data;

  ///NOTE: If not provided, Firestore will assign a unique ID (documentId) [documentId]
  final String? documentId;

  const AddSalesDistribution({this.documentId, required this.data});

  @override
  List<Object?> get props => [documentId, data];
}

/// T data: Generic Data Update: using Model-Class
///   --OR-- Note:: use Generic or Map data update
/// Map? mapData: `Map<String, dynamic>` Data Update
class UpdateSalesDistribution<T> extends SalesDistributionEvent<T> {
  final T? data;
  final Map<String, dynamic>? mapData;
  final String documentId;

  const UpdateSalesDistribution({
    required this.documentId,
    this.data,
    this.mapData,
  });

  @override
  List<Object?> get props => [data, mapData, documentId];
}

/// Add/Update Audit Log (History) for SalesDistribution [AuditSalesDistribution]
class AuditSalesDistribution<T> extends SalesDistributionEvent<T> {
  final Map<String, dynamic>? log;
  final String documentId;

  const AuditSalesDistribution({required this.documentId, this.log});

  @override
  List<Object?> get props => [log, documentId];
}

class DeleteSalesDistribution<T> extends SalesDistributionEvent<T> {
  final T documentId;

  const DeleteSalesDistribution({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

/// Internal events for state updates
class _SalesDistributionsLoaded<T> extends SalesDistributionEvent<T> {
  final List<T> data;

  const _SalesDistributionsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _ShortIDLoaded<T> extends SalesDistributionEvent<T> {
  final T shortID;

  const _ShortIDLoaded(this.shortID);

  @override
  List<Object?> get props => [shortID];
}

class _SalesDistributionLoaded<T> extends SalesDistributionEvent<T> {
  final T data;

  const _SalesDistributionLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _SalesDistributionLoadError extends SalesDistributionEvent {
  final String error;

  const _SalesDistributionLoadError(this.error);

  @override
  List<Object?> get props => [error];
}
