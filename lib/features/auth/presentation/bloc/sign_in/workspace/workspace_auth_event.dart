part of 'workspace_auth_bloc.dart';

/// [WorkspaceAuthEvent] Abstract class for all sign-in events
sealed class WorkspaceAuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// [SignInEmailChanged] TEXT-FIELD: Event when the email field changes
class SignInEmailChanged extends WorkspaceAuthEvent {
  SignInEmailChanged(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

/// [SignInMobileChanged] TEXT-FIELD: Event when the mobile number field changes
class SignInMobileChanged extends WorkspaceAuthEvent {
  SignInMobileChanged(this.mobileNumber);

  final String mobileNumber;

  @override
  List<Object> get props => [mobileNumber];
}

/// [WorkspaceCategoryChanged] TEXT-FIELD: Event when the Workspace Category field changes
class WorkspaceCategoryChanged extends WorkspaceAuthEvent {
  final String workspaceCategory;

  WorkspaceCategoryChanged(this.workspaceCategory);

  @override
  List<Object> get props => [workspaceCategory];
}

/// [WorkspaceNameChanged] TEXT-FIELD: Event when the Workspace name field changes
class WorkspaceNameChanged extends WorkspaceAuthEvent {
  final String workspaceName;

  WorkspaceNameChanged(this.workspaceName);

  @override
  List<Object> get props => [workspaceName];
}

/// [ClientNameChanged] TEXT-FIELD: Event when the full name field changes
class ClientNameChanged extends WorkspaceAuthEvent {
  final String fullName;

  ClientNameChanged(this.fullName);

  @override
  List<Object> get props => [fullName];
}

/// [TemporaryPasscodeChanged] TEXT-FIELD: Event when the employee passcode field changes (Only For Employee)
class TemporaryPasscodeChanged extends WorkspaceAuthEvent {
  TemporaryPasscodeChanged(this.passcode);

  final String passcode;

  @override
  List<Object> get props => [passcode];
}

/// [AddressChanged] TEXT-FIELD
class AddressChanged extends WorkspaceAuthEvent {
  AddressChanged(this.address);

  final String address;

  @override
  List<Object> get props => [address];
}

/// [SignInPasswordChanged] TEXT-FIELD: Event when the password field changes
class SignInPasswordChanged extends WorkspaceAuthEvent {
  SignInPasswordChanged(this.password);

  final String password;

  @override
  List<Object> get props => [password];
}

/// [SignInRequested] BUTTON: Event to submit Workspace sign-in form
class SignInRequested extends WorkspaceAuthEvent {}

/// [UpdatePasswordRequested] BUTTON: Event to submit Update Workspace Password form
class UpdatePasswordRequested extends WorkspaceAuthEvent {}

/// [PasswordRecoveryRequested] BUTTON: Event to submit Workspace Password Recovery form
class PasswordRecoveryRequested extends WorkspaceAuthEvent {}

/// [CreateWorkspaceRequested] BUTTON: Event to submit sign-up form
class CreateWorkspaceRequested extends WorkspaceAuthEvent {}

/*/// [EmployeeSignInRequested] BUTTON: Event to submit Employee sign-in form
class EmployeeSignInRequested extends SignInEvent {}
/// [ChangeTemporaryPasscodeRequested] BUTTON: Event to submit Change Employee Temporary Passcode form
class ChangeTemporaryPasscodeRequested extends SignInEvent {}
 */
