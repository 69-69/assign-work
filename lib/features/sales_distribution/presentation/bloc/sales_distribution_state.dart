part of 'sales_distribution_bloc.dart';

/// State
///
sealed class SalesDistributionState<T> extends Equatable {
  const SalesDistributionState();

  @override
  List<Object?> get props => [];
}

class LoadingSalesDistribution<T> extends SalesDistributionState<T> {}

class SalesDistributionsLoaded<T> extends SalesDistributionState<T> {
  final List<T> data;

  const SalesDistributionsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class SalesDistributionLoaded<T> extends SalesDistributionState<T> {
  final T data;

  const SalesDistributionLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

// just
class SalesDistributionAdded<T> extends SalesDistributionState<T> {
  final String? message;

  const SalesDistributionAdded({this.message});

  @override
  List<Object?> get props => [message];
}

class SalesDistributionUpdated<T> extends SalesDistributionState<T> {
  final String? message;

  const SalesDistributionUpdated({this.message});

  @override
  List<Object?> get props => [message];
}

class SalesDistributionDeleted<T> extends SalesDistributionState<T> {
  final String? message;

  const SalesDistributionDeleted({this.message});

  @override
  List<Object?> get props => [message];
}

class SalesDistributionDeleting<T> extends SalesDistributionState<T> {}

class SalesDistributionError<T> extends SalesDistributionState<T> {
  final String error;

  const SalesDistributionError(this.error);

  @override
  List<Object?> get props => [error];
}

/*sealed class SalesDistributionState extends Equatable {
  const SalesDistributionState();

  @override
  List<Object?> get props => [];
}

class LoadingState extends SalesDistributionState {}

class DataLoadedState extends SalesDistributionState {
  final List<Inventory> data;

  const DataLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class DataAddedState extends SalesDistributionState {}

class DataUpdatedState extends SalesDistributionState {}

class DataDeletedState extends SalesDistributionState {}

class ErrorState extends SalesDistributionState {
  final String error;

  const ErrorState(this.error);

  @override
  List<Object?> get props => [error];
}*/
