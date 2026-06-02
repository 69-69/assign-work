part of 'app_training_bloc.dart';

/// State
///
sealed class AppTrainingState<T> extends Equatable {
  const AppTrainingState();

  @override
  List<Object?> get props => [];
}

class LoadingTrainings<T> extends AppTrainingState<T> {}

class TrainingsLoaded<T> extends AppTrainingState<T> {
  final List<T> data;

  const TrainingsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class TrainingLoaded<T> extends AppTrainingState<T> {
  final T data;

  const TrainingLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class TrainingAdded<T> extends AppTrainingState<T> {
  final String? message;

  const TrainingAdded({this.message});

  @override
  List<Object?> get props => [message];
}

class TrainingUpdated<T> extends AppTrainingState<T> {
  final String? message;

  const TrainingUpdated({this.message});

  @override
  List<Object?> get props => [message];
}

class TrainingDeleted<T> extends AppTrainingState<T> {
  final String? message;

  const TrainingDeleted({this.message});

  @override
  List<Object?> get props => [message];
}

class TrainingDeleting<T> extends AppTrainingState<T> {}

class TrainingError<T> extends AppTrainingState<T> {
  final String error;

  const TrainingError(this.error);

  @override
  List<Object?> get props => [error];
}
