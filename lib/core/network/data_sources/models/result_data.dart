// lib/core/result/result.dart

/// A sealed class representing the outcome of an operation.
/// It can be either a [Success] containing the result data,
/// or a [Failure] containing an optional error message.
sealed class Result<T> {}

class Success<T> extends Result<T> {
  final T data;
  Success({required this.data});
}

class Failure<T> extends Result<T> {
  final String? message;
  Failure({this.message});
}

/// [LoadResult] A generic class to wrap the result of a fetch operation.
/// It contains two fields:
/// 1. [data] - The primary data (typically a `Set<String>`) returned from the fetch operation.
/// 2. [meta] - Optional metadata related to the fetched data (e.g., role name, status, etc.).
///
/// The metadata type is generic (T), allowing flexibility in the kind of metadata it holds.
class LoadResult<T, K> {
  /// [data] The data that is fetched (usually a `Set<String>`).
  final Set<K> data;

  /// [meta] Optional metadata related to the data (e.g., role name).
  final T? meta;

  /// Constructor for LoadResult. The [data] field is required, while [meta] is optional.
  LoadResult({required this.data, this.meta});
}
