import 'package:assign_erp/core/constants/account_status.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/// Role-Based Access-Control [Employee]
class Employee extends Equatable {
  static get _today => DateTime.now();

  final String id;

  /// [employeeId] employee/staff Unique ID for Employee's Tag or Card
  final String employeeId;
  final String storeNumber;
  final String workspaceId;
  final String fullName;
  final String mobileNumber;
  final String username;
  final String role; // role name
  final String roleId;
  final String departmentCode;
  final String email;
  final String status;

  final String passCode;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AuditLog> history;

  Employee({
    this.id = '',
    this.employeeId = '',
    required this.workspaceId,
    this.storeNumber = '', // fallback main-Store,
    this.username = '',
    required this.fullName,
    required this.mobileNumber,
    required this.role,
    required this.roleId,
    required this.departmentCode,
    required this.email,
    required this.status,
    this.passCode = '',
    this.createdBy = '',
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? const [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  static const String cacheKey = 'employee_auth_cache';

  /// fromFirestore / fromJson Function [Employee.fromMap]
  factory Employee.fromMap(Map<String, dynamic> map, {String? id}) {
    return Employee(
      id: (id ?? map['id']) ?? '',
      employeeId: map['employeeId'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      role: map['role'] ?? '',
      roleId: map['roleId'] ?? '',
      departmentCode: map['departmentCode'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      username: map['username'].toString().emailToUsername,
      status: map['status'] ?? AccountStatus.disabled.getName,
      passCode: map['passCode'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt']),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'employeeId': employeeId,
    'workspaceId': workspaceId,
    'storeNumber': storeNumber,
    'username': email.emailToUsername,
    'role': role,
    'roleId': roleId,
    'departmentCode': departmentCode,
    'email': email,
    'fullName': fullName,
    'mobileNumber': mobileNumber,
    'passCode': passCode,
    'status': status,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((e) => e.toMap()).toList(),
  };

  /// Convert Employee to a map for storing in Firestore [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// Convert Employee to toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': cacheKey, 'data': newMap};
  }

  Employee copyWith({
    String? id,
    String? employeeId,
    String? storeNumber,
    String? username,
    String? fullName,
    String? mobileNumber,
    String? role,
    String? roleId,
    String? departmentCode,
    String? email,
    String? passCode,
    String? status,
    String? workspaceId,
    String? updatedBy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      storeNumber: storeNumber ?? this.storeNumber,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      roleId: roleId ?? this.roleId,
      departmentCode: departmentCode ?? this.departmentCode,
      email: email ?? this.email,
      status: status ?? this.status,
      passCode: passCode ?? this.passCode,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
      history: history ?? this.history,
    );
  }

  /// Check if 'CreatedAt' DateTime is within one week after it was created [isWithinOneWeek]
  bool isWithinOneWeek() {
    // Calculate the date and time one week from now
    DateTime oneWeekFromNow = _today.add(const Duration(days: 7));

    // Check if its greater than now/today but less than a week
    return createdAt.isAfter(_today) && createdAt.isBefore(oneWeekFromNow);
  }

  /// A singleton instance representing an empty/default Employee.
  /// Used as a fallback when no matching Employee is found.
  static final Employee empty = Employee(
    id: '',
    workspaceId: '',
    fullName: '',
    mobileNumber: '',
    role: '',
    roleId: '',
    departmentCode: '',
    email: '',
    status: '',
    createdBy: '',
  );

  /// Returns true if this instance is the singleton [empty] Employee.
  /// Use this to check if the Employee is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, Employee.empty);

  /// Verified Status [isActive]
  bool get isActive => status == AccountStatus.enabled.getName;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  String get itemAsString => '$fullName - $role'.toTitle;

  /// Filter/Search
  bool filterByAny(String filter) =>
      itemAsList.filterAny(filter) || {email, username}.filterAny(filter);

  /// [findById]
  static Iterable<Employee> findById(List<Employee> employees, String id) =>
      employees.where((employee) => employee.id == id);

  static List<Employee> filterStatus(
    List<Employee> employees, {
    bool isActive = false,
  }) => employees
      .where((employee) => isActive ? employee.isActive : !employee.isActive)
      .toList();

  @override
  List<Object?> get props => [
    id,
    employeeId,
    workspaceId,
    role,
    roleId,
    departmentCode,
    email,
    username,
    fullName,
    mobileNumber,
    passCode,
    status,
    storeNumber,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  /// ToList for Employee [itemAsList]
  List<String> get itemAsList => [
    id,
    employeeId,
    status.toTitle,
    departmentCode,
    role.toTitle,
    storeNumber.toTitle,
    fullName.toTitle,
    mobileNumber,
    getCreatedAt,
    createdBy.toTitle,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Employee ID',
    'Status',
    'Dept. Code',
    'Role',
    'Store no.',
    'Name',
    'Mobile',
    'Created At',
    'Created By',
    'Updated By',
    'Updated At',
  ];
}
