part of 'firestore_bloc.dart';

/// State
///
sealed class FirestoreState<T> extends Equatable {
  const FirestoreState();

  @override
  List<Object?> get props => [];
}

class LoadingItems<T> extends FirestoreState<T> {}

class ItemsLoaded<T> extends FirestoreState<T> {
  final List<T> data;

  const ItemsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class ItemLoaded<T> extends FirestoreState<T> {
  final T data;

  const ItemLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

// just
class ItemAdded<T> extends FirestoreState<T> {
  final String? message;

  const ItemAdded({this.message});

  @override
  List<Object?> get props => [message];
}

class ItemUpdated<T> extends FirestoreState<T> {
  final String? message;

  const ItemUpdated({this.message});

  @override
  List<Object?> get props => [message];
}

class ItemDeleted<T> extends FirestoreState<T> {
  final String? message;

  const ItemDeleted({this.message});

  @override
  List<Object?> get props => [message];
}

class ItemError<T> extends FirestoreState<T> {
  final String error;

  const ItemError(this.error);

  @override
  List<Object?> get props => [error];
}

/*sealed class FirestoreState extends Equatable {
  const FirestoreState();

  @override
  List<Object?> get props => [];
}

class LoadingState extends FirestoreState {}

class DataLoadedState extends FirestoreState {
  final List<Inventory> data;

  const DataLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class DataAddedState extends FirestoreState {}

class DataUpdatedState extends FirestoreState {}

class DataDeletedState extends FirestoreState {}

class ErrorState extends FirestoreState {
  final String error;

  const ErrorState(this.error);

  @override
  List<Object?> get props => [error];
}*/
