// WORKSPACE ROLE or ACCOUNT TYPE
import 'package:assign_erp/core/util/str_util.dart';

enum WorkspaceRole {
  /// Workspace Role for creating first-time Agent Workspaces [onboarding].
  onboarding,

  /// Workspace Role for agents to manage their own and client's (tenants) workspaces [agentFranchise].
  agentFranchise,

  /// Workspace Role for paid subscribers (tenants) workspaces [tenant].
  tenant,

  /// Workspace Role for developers to troubleshoot, manage tenants workspaces & subscriptions [developer].
  developer,

  /// Workspace Role for UnAuthorized/unknown/fake users [unknown].
  unknown,
}

extension WorkspaceRoleExtension on WorkspaceRole {
  /// USAGE: `WorkspaceRole.onboarding.label`
  String get getValue => getEnumName<WorkspaceRole>(this);

  /// [assign] Determines the role for a "New Workspace Setup" based on the
  /// currently signed-in user's role (cached workspace role).
  ///
  /// - NOTE: `WorkspaceRole.onboarding` role is used as first-time login during initial APP or WorkSpace setup.
  ///
  /// Role Assignment Logic:
  /// - If the currently signed-in workspace's role is:
  ///   - `onboarding`, assigns `WorkspaceRole.agentFranchise`.
  ///   - `agentFranchise`, assigns `WorkspaceRole.subscriber`.
  ///   - `developer`, retains `WorkspaceRole.developer`.
  ///   - If the role is `null`, defaults to `WorkspaceRole.subscriber`.
  ///
  /// Used during the "Setup/Create New Workspace" flow. [assign]
  /// USAGE: `WorkspaceRole.onboarding.assign`
  WorkspaceRole get assign {
    return switch (this) {
      WorkspaceRole.onboarding => WorkspaceRole.agentFranchise,
      WorkspaceRole.agentFranchise => WorkspaceRole.tenant,
      WorkspaceRole.developer => WorkspaceRole.onboarding,
      _ => WorkspaceRole.tenant,
    };
  }
}

/// [WorkspaceRoleHelper] Utility class for WorkspaceRole operations
class WorkspaceRoleHelper {
  /// [WorkspaceRole] Convert string to WorkspaceRole enum
  static WorkspaceRole fromString(String role) {
    return WorkspaceRole.values.firstWhere(
      (e) => e.getValue == role,
      orElse: () => WorkspaceRole.unknown,
    );
  }

  /// [toStringList] Convert enum list to a list of strings
  static List<String> toStringList([bool includeLabel = true]) {
    final list = WorkspaceRole.values.map((e) => e.getValue).toList();
    return includeLabel ? ['workspace role', ...list] : list;
  }

  /// Check if role exists in the enum
  static bool exists(String role) {
    return WorkspaceRole.values.any((e) => e.getValue == role);
  }
}
