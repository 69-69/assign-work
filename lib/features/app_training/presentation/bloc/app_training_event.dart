part of 'app_training_bloc.dart';

/// Events
///
sealed class AppTrainingEvent<T> extends Equatable {
  const AppTrainingEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrainings<T> extends AppTrainingEvent<T> {}

class RefreshTrainings<T> extends AppTrainingEvent<T> {}

class LoadTrainingById<T> extends AppTrainingEvent<T> {
  final Object? field;
  final String documentId;

  const LoadTrainingById({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

class AddTraining<T> extends AppTrainingEvent<T> {
  final T data;

  ///NOTE: If not provided, Firestore will assign a unique ID (documentId) [documentId]
  final String? documentId;

  const AddTraining({this.documentId, required this.data});

  @override
  List<Object?> get props => [documentId, data];
}

/// T data: Generic Data Update: using Model-Class
///   --OR-- Note:: use Generic or Map data update
/// Map? mapData: `Map<String, dynamic>` Data Update
class UpdateTraining<T> extends AppTrainingEvent<T> {
  final T? data;
  final Map<String, dynamic>? mapData;
  final String documentId;

  const UpdateTraining({required this.documentId, this.data, this.mapData});

  @override
  List<Object?> get props => [data, documentId];
}

class DeleteTraining<T> extends AppTrainingEvent<T> {
  final T documentId;

  const DeleteTraining({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

/// Internal events for state updates
class _TrainingsLoaded<T> extends AppTrainingEvent<T> {
  final List<T> data;

  const _TrainingsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _TrainingLoaded<T> extends AppTrainingEvent<T> {
  final T data;

  const _TrainingLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _TrainingError extends AppTrainingEvent {
  final String error;

  const _TrainingError(this.error);

  @override
  List<Object?> get props => [error];
}
