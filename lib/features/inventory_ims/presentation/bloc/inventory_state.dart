part of 'inventory_bloc.dart';

/// State
///
sealed class InventoryState<T> extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class LoadingInventory<T> extends InventoryState<T> {}

class InventoriesLoaded<T> extends InventoryState<T> {
  final List<T> data;

  const InventoriesLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class InventoryLoaded<T> extends InventoryState<T> {
  final T data;

  const InventoryLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

// just
class InventoryAdded<T> extends InventoryState<T> {
  final String? message;

  const InventoryAdded({this.message});

  @override
  List<Object?> get props => [message];
}

class InventoryUpdated<T> extends InventoryState<T> {
  final String? message;

  const InventoryUpdated({this.message});

  @override
  List<Object?> get props => [message];
}

class InventoryDeleted<T> extends InventoryState<T> {
  final String? message;

  const InventoryDeleted({this.message});

  @override
  List<Object?> get props => [message];
}

class InventoryDeleting<T> extends InventoryState<T> {}

class InventoryError<T> extends InventoryState<T> {
  final String error;

  const InventoryError(this.error);

  @override
  List<Object?> get props => [error];
}

/*sealed class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class LoadingState extends InventoryState {}

class DataLoadedState extends InventoryState {
  final List<Inventory> data;

  const DataLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class DataAddedState extends InventoryState {}

class DataUpdatedState extends InventoryState {}

class DataDeletedState extends InventoryState {}

class ErrorState extends InventoryState {
  final String error;

  const ErrorState(this.error);

  @override
  List<Object?> get props => [error];
}*/
