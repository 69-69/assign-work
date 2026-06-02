part of 'procurement_bloc.dart';

/// State
///
sealed class ProcurementState<T> extends Equatable {
  const ProcurementState();

  @override
  List<Object?> get props => [];
}

class LoadingProcurement<T> extends ProcurementState<T> {}

class ProcurementsLoaded<T> extends ProcurementState<T> {
  final List<T> data;

  const ProcurementsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class ProcurementLoaded<T> extends ProcurementState<T> {
  final T data;

  const ProcurementLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

// just
class ProcurementAdded<T> extends ProcurementState<T> {
  final String? message;

  const ProcurementAdded({this.message});

  @override
  List<Object?> get props => [message];
}

class ProcurementUpdated<T> extends ProcurementState<T> {
  final String? message;

  const ProcurementUpdated({this.message});

  @override
  List<Object?> get props => [message];
}

class ProcurementDeleted<T> extends ProcurementState<T> {
  final String? message;

  const ProcurementDeleted({this.message});

  @override
  List<Object?> get props => [message];
}

class ProcurementDeleting<T> extends ProcurementState<T> {}

class ProcurementError<T> extends ProcurementState<T> {
  final String error;

  const ProcurementError(this.error);

  @override
  List<Object?> get props => [error];
}

/*sealed class ProcurementState extends Equatable {
  const ProcurementState();

  @override
  List<Object?> get props => [];
}

class LoadingState extends ProcurementState {}

class DataLoadedState extends ProcurementState {
  final List<Inventory> data;

  const DataLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class DataAddedState extends ProcurementState {}

class DataUpdatedState extends ProcurementState {}

class DataDeletedState extends ProcurementState {}

class ErrorState extends ProcurementState {
  final String error;

  const ErrorState(this.error);

  @override
  List<Object?> get props => [error];
}*/
