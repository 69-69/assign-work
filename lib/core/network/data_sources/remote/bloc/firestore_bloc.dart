import 'dart:async';

import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/data_repository.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'firestore_event.dart';
part 'firestore_state.dart';

/// FirestoreBloc
///
class FirestoreBloc<T> extends Bloc<FirestoreEvent, FirestoreState<T>> {
  final DataRepository _dataRepository;
  final FirebaseFirestore _firestore;
  final String collectionPath;

  /// toCache/toJson Function [toCache]
  final Map<String, dynamic> Function(T data) toCache;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;

  // Set up the stream subscription
  StreamSubscription<List<CacheData>>? _getDataStreamObserver;

  FirestoreBloc({
    required FirebaseFirestore firestore,
    required this.collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
  }) : _firestore = firestore,
       _dataRepository = DataRepository(
         firestore: firestore,
         collectionPath: collectionPath,
         collectionRef: firestore.collection(collectionPath),
       ),
       super(LoadingItems<T>()) {
    _initialize();
    // Start loading data from Firestore-DB (Remote)
    // to LocalStorage/Cache (Hive) & refresh Cache
    // _dataRepository.refreshCacheData();

    _dataRepository.dataStream.listen(
      (cacheData) => add(_ItemsLoaded<T>(_toList(cacheData))),
    );
  }

  Future<void> _initialize() async {
    on<RefreshItems<T>>(_onRefreshItems);
    on<GetShortID<T>>(_onGetShortID);
    on<GetItems<T>>(_onGetItems);
    on<GetItemById<T>>(_onGetItemById);
    on<GetItemsByIDs<T>>(_onGetItemsByIDs);
    on<GetItemsWithSameId<T>>(_onGetItemsWithSameId);
    on<SearchItems<T>>(_onSearchItems);
    on<AddItem<T>>(_onAddItem);
    on<AddItem<List<T>>>(_onAddItems);
    on<UpdateItem>(_onUpdateItem);
    on<DeleteItem<String>>(_onDeleteItem);
    on<DeleteItem<List<String>>>(_onDeleteItems);
    on<_ShortIDLoaded<T>>(_onShortUIDLoaded);
    on<_ItemsLoaded<T>>(_onItemsLoaded);
    on<_ItemLoaded<T>>(_onItemLoaded);
    on<_ItemLoadError>(_onItemLoadError);
  }

  Future<void> _onRefreshItems(
    RefreshItems<T> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    emit(LoadingItems<T>());
    try {
      // Trigger data refresh in the DataRepository
      await _dataRepository.refreshCacheData();

      // Fetch the updated data from the repository
      final snapshot = await _dataRepository.getAllCacheData().first;
      final data = _toList(snapshot);

      // Emit the loaded state with the refreshed data
      emit(ItemsLoaded<T>(data));
    } catch (e) {
      // Emit an error state in case of failure
      emit(ItemError<T>(e.toString()));
    }
  }

