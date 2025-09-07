part of 'setup_bloc.dart';

/// Events
///
sealed class SetupEvent<T> extends Equatable {
  const SetupEvent();

  @override
  List<Object?> get props => [];
}

class GetSetups<T> extends SetupEvent<T> {
  const GetSetups();
}

class RefreshSetups<T> extends SetupEvent<T> {}

class GetSetupsByIds<T> extends SetupEvent<T> {
  final List<String> documentIDs;

  const GetSetupsByIds({required this.documentIDs});

  @override
  List<Object?> get props => [documentIDs];
}

class GetSetupById<T> extends SetupEvent<T> {
  final Object? field;
  final String documentId;

  const GetSetupById({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

class GetSetupsWithSameId<T> extends SetupEvent<T> {
  final Object? field;
  final String documentId;

  const GetSetupsWithSameId({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

/*/// For Generating Short UID [GetShortIDEvent]
class GetShortIDEvent<T> extends SetupEvent<T> {}*/

class SearchSetup<T> extends SetupEvent<T> {
  /// Query_Term / Search_Term [query]
  final String query;

  /// First_Field_Name[field]
  final Object? field;

  /// Second_Field_Name [optField]
  final Object? optField;

  /// Third_Field_Name[auxField]
  final Object? auxField;

  const SearchSetup({
    this.field,
    this.optField,
    this.auxField,
    required this.query,
  });

  @override
  List<Object?> get props => [field, optField, auxField, query];
}

class AddSetup<T> extends SetupEvent<T> {
  final T data;

  ///NOTE: If not provided, Firestore will assign a unique ID (documentId) [documentId]
  final String? documentId;

  const AddSetup({this.documentId, required this.data});

  @override
  List<Object?> get props => [documentId, data];
}

/// T data: Generic Data Update: using Model-Class
///   --OR-- Note:: use Generic or Map data update
/// Map? mapData: `Map<String, dynamic>` Data Update
class UpdateSetup<T> extends SetupEvent<T> {
  final T? data;
  final Map<String, dynamic>? mapData;
  final String documentId;

  const UpdateSetup({required this.documentId, this.data, this.mapData});

  @override
  List<Object?> get props => [data, documentId];
}

class OverrideSetup<T> extends UpdateSetup<T> {
  const OverrideSetup({required super.documentId, super.data, super.mapData});
}

class DeleteSetup<T> extends SetupEvent<T> {
  final T documentId;

  const DeleteSetup({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

/// Internal events for state updates
class _SetupsLoaded<T> extends SetupEvent<T> {
  final List<T> data;

  const _SetupsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _ShortIDLoaded<T> extends SetupEvent<T> {
  final T shortID;

  const _ShortIDLoaded(this.shortID);

  @override
  List<Object?> get props => [shortID];
}

class _SetupLoaded<T> extends SetupEvent<T> {
  final T data;

  const _SetupLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _SetupLoadError extends SetupEvent {
  final String error;

  const _SetupLoadError(this.error);

  @override
  List<Object?> get props => [error];
}
