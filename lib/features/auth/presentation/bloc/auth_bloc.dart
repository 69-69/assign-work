import 'dart:async';

import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/domain/repository/auth_repository.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_status_enum.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription<void> _subscription;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState.authInitial()) {
    _initialize();
    add(AuthCheckRequested());

    _subscribeToAuthStreams();
  }

  void _initialize() {
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthUserChanged>(_onAuthUserChanged);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  void _subscribeToAuthStreams() {
    _subscription =
        StreamGroup.merge([
          _authRepository.firebaseAuthStateChanges.map(
            (user) => AuthUserChanged(user: user),
          ),

          _authRepository.authStatusChanges.map(
            (status) => AuthStatusChanged(status: status),
          ),
        ])
        // Listen to the merged stream and add each event to the Bloc's event stream.
        // This allows the Bloc to process events from both streams.
        .listen((event) {
          prettyPrint(
            'DEBUG-EventStream: Received event',
            'new event received',
          );
          if (!isClosed) {
            add(event);
          } else {
            prettyPrint(
              'DEBUG-EventStream: Skipped event after close',
              '$event',
            );
          }
        });
  }

  Future<void> _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;

    if (user == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    await _handleUserAuth(user, emit);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await Future.delayed(kAnimateDuration);
      final user = _authRepository.firebaseUser;

      if (user == null) {
        emit(const AuthState.unauthenticated());
        return;
      }

      await _handleUserAuth(user, emit);
    } catch (e /*, stackTrace*/) {
      _handleError(emit, 'Error during status change: $e');
    }
  }

  Future<void> _handleUserAuth(User user, Emitter<AuthState> emit) async {
    try {
      final workspace = await _authRepository.getWorkspace(uid: user.uid);
      final employee = await _authRepository.getEmployee();

      if (workspace!.unExpired) {
        if (!user.emailVerified) {
          emit(const AuthState.emailNotVerified());
        } else {
          emit(
            AuthState.authenticated(workspace: workspace, employee: employee),
          );
        }
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (e /*, stackTrace*/) {
      _handleError(emit, 'Error during status change: $e');
    }
  }

  Future<void> _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    try {
      switch (event.status) {
        case AuthStatus.workspaceAuthenticated:
          await _emitWorkspaceAuthenticatedState(emit);
          break;

        case AuthStatus.unauthenticated:
          emit(const AuthState.unauthenticated());
          break;

        case AuthStatus.authenticated:
          await _emitAuthenticatedState(emit);
          break;

        case AuthStatus.emailNotVerified:
          emit(const AuthState.emailNotVerified());
          break;

        case AuthStatus.initial:
          emit(const AuthState.authInitial());
          break;

        case AuthStatus.isLoading:
          emit(const AuthState.isLoading());
          break;

        case AuthStatus.hasError:
          emit(const AuthState.hasError());
          break;

        case AuthStatus.hasTemporaryPasscode:
          emit(const AuthState.hasTemporaryPasscode());
      }
    } catch (e /*, stackTrace*/) {
      _handleError(emit, 'Error during status change: $e');
    }
  }

  Future<void> _emitWorkspaceAuthenticatedState(Emitter<AuthState> emit) async {
    final workspace = await _authRepository.getWorkspace();
    emit(AuthState.workspaceAuthenticated(workspace: workspace));
  }

  Future<void> _emitAuthenticatedState(Emitter<AuthState> emit) async {
    final (Workspace workspace, Employee employee) = await Future.wait([
      _authRepository.getWorkspace(),
      _authRepository.getEmployee(),
    ]).then((a) => (a.first as Workspace, a.last as Employee));

    emit(AuthState.authenticated(workspace: workspace, employee: employee));
  }

  void _handleError(Emitter<AuthState> emit, String errorMessage) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: errorMessage, fileName: 'auth_bloc');
    emit(AuthState.hasError(error: errorMessage));
    // Optionally, log the stack trace for further debugging
    // print('Error: $errorMessage');
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();

      emit(const AuthState.unauthenticated());
    } catch (e /*, stackTrace*/) {
      emit(AuthState.hasError(error: 'Error during sign out: $e'));
      // Optionally, log the stack trace for further debugging
      // print('StackTrace: $stackTrace');
    }
  }

  @override
  Future<void> close() async {
    prettyPrint('Closing AuthBloc', 'AuthBloc is closing');
    await _subscription.cancel(); // Stop listening to Firebase events
    _authRepository.dispose(); // clean up repository streams
    return super.close(); // Properly close the bloc
  }
}
