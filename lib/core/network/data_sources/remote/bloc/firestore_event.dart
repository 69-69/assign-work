part of 'firestore_bloc.dart';

/// Events
///
sealed class FirestoreEvent<T> extends Equatable {
  const FirestoreEvent();

  @override
  List<Object?> get props => [];
}

class GetItems<T> extends FirestoreEvent<T> {}

class GetItemsByIDs<T> extends FirestoreEvent<T> {
  final List<String> documentIDs;

  const GetItemsByIDs({required this.documentIDs});

  @override
  List<Object?> get props => [documentIDs];
}

class GetItemById<T> extends FirestoreEvent<T> {
  final Object? field;
  final String documentId;

  const GetItemById({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

class GetItemsWithSameId<T> extends FirestoreEvent<T> {
  final Object? field;
  final String documentId;

  const GetItemsWithSameId({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

/// For Generating Short UID [GetShortID]
class GetShortID<T> extends FirestoreEvent<T> {}

class RefreshItems<T> extends FirestoreEvent<T> {}

class SearchItems<T> extends FirestoreEvent<T> {
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

  const SearchItems({
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

class AddItem<T> extends FirestoreEvent<T> {
  final T data;

  ///NOTE: If not provided, Firestore will assign a unique ID (documentId) [documentId]
  final String? documentId;

  const AddItem({this.documentId, required this.data});

  @override
  List<Object?> get props => [documentId, data];
}

/// T data: Generic Data Update: using Model-Class
///   --OR-- Note:: use Generic or Map data update
/// Map? mapData: `Map<String, dynamic>?` Data Update
class UpdateItem<T> extends FirestoreEvent<T> {
  final T? data;
  final Map<String, dynamic>? mapData;
  final String documentId;

  const UpdateItem({required this.documentId, this.data, this.mapData});

  @override
  List<Object?> get props => [data, documentId];
}

class DeleteItem<T> extends FirestoreEvent<T> {
  final T documentId;

  const DeleteItem({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

/// Internal events for state updates
class _ItemsLoaded<T> extends FirestoreEvent<T> {
  final List<T> data;

  const _ItemsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _ShortIDLoaded<T> extends FirestoreEvent<T> {
  final T shortID;

  const _ShortIDLoaded(this.shortID);

  @override
  List<Object?> get props => [shortID];
}

class _ItemLoaded<T> extends FirestoreEvent<T> {
  final T data;

  const _ItemLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _ItemLoadError extends FirestoreEvent {
  final String error;

  const _ItemLoadError(this.error);

  @override
  List<Object?> get props => [error];
}
