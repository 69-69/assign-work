enum WorkspaceCreationStage {
  initial,
  registeringEmail,
  creatingWorkspace,
  creatingEmployee,
  linkingAgent,
  creatingDefaultRolePermission,
  creatingDefaultDepartment,
  creatingDefaultBusinessLocation,
  success,
  failure,
}

extension Workflow on WorkspaceCreationStage {
  String get stageMessage => switch (this) {
    WorkspaceCreationStage.registeringEmail => "Registering email...",
    WorkspaceCreationStage.creatingWorkspace => "Creating workspace...",
    WorkspaceCreationStage.creatingDefaultRolePermission => "Creating role...",
    WorkspaceCreationStage.creatingDefaultBusinessLocation =>
      "Creating business address...",
    WorkspaceCreationStage.creatingDefaultDepartment =>
      "Creating department...",
    WorkspaceCreationStage.creatingEmployee => "Creating employee...",
    WorkspaceCreationStage.linkingAgent => "Linking agent...",
    WorkspaceCreationStage.success => "Setup successful! 🎉",
    WorkspaceCreationStage.initial => "Preparing...",
    WorkspaceCreationStage.failure => "Something went wrong ❌",
  };

  static List<WorkspaceCreationStage> get allStages => WorkspaceCreationStage
      .values
      .where(
        (s) =>
            s != WorkspaceCreationStage.initial &&
            s != WorkspaceCreationStage.failure,
      )
      .toList();
}
