part of 'workspace_auth_bloc.dart';

class WorkspaceAuthState extends Equatable {
  const WorkspaceAuthState({
    this.status = FormzSubmissionStatus.initial,
    this.creationStage = WorkspaceCreationStage.initial,
    this.workspaceCategory = const WorkspaceCategory.pure(),
    this.workspaceName = const WorkspaceName.pure(),
    this.mobileNumber = const MobileNumber.pure(),
    this.password = const Password.pure(),
    this.temporaryPasscode = const Passcode.pure(),
    this.clientName = const Name.pure(),
    this.address = const Address.pure(),
    this.email = const Email.pure(),
    this.isValid = false,
    this.errorMessage,
  });

  final FormzSubmissionStatus status;
  final WorkspaceCreationStage creationStage;
  final WorkspaceCategory workspaceCategory;
  final WorkspaceName workspaceName;
  final MobileNumber mobileNumber;
  final Password password; // Only for Workspace
  final Passcode temporaryPasscode; // Only for Employee Onetime
  final Name clientName;
  final Address address;
  final Email email;
  final bool isValid;
  final String? errorMessage;

  // Creates a copy of the current state with possible modifications
  WorkspaceAuthState copyWith({
    FormzSubmissionStatus? status,
    WorkspaceCreationStage? creationStage,
    WorkspaceCategory? workspaceCategory,
    WorkspaceName? workspaceName,
    MobileNumber? mobileNumber,
    Password? password,
    Passcode? temporaryPasscode,
    Address? address,
    Name? clientName,
    Email? email,
    bool? isValid,
    String? errorMessage,
  }) {
    return WorkspaceAuthState(
      status: status ?? this.status,
      creationStage: creationStage ?? this.creationStage,
      workspaceCategory: workspaceCategory ?? this.workspaceCategory,
      workspaceName: workspaceName ?? this.workspaceName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      clientName: clientName ?? this.clientName,
      password: password ?? this.password,
      temporaryPasscode: temporaryPasscode ?? this.temporaryPasscode,
      address: address ?? this.address,
      email: email ?? this.email,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    workspaceCategory,
    workspaceName,
    email,
    clientName,
    address,
    mobileNumber,
    password,
    temporaryPasscode,
    status,
    creationStage,
    isValid,
    errorMessage,
  ];
}

// State when an error occurs during authentication
class WorkspaceAuthError extends WorkspaceAuthState {
  final String error;

  const WorkspaceAuthError({required this.error});

  @override
  List<Object?> get props => [error, ...super.props];
}
