part of 'tenant_bloc.dart';

/// Events
///
sealed class TenantEvent<T> extends Equatable {
  const TenantEvent();

  @override
  List<Object?> get props => [];
}

class RefreshTenants<T> extends TenantEvent<T> {
  const RefreshTenants();
}

class LoadSubscriptions<T> extends TenantEvent<T> {}

class AddSubscription<T> extends TenantEvent<T> {
  final T data;

  ///NOTE: If not provided, Firestore will assign a unique ID (documentId) [documentId]
  final String? documentId;

  const AddSubscription({this.documentId, required this.data});

  @override
  List<Object?> get props => [documentId, data];
}

class LoadTenants<T> extends TenantEvent<T> {
  const LoadTenants();
}

class LoadTenantById<T> extends TenantEvent<T> {
  final Object? field;
  final String documentId;

  const LoadTenantById({required this.documentId, this.field});

  @override
  List<Object?> get props => [documentId, field];
}

/// T data: Generic Data Update: using Model-Class
///   --OR-- Note:: use Generic or Map data update
/// Map? mapData: `Map<String, dynamic>` Data Update
class UpdateTenant<T> extends TenantEvent<T> {
  final T? data;
  final Map<String, dynamic>? mapData;
  final String documentId;

  const UpdateTenant({required this.documentId, this.data, this.mapData});

  @override
  List<Object?> get props => [data, documentId];
}

class OverrideTenant<T> extends UpdateTenant<T> {
  const OverrideTenant({required super.documentId, super.data, super.mapData});
}

class RevokeAuthorizedDeviceId<T> extends UpdateTenant<T> {
  const RevokeAuthorizedDeviceId({
    required super.documentId,
    required super.data,
  });
}

class DeleteTenant<T> extends TenantEvent<T> {
  final T documentId;

  const DeleteTenant({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

/// Internal events for state updates
///
// Multiple Tenants loaded
class _TenantsLoaded<T> extends TenantEvent<T> {
  final List<T> data;

  const _TenantsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

// single Tenant loaded
class _TenantLoaded<T> extends TenantEvent<T> {
  final T data;

  const _TenantLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class _TenantError<T> extends TenantEvent<T> {
  final String error;

  const _TenantError(this.error);

  @override
  List<Object?> get props => [error];
}
