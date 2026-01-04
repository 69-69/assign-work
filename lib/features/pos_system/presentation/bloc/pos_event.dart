part of 'pos_bloc.dart';

/// Events
///
sealed class POSEvent<T> extends Equatable {
  const POSEvent();

  @override
  List<Object?> get props => [];
}

class GetPOSs<T> extends POSEvent<T> {}

class RefreshPOSs<T> extends POSEvent<T> {}

class GetPOSsByIds<T> extends POSEvent<T> {
  final List<String> documentIDs;

  const GetPOSsByIds({required this.documentIDs});

  @override
  List<Object?> get props => [documentIDs];
}

class GetPOSById<T> extends POSEvent<T> {
  final Object? field;
  final String documentId;

  const GetPOSById({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

class GetPOSsWithSameId<T> extends POSEvent<T> {
  final Object? field;
  final String documentId;

  const GetPOSsWithSameId({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

/*/// For Generating Short UID [GetShortIDEvent]
class GetShortIDEvent<T> extends POSEvent<T> {}*/

class SearchPOS<T> extends POSEvent<T> {
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

  const SearchPOS({
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

class AddPOS<T> extends POSEvent<T> {
  final T data;

  ///NOTE: If not provided, Firestore will assign a unique ID (documentId) [documentId]
  final String? documentId;

  const AddPOS({this.documentId, required this.data});

  @override
  List<Object?> get props => [documentId, data];
}

/// T data: Generic Data Update: using Model-Class
///   --OR-- Note:: use Generic or Map data update
/// Map? mapData: `Map<String, dynamic>` Data Update
class UpdatePOS<T> extends POSEvent<T> {
  final T? data;
  final Map<String, dynamic>? mapData;
  final String documentId;

  const UpdatePOS({required this.documentId, this.data, this.mapData});

  @override
  List<Object?> get props => [data, documentId];
}

class DeletePOS<T> extends POSEvent<T> {
  final T documentId;

  const DeletePOS({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

/// Internal events for state updates
class _POSLoaded<T> extends POSEvent<T> {
  final List<T> data;

  const _POSLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _ShortIDLoaded<T> extends POSEvent<T> {
  final T shortID;

  const _ShortIDLoaded(this.shortID);

  @override
  List<Object?> get props => [shortID];
}

class _SinglePOSLoaded<T> extends POSEvent<T> {
  final T data;

  const _SinglePOSLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _POSLoadError extends POSEvent {
  final String error;

  const _POSLoadError(this.error);

  @override
  List<Object?> get props => [error];
}
