// WORKSPACE ROLE or ACCOUNT TYPE
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
  String get label {
    var role = switch (this) {
      WorkspaceRole.onboarding => 'onboarding',
      WorkspaceRole.agentFranchise => 'agentFranchise',
      WorkspaceRole.tenant => 'tenant',
      WorkspaceRole.developer => 'developer',
      _ => 'unknown',
    };
    return role;
  }

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

/// Enum values to a list of strings [workspaceRoleList]
final workspaceRoleList = [
  'workspace role',
  ...WorkspaceRole.values.map((e) => e.label),
];
