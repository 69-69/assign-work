import 'dart:async';

import 'package:assign_erp/config/routes/route_logger.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/models/result_data.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/firestore_helper.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/firestore_repository.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/device_info_service.dart';
import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/extensions/account_status.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/secret_hasher.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/access_control/domain/repository/access_control_repository.dart';
import 'package:assign_erp/features/auth/data/data_sources/local/auth_cache_service.dart';
import 'package:assign_erp/features/auth/data/data_sources/remote/geo_location_service.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/data/role/workspace_role.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_status_enum.dart';
import 'package:assign_erp/features/auth/presentation/bloc/sign_in/workspace/workspace_creation_stages.dart';
import 'package:assign_erp/features/system_admin/data/models/activity_log_model.dart';
import 'package:assign_erp/features/system_admin/data/models/company_store_model.dart';
import 'package:assign_erp/features/system_admin/data/models/department_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/permission/setup_permission.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// User? authUser = FirebaseAuth.instance.currentUser;
final _today = DateTime.now();

/// Using dynamicLinkDomain in Desktop Applications
/// Custom URL Schemes
/// Example Workflow for Desktop Apps
/// Example of Using ActionCodeSettings
/// Alternatives to Firebase Dynamic Links
/// Universal Links (iOS) and App Links (Android)
///
class AuthRepository extends FirestoreRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore firestore;
  final RouteLogger routeLogger;
  final AccessControlRepository accessControlRepo;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    required this.firestore,
    required this.routeLogger,
    required this.accessControlRepo,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       super(
         firestore: firestore,
         collectionRef: firestore.collection(workspaceAccDBColPath),
       );

  /// A temporary variable to hold new-user's Workspace ID & Agent ID
  String _newWorkspaceId = '';
  bool isRegistered = false;
  String _registrarAgentId = '';

  final _controller = StreamController<AuthStatus>.broadcast();

  User? get firebaseUser => _firebaseAuth.currentUser;
  final AuthCacheService _authCacheService = AuthCacheService();

  /// Stream FirebaseAuth AuthState Changes [firebaseAuthStateChanges]
  Stream<User?> get firebaseAuthStateChanges =>
      _firebaseAuth.authStateChanges();

  /// Stream AuthStatus Changes [authStatusChanges]
  Stream<AuthStatus> get authStatusChanges async* {
    await Future<void>.delayed(kRProgressDelay);

    if (!isRegistered) {
      yield (firebaseUser?.uid ?? '').isNotEmpty
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    }

    yield* _controller.stream;
  }

  Future<Workspace?> getWorkspace({String? uid}) async {
    try {
      final id = uid ?? firebaseUser?.uid;
      if (id == null) {
        return null;
      }

      // Try to get the workspace from the cache
      Workspace? cacheWorkspace = _getWorkspaceCache();
      if (cacheWorkspace != null || cacheWorkspace!.unExpired) {
        return cacheWorkspace;
      }

      // else, Fetch the workspace from remote source
      final docSnapshot = await findById(id);

      // Check if the document exists and is not empty
      if (docSnapshot.exists && !docSnapshot.data().isNullOrEmpty) {
        final workspace = Workspace.fromMap(docSnapshot.data()!);

        if (workspace.isExpired) return null;

        // Write to cache
        await _cacheWorkspace(workspace);
        return workspace;
      }

      // Return null if no valid data found
      return null;
    } catch (e /*, stackTrace*/) {
      _handleAuthException(
        "An error occurred during getting signed-In workspace data.",
      );
      return null; // Return null or handle the exception according to your needs
    }
  }

  Future<Employee?> getEmployee() async {
    try {
      // Try to get the Employee from the cache
      Employee? cacheEmployee = _getEmployeeCache();
      if (cacheEmployee != null &&
          cacheEmployee.status == AccountStatus.enabled.getName &&
          cacheEmployee.workspaceId == firebaseUser?.uid) {
        return cacheEmployee;
      }

      // Return null if the document does not exist or is empty
      return null;
    } catch (e /*, stackTrace*/) {
      _handleAuthException(
        "An error occurred during getting signed-In employee data.",
      );
      return null; // Return null or handle the exception according to your needs
    }
  }

  Workspace? _getWorkspaceCache() => _authCacheService.getWorkspace();

  Employee? _getEmployeeCache() => _authCacheService.getEmployee();

  /// [assignWorkspaceRole] Determines the role for a "New Workspace Setup" based on the
  /// currently signed-in user's role (cached workspace role).
  ///
  /// Used during the "Setup/Create New Workspace" flow. [assignWorkspaceRole]
  WorkspaceRole get assignWorkspaceRole {
    Workspace? cacheWorkspace = _getWorkspaceCache();

    return cacheWorkspace?.role.assign ?? WorkspaceRole.tenant;
  }

  Future<void> _cacheWorkspace(Workspace workspace) async =>
      await _authCacheService.setWorkspace(workspace);

  Future<void> _cacheEmployee(Employee employee) async =>
      await _authCacheService.setEmployee(employee);

  Future<Result<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _validateWorkspaceAccess(String email) async {
    try {
      // Fetch the workspace document by email
      final doc = await _fetchWorkspaceByEmail(email);

      // workspace not created
      if (doc == null) {
        return Failure(
          message:
              '$errorPrefix:Email is not associated with any existing workspace.',
        );
      }

      // Convert doc data to Workspace
      final workspace = Workspace.fromMap(doc.data());

      final subMsg = '$errorPrefix:Software is unlicensed / expired';
      if (workspace.subscriptionId.isEmpty) {
        return Failure(message: subMsg);
      }
      final sub = await accessControlRepo.fetchLicensesForSubscription(
        workspace.subscriptionId,
      );

      // Validate workspace and license status
      final isUnlicensed = sub.data.isEmpty || workspace.isExpired;

      if (isUnlicensed) {
        return Failure(message: subMsg);
      }

      final userDeviceId = await DeviceInfoService.getDeviceId();

      // Device-Id not previously authorized, else skip
      if (!workspace.isDeviceAuthorized(userDeviceId)) {
        if (workspace.isDeviceLimitReached) {
          return Failure(
            message: '$errorPrefix:Upgrade your Plan: Too many devices in use',
          );
        }

        // Add current deviceId to authorized list
        await updateById(
          doc.id,
          data: {
            'authorizedDeviceIds': FieldValue.arrayUnion([userDeviceId]),
            /* Remove an item from the array
            'authorizedDeviceIds': FieldValue.arrayRemove([userDeviceId]),*/
          },
        );
      }

      return Success(data: doc);
    } catch (e) {
      var e2 = "An error occurred while validating workspace sign-in.";
      _handleAuthException(e, message: e2);

      return Failure(message: e2);
    }
  }

  /// [workspaceSignIn] Signs a user into their Workspace account using email and password.
  ///
  /// - Retrieves the workspace document by [email].
  /// - Verifies that the license is active and the account is enabled.
  /// - Ensures the current device is within the allowed list.
  /// - Attempts to authenticate the user using Firebase Authentication.
  /// - If successful, returns the authenticated [Workspace] object.
  ///
  /// Returns a [Future] containing a record of:
  /// - `workspace`: the signed-in [Workspace] object (nullable).
  /// - `message`: an optional message in case of failure.
  ///
  /// Possible failure messages include:
  /// - `Software is unlicensed / expired`
  /// - `Device is unauthorized`
  /// - `Extend Your License: Too many devices in use`
  /// - `Invalid email or password`
  /// - `Please verify your email...`
  Future<({Workspace? workspace, String? message})> workspaceSignIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _validateWorkspaceAccess(email);

      if (result is Failure) {
        return (workspace: null, message: (result as Failure).message);
      }

      // Attempt to sign in with Firebase
      final userCredential = await _signInUser(email, password);
      if (userCredential == null) {
        return (workspace: null, message: 'Invalid email or password');
      }
      final user = userCredential.user;

      // Check if the user's email is verified
      if (user != null && !user.emailVerified) {
        // Send email verification and notify the user
        await _sendEmailVerification(user);
        _handleAuthException(
          "Please verify your email. A verification link has been sent to $email.",
        );
      }

      // Extract data from the document
      final doc = (result as Success).data;
      final data = doc.data();

      // Convert the data to a Workspace object
      final workspace = Workspace.fromMap(data, id: doc.id);

      // Cache the workspace data for future use
      await _cacheWorkspace(workspace);

      await _logAuthSession(
        workspace.id,
        'sign-in',
        name: workspace.name,
        colPath: workspaceSessionLogsColPath,
      );

      _controller.add(AuthStatus.workspaceAuthenticated);

      // Return the Workspace object
      return (workspace: workspace, message: '');
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication exceptions with a specific message
      _handleAuthException(
        e,
        message: e.message ?? "An error occurred during workspace sign-in.",
      );
      return (
        workspace: null,
        message: e.message ?? 'An error occurred during workspace sign-in.',
      );
    } catch (e) {
      // Handle any other exceptions with a general message
      _handleAuthException("An unexpected error occurred: $e");
      return (workspace: null, message: 'An unexpected error occurred');
    }
  }

  /*/// Remove device ID from a user's authorized device list.
  Future<void> revokeDeviceFromAuthorizedList({
    required String deviceId,
    required String email,
  }) async {
    final doc = await _fetchWorkspaceUserByEmail(email);

    if (doc == null) return;

    await updateById(
      doc.id,
      data: {
        'authorizedDeviceIds': FieldValue.arrayRemove([deviceId]),
      },
    );
  }*/

  /// Signs in an employee using their email and passcode.
  /// Returns a tuple with the `employee` and `workspace` if successful, otherwise `null` for both.
  ///
  /// [email] - The email address of the employee.
  /// [passCode] - The passcode used for authentication.
  ///
  /// Returns a [Future] containing a tuple with optional `Employee` and `Workspace` objects.
  Future<({Employee? employee, Workspace? workspace, String? message})>
  employeeSignIn({required String email, required String passCode}) async {
    const invalid = (employee: null, workspace: null, message: '');

    try {
      // Fetch Employee document using email and passcode
      final result = await _fetchEmployeeByEmailPasscode(email, passCode);

      if (result is Failure) {
        return (
          employee: null,
          workspace: null,
          message: (result as Failure).message,
        );
      }
      // Get the workspace of the currently authenticated user
      final workspace = firebaseUser;

      // Check if the workspace is available, document is not null, and status is active
      if (workspace == null) {
        return invalid;
      }

      // Extract data from the document
      final doc = (result as Success).data;
      final data = doc.data();

      // Convert the data to an Employee object
      final employee = Employee.fromMap(data, id: doc.id);

      if (employee.status != AccountStatus.enabled.getName ||
          employee.workspaceId != workspace.uid ||
          employee.roleId.isEmpty) {
        return invalid;
      }

      // Cache the employee data
      await _cacheEmployee(employee);

      /// Determines whether the provided passcode is a Temporary passcode.
      ///
      /// If [isTemporaryPasscode] is `true`, the user should be prompted to create
      /// a new permanent passcode. Otherwise, the user can be routed to the home dashboard.
      bool isTemporaryPasscode = passCode.startsWith(kTemporaryPasscodePrefix);

      // Retrieve the workspace user details
      final workspaceUser = await getWorkspace(uid: workspace.uid);

      final status = isTemporaryPasscode
          ? AuthStatus.hasTemporaryPasscode
          : AuthStatus.authenticated;

      _controller.add(status);

      // Return the employee and workspace objects
      return (employee: employee, workspace: workspaceUser, message: '');
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication exceptions
      _handleAuthException(
        e,
        message: e.message ?? "An error occurred during employee sign-in.",
      );
      return invalid;
    } catch (e) {
      // Handle any other types of exceptions
      _handleAuthException("An unexpected error occurred: $e");
      return invalid;
    }
  }

  /// Changes the temporary PassCode for employee.
  ///
  /// [workspaceId] - The unique identifier of the employee whose passcode needs to be updated.
  /// [newPasscode] - The new passcode to be set for the employee.
  ///
  /// This method performs the following steps:
  /// 1. Fetch the employee info using the provided [workspaceId] and a workspace ID.
  /// 2. Hashes the provided [newPasscode] using the `PasswordHash.hashPassword` method to ensure security.
  /// 3. Updates the employee with the hashed passcode.
  Future<({Employee? employee, Workspace? workspace})>
  changeEmployeeTemporaryPassCode({required String newPasscode}) async {
    final invalid = (employee: null, workspace: null);

    try {
      // Try to get the workspace from the cache
      Workspace? cacheWorkspace = _getWorkspaceCache();
      Employee? cacheEmployee = _getEmployeeCache();

      if (cacheWorkspace == null || cacheEmployee == null) {
        return invalid;
      }

      final docRef = _genericCollection(
        workspaceRole: EnumUtil<WorkspaceRole>(cacheWorkspace.role).getName,
        workspaceId: cacheWorkspace.id,
      ).doc(cacheEmployee.id);

      if (docRef.id.isNotEmpty) {
        // Hash the new passcode to enhance security and prevent it from being exposed
        final hashPasscode = SecretHasher.hash(newPasscode);

        // Update the employee document with the hashed passcode
        await docRef.update({'passCode': hashPasscode});

        // Retrieve the workspace user details
        final workspace = await getWorkspace();
        final employee = await getEmployee();

        _controller.add(AuthStatus.authenticated);
        // Return the employee and workspace objects
        return (employee: employee, workspace: workspace);
      }

      _controller.add(AuthStatus.unauthenticated);
      return invalid;
    } catch (e) {
      // Handle any other types of exceptions
      _handleAuthException("An unexpected error occurred: $e");

      return invalid;
    }
  }

  /// Creates a new workspace by registering a user and setting up related data.
  ///
  /// [email] - The email address for the new user.
  /// [clientName] - The full name of the new user.
  /// [password] - The password for the new user.
  /// [mobileNumber] - The mobile number of the new user.
  /// [registerNewWorkspace]
  /// Returns a [Future<bool>] indicating whether the workspace creation was successful.
  Future<bool> registerNewWorkspace({
    required String workspaceName,
    required String email,
    required String address,
    required String clientName,
    required String password,
    required String mobileNumber,
    required String workspaceCategory,
    required String employeeTemporaryPasscode,
    required void Function(WorkspaceCreationStage) onProgress,
  }) async {
    try {
      // Store agent ID temporarily, so we don't loose it when newUser is created
      _registrarAgentId = firebaseUser!.uid;

      // Call stage update here
      onProgress(WorkspaceCreationStage.registeringEmail);
      // Create a new User via Firebase Authentication.
      final UserCredential userCredential = await _createUser(email, password);
      final User? newUser = userCredential.user;

      if (newUser != null && newUser.uid != _registrarAgentId) {
        // Store user ID temporarily, so we don't loose it when signOut
        _newWorkspaceId = newUser.uid;
        isRegistered = true;

        // Send email verification to the new newUser.
        await _sendEmailVerification(newUser);

        // Sign out immediately after sending verification email.
        // This prevents a situation where the new user remains signed in on the agent's device.
        await _firebaseAuth.signOut();

        // FOR ORGANIZATION'S WORKSPACE CREATION/SETUP
        onProgress(WorkspaceCreationStage.creatingWorkspace);
        await _createWorkspace(
          email: email,
          address: address,
          clientName: clientName,
          mobileNumber: mobileNumber,
          workspaceName: workspaceName,
          workspaceCategory: workspaceCategory,
          agentId: _registrarAgentId,
        );

        // FOR ROLE-PERMISSION CREATION (Business Owner)
        onProgress(WorkspaceCreationStage.creatingDefaultRolePermission);
        final role = await _createBusinessOwnerRoleAndPerm();

        // FOR DEFAULT(Main) STORE-BRANCH CREATION (Business Owner)
        onProgress(WorkspaceCreationStage.creatingDefaultBusinessLocation);
        final storeNumber = await _createBusinessOwnerPrimaryBranch(
          address: address,
          company: workspaceName,
        );

        // FOR DEPARTMENT CREATION (Business Owner)
        onProgress(WorkspaceCreationStage.creatingDefaultDepartment);
        final departmentCode = await _createBusinessOwnerDepartment();

        // FOR EMPLOYEE CREATION (Business Owner)
        onProgress(WorkspaceCreationStage.creatingEmployee);
        await _createEmployee(
          email: email,
          fullName: clientName,
          storeNumber: storeNumber,
          mobileNumber: mobileNumber,
          createdBy: _registrarAgentId,
          employeePasscode: employeeTemporaryPasscode,
          code: departmentCode,
          role: role,
        );

        // Link Agent to their Tenants/Clients workspace (AGENT -> CLIENT)
        onProgress(WorkspaceCreationStage.linkingAgent);
        await _linkAgentToClientWorkspace(clientWorkspaceId: _newWorkspaceId);

        onProgress(WorkspaceCreationStage.success);
        // SignOut current Workspace & Employee, if new Workspace setup was successfully
        // await signOut();
        // _controller.add(AuthStatus.unauthenticated);

        return true;
      }

      onProgress(WorkspaceCreationStage.failure);
      // Return false if newUser creation was unsuccessful.
      return false;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors.
      _handleAuthException(
        e,
        message: e.message ?? "An error occurred during sign-up.",
      );
      return false;
    } catch (e) {
      // Handle unexpected errors.
      _handleAuthException("An unexpected error occurred: ${e.toString()}");
      return false;
    }
  }

  /// Associates an agent with a client workspace.
  /// Firestore path: /agent_clients/{agentId}/clients/{clientWorkspaceId}
  Future<bool> _linkAgentToClientWorkspace({
    required String clientWorkspaceId,
  }) async {
    try {
      /// NOTE: workspaceId is used as agentId
      await _genericCollection(
        collectionType: CollectionType.clients,
        collectionPath: agentClientsDBColPath,
      ).doc(clientWorkspaceId).set({
        'commission': [],
        'clientWorkspaceId': clientWorkspaceId,
        'assignedAt': _today.toMilliseconds,
      });

      return true;
    } on FirebaseException catch (e) {
      // Handle Firestore errors.
      _handleAuthException(
        e,
        message: e.message ?? "An error occurred while linking the client.",
      );
      return false;
    } catch (e) {
      // Handle unexpected errors.
      _handleAuthException("Unexpected error: ${e.toString()}");
      return false;
    }
  }

  /// Creates a new user in Firebase Authentication.
  ///
  /// [email] - The email address for the new user.
  /// [password] - The password for the new user.
  ///
  /// Returns a [Future<UserCredential>] with the result of the user creation. [_createUser]
  Future<UserCredential> _createUser(String email, String password) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Creates a new Workspace or updates an existing one in Firestore.
  ///
  /// This method sets up a new workspace for a client or customer, using the
  /// provided information. It assigns a default role and
  /// marks the license as unauthorized until verified.
  ///
  /// Parameters:
  /// - [workspaceName]: The name of the client's company or workspace.
  /// - [email]: The email address associated with the workspace.
  /// - [clientName]: The full name of the client or customer.
  /// - [mobileNumber]: The client's mobile phone number.
  /// - [workspaceCategory]: The type of business type (e.g., real estate, retail, logistics).
  /// - [agentId]: The ID of the agent who is creating or updating the workspace.
  ///
  /// Returns a [Future<void>]. [_createWorkspace]
  Future<void> _createWorkspace({
    required String email,
    required String address,
    required String clientName,
    required String mobileNumber,
    required String workspaceName,
    required String workspaceCategory,
    required String agentId,
  }) async {
    final aId = agentId.isNullOrEmpty ? _registrarAgentId : agentId;

    final workspace = Workspace(
      id: _newWorkspaceId,
      role: assignWorkspaceRole,
      email: email,
      agentId: aId,
      address: address,
      subscriptionId: '',
      name: workspaceName,
      clientName: clientName,
      mobileNumber: mobileNumber,
      category: workspaceCategory,
    );
    final newMap = workspace.toMap();
    // update map
    newMap['effectiveFrom'] = _today.toMilliseconds;
    newMap['expiresOn'] = _today.toMilliseconds;
    newMap['createdAt'] = _today.toMilliseconds;

    await overrideById(_newWorkspaceId, data: newMap);
  }

  /// Creates and saves employee data in Firestore.
  ///
  /// [user] - The newly created user who will be an employee.
  /// [fullName] - The full name of the new employee.
  /// [mobileNumber] - The mobile number of the new employee.
  /// [password] - The password for the new employee.
  ///
  /// Returns a [Future<void>] [_createEmployee]
  Future<void> _createEmployee({
    required String email,
    required String fullName,
    required String storeNumber,
    required String mobileNumber,
    required String employeePasscode,
    required String createdBy,
    required String code,
    required ({String id, String name}) role,
  }) async {
    final workspaceId = _newWorkspaceId;
    final workspaceRole = EnumUtil<WorkspaceRole>(assignWorkspaceRole).getName;

    // Add a new document to the collection and get its reference
    final DocumentReference docRef = _genericCollection(
      workspaceRole: workspaceRole,
      workspaceId: workspaceId,
    ).doc(); // Generates a new document reference with an auto-generated ID

    // Extract the document ID

    final byWho = await getEmployee();
    final empId = (await DocType.employee.getShortStr());

    // Create an Employee instance with the document ID
    final employee = Employee(
      id: docRef.id,
      employeeId: empId ?? '',
      workspaceId: workspaceId,
      storeNumber: storeNumber,
      isBusinessOwner: true,
      roleId: role.id,
      role: role.name,
      departmentCode: code,
      email: email,
      fullName: fullName,
      mobileNumber: mobileNumber,
      status: AccountStatus.enabled.getName,
      createdBy: byWho?.fullName ?? createdBy,
      passCode: SecretHasher.hash(employeePasscode),
    );

    final newMap = employee.toMap();
    // update map
    newMap['updatedAt'] = _today.toMilliseconds;
    newMap['createdAt'] = _today.toMilliseconds;

    // Add the employee data to the Firestore collection
    await docRef.set(newMap);
  }

  /// [_createBusinessOwnerRoleAndPerm] Creates the default permission set for the business owner
  /// during initial workspace setup (first-time tenant creation).
  /// @return `Future<({String id, String name})>`
  Future<({String id, String name})> _createBusinessOwnerRoleAndPerm() async {
    final workspaceId = _newWorkspaceId;
    final workspaceRole = EnumUtil<WorkspaceRole>(assignWorkspaceRole).getName;

    final docRef = _genericCollection(
      workspaceId: workspaceId,
      workspaceRole: workspaceRole,
      collectionPath: rolesDBColPath,
    ).doc();

    final defaultPerm = createBusinessOwnerRoleAndPerm(id: docRef.id);

    // update map
    defaultPerm['updatedAt'] = _today.toMilliseconds;
    defaultPerm['createdAt'] = _today.toMilliseconds;

    await docRef.set(defaultPerm);

    return (id: docRef.id, name: defaultPerm['name'] as String);
  }

  /// [_createBusinessOwnerDepartment] Creates the default department for the business owner
  /// during initial workspace setup (first-time tenant creation)
  /// @return `Future<String>`
  Future<String> _createBusinessOwnerDepartment() async {
    final workspaceId = _newWorkspaceId;
    final workspaceRole = EnumUtil<WorkspaceRole>(assignWorkspaceRole).getName;

    final docRef = _genericCollection(
      workspaceId: workspaceId,
      workspaceRole: workspaceRole,
      collectionPath: departmentsDBColPath,
    ).doc();

    final defaultDepart = createBusinessOwnerDepartment(id: docRef.id);

    // update map
    defaultDepart['updatedAt'] = _today.toMilliseconds;
    defaultDepart['createdAt'] = _today.toMilliseconds;

    await docRef.set(defaultDepart);

    return defaultDepart['code'] as String;
  }

  /// [_createBusinessOwnerPrimaryBranch] This is the Business owner's default(main) Store-Branch
  /// created during first-time tenant workspace setup(Workspace Creation)
  /// Its save in the Company's Store Branches DB
  ///
  /// @param address - The address of the store Branch.
  /// @param company - The name of the company.
  /// @return `Future<String>`
  Future<String> _createBusinessOwnerPrimaryBranch({
    required String address,
    required String company,
  }) async {
    final workspaceId = _newWorkspaceId;
    final workspaceRole = EnumUtil<WorkspaceRole>(assignWorkspaceRole).getName;

    final docRef = _genericCollection(
      workspaceId: workspaceId,
      workspaceRole: workspaceRole,
      collectionPath: storeLocationsDBColPath,
    ).doc();

    // Save into DB
    final defaultBranch = createBusinessOwnerPrimaryBranch(
      id: docRef.id,
      name: company,
      address: address,
    );

    // update map
    defaultBranch['updatedAt'] = _today.toMilliseconds;
    defaultBranch['createdAt'] = _today.toMilliseconds;

    await docRef.set(defaultBranch);

    return defaultBranch['storeNumber'] as String;
  }

  /// Provides a [CollectionReference] for specified collection path.
  CollectionReference<Map<String, dynamic>> _genericCollection({
    String? workspaceId,
    String? workspaceRole,
    String? collectionPath,
    CollectionType collectionType = CollectionType.workspace,
  }) {
    // Create a FirestoreHelper instance with current workspace role and ID
    final fireHelper = FirestoreHelper(
      firestore: firestore,
      workspaceId: workspaceId,
      workspaceRole: workspaceRole,
    );
    final cPath = collectionPath ?? employeesDBColPath;

    return fireHelper.getCollectionRef(collectionType: collectionType, cPath);
  }

  Future<bool> updateWorkspacePassword({required String newPassword}) async {
    try {
      if (firebaseUser != null) {
        await _updatePassword(newPassword);

        _controller.add(AuthStatus.authenticated);
        return true;
      }
      return false;
    } catch (e) {
      // Handle any other exceptions with a general message
      _handleAuthException("An unexpected error occurred: $e");
      return false;
    }
  }

  Future<bool> forgotWorkspacePassword({required String email}) async {
    try {
      // Fetch the workspace document based on the email
      final queryDocSnap = await _fetchWorkspaceByEmail(email);

      // Check if account is available and not expired
      if (queryDocSnap!.exists && !queryDocSnap.data().isNullOrEmpty) {
        final workspace = Workspace.fromMap(queryDocSnap.data());

        if (workspace.isExpired) return false;

        await _forgotPassword(email);
        return true;
      }

      return false;
    } catch (e) {
      // Handle any other types of exceptions
      _handleAuthException("An unexpected error occurred: $e");
      return false;
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      await firebaseUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      _handleAuthException(
        e,
        message: e.message ?? "An error occurred while updating password.",
      );
    }
  }

  Future<void> _forgotPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _handleAuthException(
        e,
        message:
            e.message ??
            "An error occurred while sending password reset email.",
      );
    }
  }

  // ignore: unused_element
  Future<void> _resendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      _handleAuthException(
        e,
        message:
            e.message ??
            "An error occurred while sending the verification email.",
      );
    }
  }

  // ignore: unused_element
  Future<void> _completeEmailVerification(String oobCode) async {
    try {
      await FirebaseAuth.instance.applyActionCode(oobCode);
      // debugPrint('Email successfully verified!');
    } on FirebaseAuthException catch (e) {
      Exception('Error verifying email: ${e.message}');
    }
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _fetchWorkspaceByEmail(
    String email,
  ) async {
    final querySnapshot = await findOneByAny('email', term: email);
    if (querySnapshot.docs.isNotEmpty) {
      final snap = querySnapshot.docs.first;
      return snap.exists ? snap : null;
    }
    return null;
  }

  // Future<QueryDocumentSnapshot<Map<String, dynamic>>>
  Future<Result<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _fetchEmployeeByEmailPasscode(String email, String passCode) async {
    // Try to get the workspace from the cache
    Workspace? cacheWorkspace = _getWorkspaceCache();

    if (cacheWorkspace == null || cacheWorkspace.isExpired) {
      return Failure(
        message: '$errorPrefix:Workspace not found or license is unauthorized.',
      );
    }

    final workId = cacheWorkspace.id;
    final workRole = EnumUtil<WorkspaceRole>(cacheWorkspace.role).getName;

    final querySnap = await _genericCollection(
      workspaceId: workId,
      workspaceRole: workRole,
    ).where('email', isEqualTo: email).get();
    // .where('passCode', isEqualTo: PasswordHash.hashPassword(passCode))

    if (querySnap.docs.isEmpty) {
      return Failure(message: '$errorPrefix:Employee not found');
    }

    // Return the first document if available
    final doc = querySnap.docs.first;
    final data = doc.data();
    final roleId = data['roleId'] ?? '';
    final storedHashPasscode = data['passCode'] ?? '';

    if (roleId.isEmpty) {
      return Failure(
        message: '$errorPrefix:No permissions assigned to the employee\'s role',
      );
    }

    final perm = await accessControlRepo.fetchPermissionsForRole(
      roleId,
      workspaceId: workId,
      workspaceRole: workRole,
    );

    if (perm.data.isEmpty) {
      return Failure(
        message: '$errorPrefix:Employee currently unassigned to a role',
      );
    }

    // Verify passcode
    if (storedHashPasscode.isEmpty ||
        !SecretHasher.verify(passCode, hashed: storedHashPasscode)) {
      return Failure(message: '$errorPrefix:Invalid Passcode.');
    }

    // Log successful authentication
    await _logAuthSession(
      data['employeeId'],
      'sign-in',
      name: data['fullName'],
      workspaceId: workId,
      workspaceRole: workRole,
      colPath: employeeSessionLogsColPath,
    );

    return Success(data: doc);
  }

  /// SignIn with email and password via Firebase Authentication.
  Future<UserCredential?> _signInUser(String email, String password) async {
    try {
      // Attempt to sign in the user with the provided email and password
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // If successful, return the UserCredential
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Use the utility method to get the error message
      final errorMessage = getFirebaseAuthErrorMessage(e);
      prettyPrint('signInUser', errorMessage);
      return null; // Return null if sign-in fails
    } catch (e) {
      // Handle any other errors
      prettyPrint('An unexpected error occurred', '$e');
      return null; // Return null if an unexpected error occurs
    }
  }

  /// Sends an email verification to the newly created user.
  ///
  /// [user] - The newly created user who will receive the verification email.
  ///
  /// Returns a [Future<void>]. [_sendEmailVerification]
  Future<void> _sendEmailVerification(User user) async {
    /*final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
      // URL to redirect back to after email is verified
      url: 'https://yourapp.com/finishSignUp?user=${user.uid}',
      handleCodeInApp: true,
      // iOS
      iOSBundleId: 'com.example.ios',
      // Android
      androidPackageName: 'com.example.android',
      // Dynamic Link URL for web
      dynamicLinkDomain: 'example.page.link',
    );*/

    await user.sendEmailVerification(/*actionCodeSettings*/);
  }

  /// Log Workspace & Employee Auth Activity; Sign-In or Sign-Out. [_logAuthSession]
  Future<void> _logAuthSession(
    String id,
    String type, {
    String? name,
    String? colPath,
    String? workspaceId,
    String? workspaceRole,
  }) async {
    try {
      final geo = await GeoLocationService().getGeoLocation();

      final colType = workspaceRole == null
          ? CollectionType.global
          : CollectionType.workspace;

      final colRef = _genericCollection(
        collectionPath: colPath,
        collectionType: colType,
        workspaceId: workspaceId,
        workspaceRole: workspaceRole,
      ).doc();

      final areasViewed = routeLogger.visitedRoutes
          .map((e) => '${e.name} @ ${e.visitedAt.toStandardDT}')
          .toList();

      // Prepare log data
      final log = ActivityLog(
        id: colRef.id,
        type: type,
        userId: id,
        name: name ?? 'employee',
        ip: geo?.ip,
        city: geo?.city,
        region: geo?.region,
        areasViewed: areasViewed,
        location: geo != null ? GeoPoint(geo.latitude, geo.longitude) : null,
      );

      // Write to Firestore
      await colRef.set(log.toMap());

      prettyPrint('Activity-Log $type', 'saved successfully.');
    } catch (e) {
      prettyPrint('Failed to saved Activity-Log', '$e');
    }
  }

  void _handleAuthException(e, {String? message}) {
    throw Exception(message ?? e);
    // debugPrint('FirebaseAuthException: ${e.code} - ${e.message}\n');
    // debugPrint('Error Code: ${e.code}\n');
    // debugPrint('Error Message: ${e.message}\n');
    // debugPrint('Error Details: ${e.stackTrace}\n');
  }

  // Method to get error message based on FirebaseAuthException
  String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    // debugPrint('Steve-Er:: ${e.code}');

    switch (e.code) {
      case 'user-not-found':
        return 'User not found. Please check your email and try again.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'Your account has been disabled due to too many failed login attempts. Please contact support.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'The operation is not allowed.';
      default:
        return 'Sign in failed: ${e.message}';
    }
  }

  // SignOut current Workspace & Employee
  Future<void> signOut() async {
    Future.wait([
      _logSignOut(),
      _authCacheService.deleteEmployee(),
      _authCacheService.deleteWorkspace(),
      _firebaseAuth.signOut(),
      // _controller.close(),
    ]);
  }

  // Log signOut sessions for tracking and analytics
  Future<void> _logSignOut() async {
    Workspace? cacheWork = _getWorkspaceCache();
    Employee? cacheEmp = _getEmployeeCache();

    if (cacheWork == null) return;

    final workId = cacheWork.id;
    final workRole = EnumUtil<WorkspaceRole>(cacheWork.role).getName;

    await _logAuthSession(
      cacheEmp?.employeeId ?? cacheWork.id,
      'sign-out',
      name: cacheEmp?.fullName,
      workspaceId: workId,
      workspaceRole: workRole,
      colPath: employeeSessionLogsColPath,
    );
  }

  void _closeController() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  // Add this method if using in a context where disposing is required
  void dispose() {
    _closeController();
  }
}
