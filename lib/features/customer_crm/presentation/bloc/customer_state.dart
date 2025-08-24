part of 'customer_bloc.dart';

/// State
///
sealed class CustomerState<T> extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class LoadingCustomers<T> extends CustomerState<T> {}

class CustomersLoaded<T> extends CustomerState<T> {
  final List<T> data;

  const CustomersLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class CustomerLoaded<T> extends CustomerState<T> {
  final T data;

  const CustomerLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

// just
class CustomerAdded<T> extends CustomerState<T> {
  final String? message;

  const CustomerAdded({this.message});

  @override
  List<Object?> get props => [message];
}

class CustomerUpdated<T> extends CustomerState<T> {
  final String? message;

  const CustomerUpdated({this.message});

  @override
  List<Object?> get props => [message];
}

class CustomerDeleted<T> extends CustomerState<T> {
  final String? message;

  const CustomerDeleted({this.message});

  @override
  List<Object?> get props => [message];
}

class CustomerError<T> extends CustomerState<T> {
  final String error;

  const CustomerError(this.error);

  @override
  List<Object?> get props => [error];
}

/*sealed class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class LoadingState extends CustomerState {}

class DataLoadedState extends CustomerState {
  final List<Inventory> data;

  const DataLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class DataAddedState extends CustomerState {}

class DataUpdatedState extends CustomerState {}

class DataDeletedState extends CustomerState {}

class ErrorState extends CustomerState {
  final String error;

  const ErrorState(this.error);

  @override
  List<Object?> get props => [error];
}*/
