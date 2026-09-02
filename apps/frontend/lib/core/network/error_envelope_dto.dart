import 'package:freezed_annotation/freezed_annotation.dart';

part 'error_envelope_dto.freezed.dart';
part 'error_envelope_dto.g.dart';

/// Mirrors the backend's one error JSON shape:
/// `{"error": {"code", "message", "request_id", "details"}}`
/// (core/errors.py's `ErrorEnvelopeOut`/`ErrorDetailOut`). Used only inside
/// `core/network` to build a typed [ApiException] -- never passed further
/// up the stack itself.
@freezed
sealed class ErrorDetailDto with _$ErrorDetailDto {
  const factory ErrorDetailDto({
    required String code,
    required String message,
    String? requestId,
    Map<String, dynamic>? details,
  }) = _ErrorDetailDto;

  factory ErrorDetailDto.fromJson(Map<String, dynamic> json) =>
      _$ErrorDetailDtoFromJson(json);
}

@freezed
sealed class ErrorEnvelopeDto with _$ErrorEnvelopeDto {
  const factory ErrorEnvelopeDto({required ErrorDetailDto error}) = _ErrorEnvelopeDto;

  factory ErrorEnvelopeDto.fromJson(Map<String, dynamic> json) =>
      _$ErrorEnvelopeDtoFromJson(json);
}
