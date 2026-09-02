import '../../../core/network/api_client.dart';
import '../domain/assistant_message.dart';

/// Talks to `POST /assistant/message`. No `profile` parameter here,
/// deliberately -- the model extracts structured profile facts from the
/// message itself; see api/v1/routers/assistant.py's module docstring.
class AssistantApi {
  AssistantApi(this._client);

  final ApiClient _client;

  /// Longer than [ApiClient]'s 15s default: a turn can involve up to two
  /// sequential LLM calls server-side, each budgeted 30s (see the backend's
  /// providers/gemini_provider.py and anthropic_provider.py) -- the
  /// client's own bound has to be comfortably above that worst case, or a
  /// slow-but-successful reply shows a spurious network error instead.
  /// Real measured round trips during live testing: 16.3s, 20.7s, 22.6s for
  /// the full two-call turn -- 90s leaves ample headroom above both that
  /// and the 60s server-side worst case.
  static const _receiveTimeout = Duration(seconds: 90);

  Future<AssistantTurn> sendMessage(String message) async {
    final json = await _client.post(
      '/assistant/message',
      data: {'message': message},
      receiveTimeout: _receiveTimeout,
    );
    return AssistantTurn.fromJson(json as Map<String, dynamic>);
  }
}
