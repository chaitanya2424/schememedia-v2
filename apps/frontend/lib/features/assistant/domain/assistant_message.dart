import 'package:freezed_annotation/freezed_annotation.dart';

import 'assistant_evidence.dart';

part 'assistant_message.freezed.dart';
part 'assistant_message.g.dart';

/// Mirrors `AssistantResponseOut`. `grounding_warnings` is surfaced
/// deliberately, not swept under the rug -- a non-empty list is the system
/// telling the UI the reply may not be fully trustworthy.
@freezed
sealed class AssistantTurn with _$AssistantTurn {
  const factory AssistantTurn({
    required String reply,
    required AssistantEvidence evidence,
    required List<String> groundingWarnings,
  }) = _AssistantTurn;

  factory AssistantTurn.fromJson(Map<String, dynamic> json) => _$AssistantTurnFromJson(json);
}

/// One turn of local-only chat history -- the backend is stateless per
/// request today (see api/v1/routers/assistant.py), so conversation state
/// lives entirely on the client.
@freezed
sealed class ChatEntry with _$ChatEntry {
  const factory ChatEntry.user(String message) = ChatEntryUser;
  const factory ChatEntry.assistant(AssistantTurn turn) = ChatEntryAssistant;
  const factory ChatEntry.error(String message) = ChatEntryError;
}
