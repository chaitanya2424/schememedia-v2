import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_exception.freezed.dart';

/// The only error type `presentation/` code ever handles. Every screen
/// catches this, never [DioException] directly -- see the frontend
/// architecture plan's API client design / error handling sections.
@freezed
sealed class ApiException with _$ApiException implements Exception {
  /// No connection could be made at all (offline, DNS failure, timeout).
  const factory ApiException.network() = ApiNetworkException;

  /// 422 with field-level detail (backend's `details.fields`, from
  /// `RequestValidationError`) -- e.g. the recommendations profile form.
  const factory ApiException.validation(Map<String, dynamic> fields) = ApiValidationException;

  /// 404 -- e.g. an unknown scheme identifier.
  const factory ApiException.notFound(String message) = ApiNotFoundException;

  /// 503 -- a backend dependency (DB, embedder, LLM provider) is down.
  /// Safe to retry, per the backend's own contract for this status.
  const factory ApiException.unavailable(String message) = ApiUnavailableException;

  /// Any other structured `{error:{...}}` response the backend sent.
  const factory ApiException.server({
    required String code,
    required String message,
    String? requestId,
  }) = ApiServerException;

  /// Anything that doesn't fit the above -- an unstructured 5xx, a body
  /// that failed to parse as the error envelope, etc.
  const factory ApiException.unknown(String message) = ApiUnknownException;
}

/// Pulls the [ApiException] a [_ErrorMappingInterceptor] attached to a
/// [DioException], with a safe fallback for anything that reached the
/// caller without going through that interceptor.
extension DioExceptionApiExceptionX on DioException {
  ApiException get asApiException {
    final carried = error;
    if (carried is ApiException) return carried;
    return ApiException.unknown(message ?? 'Something went wrong.');
  }
}
