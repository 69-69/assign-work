import 'dart:async';

import 'package:assign_erp/core/constants/collection_type.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/features/customer_crm/domain/repository/customer_repository.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'customer_event.dart';
part 'customer_state.dart';

/// CustomerBloc
///
class CustomerBloc<T> extends Bloc<CustomerEvent, CustomerState<T>> {
  final CustomerRepository _customerRepository;

  /// toCache/toJson Function [toCache]
  final Map<String, dynamic> Function(T data) toCache;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;

  // Set up the stream subscription
  late StreamSubscription<List<CacheData>> _subscription;

  CustomerBloc({
    required FirebaseFirestore firestore,
    required String collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
  }) : _customerRepository = CustomerRepository(
         collectionType: CollectionType.stores,
         firestore: firestore,
         collectionPath: collectionPath,
       ),
       super(LoadingCustomers<T>()) {
    _initialize();

    _customerRepository.dataStream.listen(
      (cacheData) => add(_CustomersLoaded<T>(_toList(cacheData))),
    );
  }

  Future<void> _initialize() async {
    // on<GetShortIDEvent<T>>(_onGetShortID);
    on<RefreshCustomers<T>>(_onRefreshCustomers);
    on<GetCustomers<T>>(_onGetCustomers);
    on<GetCustomerById<T>>(_onGetCustomerById);
    on<GetCustomersByIds<T>>(_onGetCustomersByIds);
    on<GetCustomersWithSameId<T>>(_onGetCustomersWithSameId);
    on<SearchCustomers<T>>(_onSearchCustomers);
    on<AddCustomer<T>>(_onAddCustomer);
    on<AddCustomer<List<T>>>(_onAddMultiCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<_ShortIDLoaded<T>>(_onShortUIDLoaded);
    on<_CustomersLoaded<T>>(_onCustomersLoaded);
    on<_CustomerLoaded<T>>(_onCustomerLoaded);
    on<_CustomerError>(_onCustomerError);
  }

  Future<void> _onRefreshCustomers(
    RefreshCustomers<T> event,
    Emitter<CustomerState<T>> emit,
  ) async {
    emit(LoadingCustomers<T>());
    try {
      // Trigger data refresh in the DataRepository
      await _customerRepository.refreshCacheData();

      // Fetch the updated data from the repository
      final snapshot = await _customerRepository.getAllCacheData().first;
      final data = _toList(snapshot);

      // Emit the loaded state with the refreshed data
      emit(CustomersLoaded<T>(data));
    } catch (e) {
      // Emit an error state in case of failure
      emit(CustomerError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onGetCustomers]
  Future<void> _onGetCustomers(
    GetCustomers<T> event,
    Emitter<CustomerState<T>> emit,
  ) async {
    emit(LoadingCustomers<T>());

    try {
      _subscription = _customerRepository.getAllCacheData().listen(
        (snapshot) async {
          final data = _toList(snapshot);

          // Update internal state in the BLoC to reflect data loaded
          emit(CustomersLoaded<T>(data));

          // Trigger an event to handle the loaded data
          // add(_CustomerLoadedEvent<T>(data));

          // Optionally, emit another state or handle other logic
          // emit(DataAddedState<T>()); // For example, notify that data is added
        },
        onError: (e) {
          add(_CustomerError('Error loading data: $e'));
        },
      );

      // Await for the subscription to be done (optional)
      await _subscription.asFuture();

      /*List<CacheData> firstData =  await _dataRepository.getAllData().first; // Ensure await

      final data = _listDoc(firstData);

      emit(DataLoadedState<T>(data));*/
    } catch (e) {
      emit(CustomerError<T>('Error loading data: $e'));
    } finally {
      // Ensure to cancel the subscription when it's no longer needed
      // This could be in the dispose() method of a widget or BLoC
      _subscription.cancel();
    }
  }

  /*Future<void> _onLoadData2(
      LoadDataEvent<T> event, Emitter<CustomerState<T>> emit) async {
    emit(LoadingState<T>());

    _dataRepository.getAllData().listen((snapshot) {
      final data = _listDoc(snapshot);

      // Added data to event
      add(_DataLoadedEvent<T>(data));
      // Notify that data is deleted
      emit(DataAddedState<T>());
    }, onError: (e) {
      add(_DataLoadErrorEvent('Error loading data: $e'));
    });
  }*/

  Future<void> _onGetCustomersByIds(
    GetCustomersByIds<T> event,
    Emitter<CustomerState<T>> emit,
  ) async {
    emit(LoadingCustomers<T>());
    try {
      final localDataList = await _customerRepository.getMultipleDataByIDs(
        event.documentIDs,
      );

      if (localDataList.isNotEmpty) {
        final data = _toList(localDataList);

        add(_CustomersLoaded<T>(data));
        // emit(DataLoadedState<T>(data));
      }
    } catch (e) {
      emit(CustomerError<T>(e.toString()));
    }
  }

  Future<void> _onGetCustomerById(
    GetCustomerById<T> event,
    Emitter<CustomerState<T>> emit,
  ) async {
    emit(LoadingCustomers<T>());
    try {
      final localData = await _customerRepository.getDataById(
        event.documentId,
        field: event.field,
      );

      if (localData != null) {
        final data = fromFirestore(localData.data, localData.id);
        emit(CustomerLoaded<T>(data));
      } else {
        emit(CustomerError<T>('Document not found'));
      }
    } catch (e) {
      emit(CustomerError<T>(e.toString()));
    }
  }

  Future<void> _onGetCustomersWithSameId(
    GetCustomersWithSameId<T> event,
    Emitter<CustomerState<T>> emit,
  ) async {
    emit(LoadingCustomers<T>());
    try {
      final localData = await _customerRepository.getAllDataWithSameId(
        event.documentId,
        field: event.field,
      );

      if (localData.isNotEmpty) {
        final data = _toList(localData);
        emit(CustomersLoaded<T>(data));
      } else {
        emit(CustomerError<T>('Data not found'));
      }
    } catch (e) {
      emit(CustomerError<T>(e.toString()));
    }
  }

  Future<void> _onSearchCustomers(
    SearchCustomers<T> event,
    Emitter<CustomerState<T>> emit,
  ) async {
    emit(LoadingCustomers<T>());
    try {
      List<CacheData> data = await _customerRepository.searchData(
        field: event.field ?? '',
        query: event.query,
        optField: event.optField,
        auxField: event.auxField,
      );

      var localData = _toList(data);
      emit(CustomersLoaded<T>(localData));
      // emit(DataLoadedState<T>(data.cast<T>()));
    } catch (e) {
      emit(CustomerError<T>('Error searching data: $e'));
    }
  }

  Future<void> _onAddCustomer(
    AddCustomer<T> event,
    Emitter<CustomerState<T>> emit,
  ) async {
    try {
      // Add data to Firestore and update local storage
      await _customerRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(CustomerAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(CustomerError<T>(e.toString()));
    }
  }

  Future<void> _onAddMultiCustomer(
    AddCustomer<List<T>> event,
    Emitter<CustomerState<T>> emit,
  ) async {
    try {
      for (var item in event.data) {
        // Add data to Firestore
        _customerRepository.createData(toCache(item));
      }

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(CustomerAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(CustomerError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState<T>> emit,
  ) async {
    try {
      final isPartialUpdate = event.mapData?.isNotEmpty ?? false;
      final data = isPartialUpdate
          ? {'data': event.mapData}
          : toCache(event.data as T);

      await _customerRepository.updateData(
        event.documentId,
        data: data,
        isPartial: isPartialUpdate, // true if not a full model update
      );

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data updated
      emit(CustomerUpdated<T>(message: 'data updated successfully'));
    } catch (e) {
      emit(CustomerError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _customerRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(GetCustomers<T>());

      // Update State: Notify that data deleted
      emit(CustomerDeleted<T>(message: 'data deleted successfully'));
    } catch (e) {
      emit(CustomerError<T>(e.toString()));
    }
  }

  void _onShortUIDLoaded(
    _ShortIDLoaded<T> event,
    Emitter<CustomerState<T>> emit,
  ) {
    emit(CustomerLoaded<T>(event.shortID));
  }

  void _onCustomersLoaded(
    _CustomersLoaded<T> event,
    Emitter<CustomerState<T>> emit,
  ) {
    emit(CustomersLoaded<T>(event.data));
  }

  void _onCustomerLoaded(
    _CustomerLoaded<T> event,
    Emitter<CustomerState<T>> emit,
  ) {
    emit(CustomerLoaded<T>(event.data));
  }

  void _onCustomerError(_CustomerError event, Emitter<CustomerState<T>> emit) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'customer_bloc');
    emit(CustomerError<T>(event.error));
  }

  List<T> _toList(List<CacheData> cacheData) {
    return cacheData
        .map((cache) => fromFirestore(cache.data, cache.id))
        .toList();
  }

  /*Future<String> _generateUniqueID(CollectionReference ref) async {
    String shortId;

    while (true) {
      shortId = shortid.generate();
      final trimNewId = _replaceSpecialCharsWithRandomNumbers(shortId);
      DocumentSnapshot doc = await ref.doc(trimNewId).get();

      if (!doc.exists) {
        break;
      }
    }

    return shortId.toUpperCase();
  }

  String _replaceSpecialCharsWithRandomNumbers(String str) {
    final Random random = Random();
    RegExp regExp = RegExp(r'[^a-zA-Z0-9]');
    String result = str.replaceAllMapped(regExp, (Match match) {
      return random.nextInt(10).toString();
    });

    return result;
  }*/

  @override
  Future<void> close() {
    _customerRepository.cancelDataSubscription();
    return super.close();
  }
}
