// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_envelope_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ErrorDetailDto _$ErrorDetailDtoFromJson(Map<String, dynamic> json) =>
    _ErrorDetailDto(
      code: json['code'] as String,
      message: json['message'] as String,
      requestId: json['request_id'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ErrorDetailDtoToJson(_ErrorDetailDto instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'request_id': instance.requestId,
      'details': instance.details,
    };

_ErrorEnvelopeDto _$ErrorEnvelopeDtoFromJson(Map<String, dynamic> json) =>
    _ErrorEnvelopeDto(
      error: ErrorDetailDto.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ErrorEnvelopeDtoToJson(_ErrorEnvelopeDto instance) =>
    <String, dynamic>{'error': instance.error.toJson()};
