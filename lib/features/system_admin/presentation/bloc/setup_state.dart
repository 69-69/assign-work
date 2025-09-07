part of 'setup_bloc.dart';

/// State
///
sealed class SetupState<T> extends Equatable {
  const SetupState();

  @override
  List<Object?> get props => [];
}

class LoadingSetup<T> extends SetupState<T> {}

class SetupsLoaded<T> extends SetupState<T> {
  final List<T> data;

  const SetupsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class SetupLoaded<T> extends SetupState<T> {
  final T data;

  const SetupLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

// just
class SetupAdded<T> extends SetupState<T> {
  final String? message;

  const SetupAdded({this.message});

  @override
  List<Object?> get props => [message];
}

class SetupUpdated<T> extends SetupState<T> {
  final String? message;

  const SetupUpdated({this.message});

  @override
  List<Object?> get props => [message];
}

class SetupOverridden<T> extends SetupUpdated<T> {
  const SetupOverridden({required super.message});
}

class SetupDeleted<T> extends SetupState<T> {
  final String message;

  const SetupDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

class SetupError<T> extends SetupState<T> {
  final String error;

  const SetupError(this.error);

  @override
  List<Object?> get props => [error];
}

/*sealed class SetupState extends Equatable {
  const SetupState();

  @override
  List<Object?> get props => [];
}

class LoadingState extends SetupState {}

class DataLoadedState extends SetupState {
  final List<Inventory> data;

  const DataLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class DataAddedState extends SetupState {}

class DataUpdatedState extends SetupState {}

class DataDeletedState extends SetupState {}

class ErrorState extends SetupState {
  final String error;

  const ErrorState(this.error);

  @override
  List<Object?> get props => [error];
}*/
