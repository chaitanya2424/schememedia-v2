import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/providers.dart';
import '../../data/assistant_api.dart';
import '../../data/assistant_repository.dart';
import '../../domain/assistant_message.dart';

final assistantApiProvider = Provider<AssistantApi>(
  (ref) => AssistantApi(ref.watch(apiClientProvider)),
);

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepository(ref.watch(assistantApiProvider)),
);

/// Local-only chat state: history plus whether a turn is currently
/// in-flight. Kept separate from `AsyncValue` -- the whole point of a chat
/// screen is that history stays visible while a reply is loading, which
/// `AsyncValue.loading()` (which replaces `.data`) doesn't model well.
class AssistantChatState {
  const AssistantChatState({this.history = const [], this.isSending = false});

  final List<ChatEntry> history;
  final bool isSending;

  AssistantChatState copyWith({List<ChatEntry>? history, bool? isSending}) =>
      AssistantChatState(history: history ?? this.history, isSending: isSending ?? this.isSending);
}

class AssistantNotifier extends StateNotifier<AssistantChatState> {
  AssistantNotifier(this._repository) : super(const AssistantChatState());

  final AssistantRepository _repository;

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || state.isSending) return;

    state = state.copyWith(history: [...state.history, ChatEntry.user(trimmed)], isSending: true);

    try {
      final turn = await _repository.sendMessage(trimmed);
      state = state.copyWith(history: [...state.history, ChatEntry.assistant(turn)], isSending: false);
    } on ApiException catch (e) {
      state = state.copyWith(history: [...state.history, ChatEntry.error(_messageFor(e))], isSending: false);
    } catch (_) {
      state = state.copyWith(
        history: [...state.history, const ChatEntry.error('Something went wrong. Please try again.')],
        isSending: false,
      );
    }
  }

  /// The backend's own message is used verbatim for `unavailable` (503) --
  /// e.g. "The assistant is temporarily unavailable. Please try again
  /// shortly." (core/errors.py's ServiceUnavailableError) -- rather than a
  /// generic client-side string, so the specific reason (provider down,
  /// quota exhausted, etc.) isn't lost.
  String _messageFor(ApiException e) => switch (e) {
    ApiNetworkException() => 'No connection. Check your network and try again.',
    ApiUnavailableException(:final message) => message,
    ApiValidationException() => 'That message could not be sent as written -- try shortening it.',
    ApiNotFoundException(:final message) => message,
    ApiServerException(:final message) => message,
    ApiUnknownException(:final message) => message,
  };
}

final assistantNotifierProvider = StateNotifierProvider<AssistantNotifier, AssistantChatState>(
  (ref) => AssistantNotifier(ref.watch(assistantRepositoryProvider)),
);
