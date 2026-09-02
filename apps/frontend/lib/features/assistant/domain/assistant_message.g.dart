// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssistantTurn _$AssistantTurnFromJson(Map<String, dynamic> json) =>
    _AssistantTurn(
      reply: json['reply'] as String,
      evidence: AssistantEvidence.fromJson(
        json['evidence'] as Map<String, dynamic>,
      ),
      groundingWarnings: (json['grounding_warnings'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AssistantTurnToJson(_AssistantTurn instance) =>
    <String, dynamic>{
      'reply': instance.reply,
      'evidence': instance.evidence.toJson(),
      'grounding_warnings': instance.groundingWarnings,
    };