  Future<void> _onGetShortID(
    GetShortID<T> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    emit(LoadingItems<T>());

    try {
      /// Generate shortId for UI/UX Usage (ex: customer-id)
      var shortId = await _generateUniqueID(
        _firestore.collection(collectionPath),
      );

      if (shortId.isNotEmpty) {
        final data = fromFirestore({'shortId': shortId}, '');
        add(_ShortIDLoaded<T>(data));
      } else {
        emit(ItemError<T>('Generating Short Id failed'));
      }
    } catch (e) {
      emit(ItemError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onGetItems]
  Future<void> _onGetItems(
    GetItems<T> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    emit(LoadingItems<T>());

    try {
      _getDataStreamObserver = _dataRepository.getAllCacheData().listen(
        (snapshot) async {
          final data = _toList(snapshot);

          // Update internal state in the BLoC to reflect data loaded
          emit(ItemsLoaded<T>(data));

          // Trigger an event to handle the loaded data
          // add(_DataLoadedEvent<T>(data));

          // Optionally, emit another state or handle other logic
          // emit(DataAddedState<T>()); // For example, notify that data is added
        },
        onError: (e) {
          add(_ItemLoadError('Error loading data: $e'));
        },
      );

      // Await for the subscription to be done (optional)
      await _getDataStreamObserver?.asFuture();

      /*List<CacheData> firstData =  await _dataRepository.getAllData().first; // Ensure await

      final data = _listDoc(firstData);

      emit(DataLoadedState<T>(data));*/
    } catch (e) {
      emit(ItemError<T>('Error loading data: $e'));
    } finally {
      // Ensure to cancel the subscription when it's no longer needed
      // This could be in the dispose() method of a widget or BLoC
      _getDataStreamObserver?.cancel();
    }
  }

  /*Future<void> _onLoadData2(
      LoadDataEvent<T> event, Emitter<FirestoreState<T>> emit) async {
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

  Future<void> _onGetItemsByIDs(
    GetItemsByIDs<T> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    emit(LoadingItems<T>());
    try {
      final localDataList = await _dataRepository.getManyDataByIDs(
        event.documentIDs,
      );

      if (localDataList.isNotEmpty) {
        final data = _toList(localDataList);

        add(_ItemsLoaded<T>(data));
        // emit(DataLoadedState<T>(data));
      }
    } catch (e) {
      emit(ItemError<T>(e.toString()));
    }
  }

  Future<void> _onGetItemById(
    GetItemById<T> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    emit(LoadingItems<T>());
    try {
      final localData = await _dataRepository.getDataById(
        event.documentId,
        field: event.field,
      );

      if (localData != null) {
        final data = fromFirestore(localData.data, localData.id);
        add(_ItemLoaded<T>(data));
      } else {
        emit(ItemError<T>('Document not found'));
      }
    } catch (e) {
      emit(ItemError<T>(e.toString()));
    }
  }

  Future<void> _onGetItemsWithSameId(
    GetItemsWithSameId<T> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    emit(LoadingItems<T>());
    try {
      final localData = await _dataRepository.getAllDataWithSameId(
        event.documentId,
        field: event.field,
      );

      if (localData.isNotEmpty) {
        final data = _toList(localData);
        emit(ItemsLoaded<T>(data));
      } else {
        emit(ItemError<T>('Data not found'));
      }
    } catch (e) {
      emit(ItemError<T>(e.toString()));
    }
  }

  Future<void> _onSearchItems(
    SearchItems<T> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    emit(LoadingItems<T>());
    try {
      List<CacheData> data = await _dataRepository.searchData(
        event.query,
        primaryField: event.primaryField ?? '',
        optionalField: event.optionalField,
        secondaryField: event.secondaryField,
        tertiaryField: event.tertiaryField,
      );

      var localData = _toList(data);
      emit(ItemsLoaded<T>(localData));
      // emit(DataLoadedState<T>(data.cast<T>()));
    } catch (e) {
      emit(ItemError<T>('Error searching data: $e'));
    }
  }

  Future<void> _onAddItem(
    AddItem<T> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    try {
      // Add data to Firestore and update local storage
      await _dataRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(ItemAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(ItemError<T>(e.toString()));
    }
  }

  Future<void> _onAddItems(
    AddItem<List<T>> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    try {
      for (var item in event.data) {
        // Add data to Firestore
        _dataRepository.createData(toCache(item));
      }

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(ItemAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(ItemError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdateItem(
    UpdateItem event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    try {
      final isPartialUpdate = event.mapData?.isNotEmpty ?? false;
      final data = isPartialUpdate
          ? {'data': event.mapData}
          : toCache(event.data as T);

      await _dataRepository.updateData(
        event.documentId,
        data: data,
        isPartial: isPartialUpdate, // true if not a full model update
      );

      // Update State: Notify that data updated
      emit(ItemUpdated<T>(message: 'Changes successfully saved'));
    } catch (e) {
      emit(ItemError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteItem(
    DeleteItem<String> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _dataRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(RefreshItems<T>());
      // add(GetData<T>());

      // Update State: Notify that data deleted
      emit(ItemDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      emit(ItemError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteItems(
    DeleteItem<List<String>> event,
    Emitter<FirestoreState<T>> emit,
  ) async {
    try {
      if (event.documentId.isEmpty) {
        emit(ItemError<T>('No Data were selected to delete.'));
        return;
      }

      // Delete data from Firestore and update local storage
      await _dataRepository.deleteManyData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(RefreshItems<T>());
      // add(GetData<T>());

      // Update State: Notify that data deleted
      emit(ItemDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      emit(ItemError<T>(e.toString()));
    }
  }

  void _onShortUIDLoaded(
    _ShortIDLoaded<T> event,
    Emitter<FirestoreState<T>> emit,
  ) {
    emit(ItemLoaded<T>(event.shortID));
  }

  void _onItemsLoaded(_ItemsLoaded<T> event, Emitter<FirestoreState<T>> emit) {
    emit(ItemsLoaded<T>(event.data));
  }

  void _onItemLoaded(_ItemLoaded<T> event, Emitter<FirestoreState<T>> emit) {
    emit(ItemLoaded<T>(event.data));
  }

  void _onItemLoadError(_ItemLoadError event, Emitter<FirestoreState<T>> emit) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'firestore_bloc');
    emit(ItemError<T>(event.error));
  }

  List<T> _toList(List<CacheData> cacheData) {
    return cacheData
        .map((cache) => fromFirestore(cache.data, cache.id))
        .toList();
  }

  Future<String> _generateUniqueID(CollectionReference ref) async {
    String shortId;
    final d = DateTime.now();

    while (true) {
      /*shortId = shortid.generate();
      final trimNewId = _replaceSpecialCharsWithRandomNumbers(shortId);*/
      shortId = '${d.second}${d.minute}-${d.year}${d.hour}${d.day}';
      DocumentSnapshot doc = await ref.doc(shortId).get();

      if (!doc.exists) {
        break;
      }
    }

    return shortId.toUpperCase();
  }

