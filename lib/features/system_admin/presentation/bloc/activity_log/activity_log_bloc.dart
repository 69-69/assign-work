import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/activity_log_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

/// Track Login User Activity(Areas or modules used)
class ActivityLogBloc extends SetupBloc<ActivityLog> {
  ActivityLogBloc({required super.firestore})
    : super(
        collectionPath: employeeSessionLogsColPath,
        fromFirestore: (data, id) => ActivityLog.fromMap(data, id: id),
        toFirestore: (log) => log.toMap(),
        toCache: (log) => log.toCache(),
      );
}
