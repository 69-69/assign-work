part of 'user_guide_bloc.dart';

/// Events
///
sealed class GuideEvent<T> extends Equatable {
  const GuideEvent();

  @override
  List<Object?> get props => [];
}

class LoadGuides<T> extends GuideEvent<T> {}

class RefreshGuides<T> extends GuideEvent<T> {}

class LoadGuideById<T> extends GuideEvent<T> {
  final Object? field;
  final String documentId;

  const LoadGuideById({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

class AddGuide<T> extends GuideEvent<T> {
  final T data;

  ///NOTE: If not provided, Firestore will assign a unique ID (documentId) [documentId]
  final String? documentId;

  const AddGuide({this.documentId, required this.data});

  @override
  List<Object?> get props => [documentId, data];
}

/// T data: Generic Data Update: using Model-Class
///   --OR-- Note:: use Generic or Map data update
/// Map? mapData: `Map<String, dynamic>` Data Update
class UpdateGuide<T> extends GuideEvent<T> {
  final T? data;
  final Map<String, dynamic>? mapData;
  final String documentId;

  const UpdateGuide({required this.documentId, this.data, this.mapData});

  @override
  List<Object?> get props => [data, documentId];
}

class DeleteGuide<T> extends GuideEvent<T> {
  final T documentId;

  const DeleteGuide({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

/// Internal events for state updates
class _GuidesLoaded<T> extends GuideEvent<T> {
  final List<T> data;

  const _GuidesLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _GuideLoaded<T> extends GuideEvent<T> {
  final T data;

  const _GuideLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _GuideError extends GuideEvent {
  final String error;

  const _GuideError(this.error);

  @override
  List<Object?> get props => [error];
}
