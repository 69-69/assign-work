import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_status_enum.dart';
import 'package:assign_erp/features/setup/data/models/employee_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Base AuthGuard class for common auth-related checks [BaseAuthGuard]
abstract class BaseAuthGuard {
  final FirebaseAuth _firebaseAuth;

  BaseAuthGuard({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  AuthState? getAuthState(BuildContext context) {
    /* If you're calling this inside a widget (not an extension), use:
    final authState = context.watch<AuthBloc>().state;*/
    final authState = BlocProvider.of<AuthBloc>(context).state;
    // final authState = context.select<AuthBloc, AuthState>((bloc) => bloc.state);

    var authStatus = authState.authStatus;
    if (currentUser != null && authStatus == AuthStatus.authenticated) {
      return authState;
    }
    return null;
  }
}

/// Guard for general authentication [AuthGuard]
class AuthGuard extends BaseAuthGuard {
  AuthGuard({super.firebaseAuth});

  ({Workspace? workspace, Employee? employee})? getAuthSession(
    BuildContext context,
  ) {
    final authState = getAuthState(context);

    if (authState != null) {
      return (workspace: authState.workspace, employee: authState.employee);
    }
    return null;
  }

  Future<bool> redirect(BuildContext context, GoRouterState state) async {
    if (currentUser == null) {
      if (state.name != RouteNames.initialScreenName) {
        context.goNamed(RouteNames.initialScreenName);
      }
      return false;
    }
    return true;
  }
}

/// Guard for dashboard access [DashboardGuard]
class DashboardGuard extends BaseAuthGuard {
  DashboardGuard({super.firebaseAuth});

  Future<bool> redirect(BuildContext context) async {
    final authState = getAuthState(context);

    if (authState != null) {
      final workspace = authState.workspace;
      final employee = authState.employee;
      return workspace != null && employee != null;
    }
    return false;
  }
}

/// Guard for email verification [EmailVerificationGuard]
class EmailVerificationGuard extends BaseAuthGuard {
  EmailVerificationGuard({super.firebaseAuth});

  Future<bool> redirect(BuildContext context, GoRouterState state) async {
    if (currentUser == null || !currentUser!.emailVerified) {
      context.goNamed(RouteNames.verifyWorkspaceEmail);
      return false;
    }
    return true;
  }
}

/// Guard for workspace role-based access [WorkspaceRoleGuard]
class WorkspaceRoleGuard {
  static bool _canAccess(
    BuildContext context,
    bool Function(Workspace) roleCheck,
  ) {
    AuthState authState;

    try {
      // Try to watch the AuthBloc (only works inside widget build context)
      authState = context.watch<AuthBloc>().state;
    } catch (_) {
      // Fallback: use read() if watch() isn't allowed
      try {
        authState = context.read<AuthBloc>().state;
      } catch (_) {
        // No access to authBloc in this context
        return false;
      }
    }

    final workspace = authState.workspace;
    if (authState.authStatus == AuthStatus.authenticated && workspace != null) {
      return roleCheck(workspace);
    }

    return false;
  }

  /*static bool _canAccess(
    BuildContext context,
    bool Function(Workspace) roleCheck,
  ) {
    final authState = context.watch<AuthBloc>().state;

    if (authState.authStatus == AuthStatus.authenticated) {
      final workspace = authState.workspace;
      prettyPrint('role-check', workspace.toString());
      if (workspace != null) {
        return roleCheck(workspace);
      }
    }
    return false;
  }*/

  static bool canAccessOnboarding(BuildContext context) {
    return _canAccess(
      context,
      (workspace) => workspace.canAccessOnboarding(workspace),
    );
  }

  static bool canAccessTenantDashboard(BuildContext context) {
    return _canAccess(
      context,
      (workspace) => workspace.canAccessTenantDashboard(workspace),
    );
  }

  static bool canAccessAgentDashboard(BuildContext context) {
    return _canAccess(
      context,
      (workspace) => workspace.canAccessAgentDashboard(workspace),
    );
  }

  static bool canAccessDeveloperDashboard(BuildContext context) {
    return _canAccess(
      context,
      (workspace) => workspace.canAccessDeveloperDashboard(workspace),
    );
  }
}

/// Access Signed In User Data [GetSignedInUser]
extension GetSignedInUser on BuildContext {
  // Retrieves the currently signed-in Workspace & Employee data for the user
  get _session => AuthGuard().getAuthSession(this);

  ({Employee? employee, Workspace? workspace})? get authSession => _session;

  // Retrieves the workspace of the signed-in user or returns a default Workspace instance
  Workspace? get workspace => _session?.workspace;

  // Retrieves the employee of the signed-in user or returns a default Employee instance
  Employee? get employee => _session?.employee;
}