  /*String _replaceSpecialCharsWithRandomNumbers(String str) {
    // Create a random number generator
    final Random random = Random();
    // Define a regular expression to match non-alphanumeric characters
    RegExp regExp = RegExp(r'[^a-zA-Z0-9]');
    // Use a function to replace matches with random numbers
    String result = str.replaceAllMapped(regExp, (Match match) {
      return random.nextInt(10).toString();
    });

    return result;
  }*/

  @override
  Future<void> close() {
    _dataRepository.cancelDataSubscription();
    _getDataStreamObserver?.cancel();
    return super.close();
  }
}

/* create and implement a cache or localStorage
using dart flutter hive_flutter package  and create
and implement a remote backup from the localStorage to
remote firestore based on the below firestoreBloc:

create and implement a CRUD local cache,
along with a CRUD remote backup to Firestore,
 based on the below firestoreBloc
using these packages: hive, hive_flutter,
path_provider, cloud_firestore, firebase_core, build_runner,
hive_generator package in Dart and Flutter,

*/

/* class FirestoreBloc<T> extends Bloc<FirestoreEvent, FirestoreState<T>> {
  final String collectionPath;
  final FirebaseFirestore _firestore;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;

  StreamSubscription? _dataSubscription;

  FirestoreBloc({
    required FirebaseFirestore firestore,
    required this.collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
  })  : _firestore = firestore,
        super(LoadingState<T>()) {
    on<LoadShortIDEvent<T>>(_onLoadShortID);
    on<LoadDataEvent<T>>(_onLoadData);
    on<LoadSingleDataEvent>(_onLoadSingleData);
    on<SearchDataEvent<T>>(_onSearchData);
    on<AddDataEvent<T>>(_onAddData);
    on<AddDataEvent<List<T>>>(_onAddMultipleData);
    on<UpdateDataEvent<T>>(_onUpdateData);
    on<UpdateSingleDataEvent<T>>(_onUpdateSingleData);
    on<DeleteDataEvent>(_onDeleteData);
    on<_ShortIDLoadedEvent<T>>(_onShortUIDLoaded);
    on<_DataLoadedEvent<T>>(_onDataLoaded);
    on<_SingleDataLoadedEvent<T>>(_onSingleDataLoaded);
    on<_DataLoadErrorEvent>(_onDataLoadError);
  }

  /// Load Generated Short-UID Function [_onLoadShortID]
  Future<void> _onLoadShortID(
      LoadShortIDEvent<T> event, Emitter<FirestoreState<T>> emit) async {
    emit(LoadingState<T>());

    try {
      /// Generate shortId for UI/UX Usage (ex: customer-id)
      CollectionReference<Map<String, dynamic>> colRef =
          _firestore.collection(collectionPath);

      /// Generate short Unique-ID
      var shortId = await _generateUniqueID(colRef);

      if (shortId.isNotEmpty) {
        final data = fromFirestore({'shortId': shortId}, '');
        add(_ShortIDLoadedEvent<T>(data));
      } else {
        emit(ErrorState<T>('Generating Short Id failed'));
      }
    } catch (e) {
      emit(ErrorState<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onLoadData]
  Future<void> _onLoadData(
      LoadDataEvent<T> event, Emitter<FirestoreState<T>> emit) async {
    emit(LoadingState<T>());
    await _dataSubscription?.cancel();
    _dataSubscription =
        _firestore.collection(collectionPath).snapshots().listen((snapshot) {
      final data = _listDoc(snapshot);

      add(_DataLoadedEvent<T>(data));
    }, onError: (e) {
      add(_DataLoadErrorEvent(e.toString()));
    });
  }

  /// Load Specific Data By Doc-Id Function [_onLoadSingleData]
  Future<void> _onLoadSingleData(
      LoadSingleDataEvent event, Emitter<FirestoreState<T>> emit) async {
    emit(LoadingState<T>());
    try {
      final doc = await _firestore
          .collection(collectionPath)
          .doc(event.documentId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = fromFirestore(doc.data()!, doc.id);
        // debugPrint('searched by docId: ${doc.id} ==$data');
        add(_SingleDataLoadedEvent<T>(data));
      } else {
        emit(ErrorState<T>('Document not found'));
      }
    } catch (e) {
      emit(ErrorState<T>(e.toString()));
    }
  }

  /// Search Specific Data By field-Name [_onSearchData]
  Future<void> _onSearchData(
      SearchDataEvent<T> event, Emitter<FirestoreState<T>> emit) async {
    emit(LoadingState<T>());
    try {
      /// First search using the first-field
      var querySnapshot = await _querySnapshot(event.field ?? '', event.query);
      var data = _listDoc(querySnapshot);

      /// If no results found...
      if (data.isEmpty) {
        /// then, search using the second-field
        if (event.optField != null) {
          querySnapshot =
              await _querySnapshot(event.optField ?? '', event.query);

          data = _listDoc(querySnapshot);

          /// If no results found, then search using the third-field
          if (event.auxField != null && data.isEmpty) {
            querySnapshot =
                await _querySnapshot(event.auxField ?? '', event.query);

            data = _listDoc(querySnapshot);
          } else {
            /// else, search using document-Id
            var docSnapshot = await _firestore
                .collection(collectionPath)
                .doc(event.query)
                .get();

            if (docSnapshot.exists && docSnapshot.data() != null) {
              data = _listDoc(querySnapshot);
            }
          }
        }
      }

      add(_DataLoadedEvent<T>(data));
    } catch (e) {
      emit(ErrorState<T>(e.toString()));
    }
  }

  /// Search Helper Functions-1
  List<T> _listDoc(QuerySnapshot<Map<String, dynamic>> querySnapshot) {
    return querySnapshot.docs
        .map((doc) => fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Search Helper Functions-2
  Future<QuerySnapshot<Map<String, dynamic>>> _querySnapshot(
      Object field, String query) async {
    return await _firestore
        .collection(collectionPath)
        .where(field, isGreaterThanOrEqualTo: query)
        .where(field, isGreaterThanOrEqualTo: '$query\uf8ff')
        .get();
  }

  Future<void> _onAddData2(
      AddDataEvent<T> event, Emitter<FirestoreState<T>> emit) async {
    try {
      String? docId;

      CollectionReference<Map<String, dynamic>> colRef =
          _firestore.collection(collectionPath);

      /// NOTE: If 'documentId' is NULL/Empty, Generate shortId
      if (event.documentId.isNullOrEmpty) {
        /// Generate short Unique-ID
        docId ??= await _generateUniqueID(colRef);
      }

      /// else, 'documentId' is autoAssign, Firestore will auto-generate unique-ID (documentId)
      final docRef = colRef.doc(docId);

      final snapShot = await docRef.get();

      if (snapShot.exists) {
        emit(const ErrorState('Document already exists'));
      } else {
        final data = toCache(event.data);

        var cacheData = CacheData(id: docRef.id, data: data['data']);

        // Add data to Firestore and update local storage
        await _dataRepository.addData(cacheData);

        // Trigger LoadDataEvent to reload the data
        // add(LoadDataEvent<T>());

        // Update State: Notify that data added
        emit(DataAddedState<T>(message: 'Data added successfully'));
      }
    } catch (e) {
      emit(ErrorState<T>(e.toString()));
    }
  }

  /// Add/Create New Data Function [_onAddData]
  Future<void> _onAddData(
      AddDataEvent<T> event, Emitter<FirestoreState<T>> emit) async {
    try {
      String? docId;

      CollectionReference<Map<String, dynamic>> colRef =
          _firestore.collection(collectionPath);

      /// NOTE: If 'documentId' is NULL/Empty, Generate shortId
      if (event.documentId.isNullOrEmpty) {
        /// Generate short Unique-ID
        docId ??= await _generateUniqueID(colRef);
      }

      /// else, 'documentId' is autoAssign, Firestore will auto-generate unique-ID (documentId)

      DocumentReference<Map<String, dynamic>> docRef = colRef.doc(docId);

      final snapShot = await docRef.get();

      if (!snapShot.exists) {
        await docRef.set(toFirestore(event.data));
      }

      // Check if Item already exists, else create it
      // snapShot.exists ? snapShot : docRef.set(toFirestore(event.data));

      // _firestore.collection(collectionPath).add(toFirestore(event.data));
      emit(DataAddedState<T>());
    } catch (e) {
      emit(ErrorState<T>(e.toString()));
    }
  }

  /// Add A List of New Data Function [_onAddMultipleData]
  Future<void> _onAddMultipleData(
      AddDataEvent<List<T>> event, Emitter<FirestoreState<T>> emit) async {
    try {
      CollectionReference<Map<String, dynamic>> colRef =
          _firestore.collection(collectionPath);

      for (var item in event.data) {
        colRef.add(toFirestore(item));
      }

      emit(DataAddedState<T>());
    } catch (e) {
      emit(ErrorState<T>(e.toString()));
    }
  }

  /// Update Data Function [_onUpdateData]
  Future<void> _onUpdateData(
      UpdateDataEvent<T> event, Emitter<FirestoreState<T>> emit) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(event.documentId)
          .update(toFirestore(event.data));

      // Reload to show changes
      add(LoadDataEvent<T>());
      // Notify that data is updated
      emit(DataUpdatedState<T>());
    } catch (e) {
      emit(ErrorState<T>(e.toString()));
    }
  }

  /// Update Single Field-Data Function [_onUpdateSingleData]
  /// Field-data(event.data) must be in Map: {'key':'value'}
  Future<void> _onUpdateSingleData(
      UpdateSingleDataEvent event, Emitter<FirestoreState<T>> emit) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(event.documentId)
          .update(event.data);

      // Reload to show changes
      add(LoadDataEvent<T>());
      // Notify that data is updated
      emit(DataUpdatedState<T>());
    } catch (e) {
      emit(ErrorState<T>(e.toString()));
    }
  }

  /// Delete Data Function [_onDeleteData]
  Future<void> _onDeleteData(
      DeleteDataEvent event, Emitter<FirestoreState<T>> emit) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(event.documentId)
          .delete();
      // Reload to show changes
      add(LoadDataEvent<T>());
      // Notify that data is deleted
      emit(DataDeletedState<T>());
    } catch (e) {
      emit(ErrorState<T>(e.toString()));
    }
  }

  void _onShortUIDLoaded(
      _ShortIDLoadedEvent<T> event, Emitter<FirestoreState<T>> emit) {
    emit(SingleDataLoadedState<T>(event.shortID));
  }

  void _onDataLoaded(
      _DataLoadedEvent<T> event, Emitter<FirestoreState<T>> emit) {
    emit(DataLoadedState<T>(event.data));
  }

  void _onSingleDataLoaded(
      _SingleDataLoadedEvent<T> event, Emitter<FirestoreState<T>> emit) {
    emit(SingleDataLoadedState<T>(event.data));
  }

  void _onDataLoadError(
      _DataLoadErrorEvent event, Emitter<FirestoreState<T>> emit) {
    emit(ErrorState<T>(event.error));
  }

  Future<String> _generateUniqueID(CollectionReference ref) async {
    String shortId;

    while (true) {
      // Generate a short, unique ID
      shortId = shortid.generate();

      final trimNewId = _replaceSpecialCharsWithRandomNumbers(shortId);

      // Check if a document with this ID already exists
      DocumentSnapshot doc = await ref.doc(trimNewId).get();

      if (!doc.exists) {
        break;
      }
    }

    return shortId.toUpperCase();
  }

  String _replaceSpecialCharsWithRandomNumbers(String str) {
    // Create a random number generator
    final Random random = Random();

    // Define a regular expression to match non-alphanumeric characters
    RegExp regExp = RegExp(r'[^a-zA-Z0-9]');

    // Use a function to replace matches with random numbers
    String result = str.replaceAllMapped(regExp, (Match match) {
      return random.nextInt(10).toString();
    });

    return result;
  }

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    return super.close();
  }
}*/
