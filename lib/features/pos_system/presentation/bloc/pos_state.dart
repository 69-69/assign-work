part of 'pos_bloc.dart';

/// State
///
sealed class POSState<T> extends Equatable {
  const POSState();

  @override
  List<Object?> get props => [];
}

class LoadingPOS<T> extends POSState<T> {}

class POSsLoaded<T> extends POSState<T> {
  final List<T> data;

  const POSsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class POSLoaded<T> extends POSState<T> {
  final T data;

  const POSLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

// just
class POSAdded<T> extends POSState<T> {
  final String? message;

  const POSAdded({this.message});

  @override
  List<Object?> get props => [message];
}

class POSUpdated<T> extends POSState<T> {
  final String? message;

  const POSUpdated({this.message});

  @override
  List<Object?> get props => [message];
}

class POSDeleting<T> extends POSState<T> {}

class POSDeleted<T> extends POSState<T> {
  final String? message;

  const POSDeleted({this.message});

  @override
  List<Object?> get props => [message];
}

class POSError<T> extends POSState<T> {
  final String error;

  const POSError(this.error);

  @override
  List<Object?> get props => [error];
}

/*sealed class POSState extends Equatable {
  const POSState();

  @override
  List<Object?> get props => [];
}

class LoadingState extends POSState {}

class DataLoadedState extends POSState {
  final List<POS> data;

  const DataLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class DataAddedState extends POSState {}

class DataUpdatedState extends POSState {}

class DataDeletedState extends POSState {}

class ErrorState extends POSState {
  final String error;

  const ErrorState(this.error);

  @override
  List<Object?> get props => [error];
}*/
