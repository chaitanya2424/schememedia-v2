import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';

/// The one shared loading/error/empty/data renderer for `AsyncValue<T>` --
/// what makes loading/error handling actually consistent across every
/// screen instead of five bespoke implementations. See the frontend
/// architecture plan's State management and Error handling sections.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.isEmpty,
    this.emptyBuilder,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) data;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (loaded) {
        if (isEmpty != null && emptyBuilder != null && isEmpty!(loaded)) {
          return emptyBuilder!(context);
        }
        return data(context, loaded);
      },
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _ErrorView(error: error, onRetry: onRetry),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (message, canRetry) = _describe(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (onRetry != null && canRetry) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }

  /// (message, canRetry) per [ApiException] variant -- e.g. a validation
  /// error isn't fixed by retrying the same request, a network or 5xx
  /// error might be.
  (String, bool) _describe(Object error) {
    if (error is ApiException) {
      return switch (error) {
        ApiNetworkException() => ('No connection. Check your network and try again.', true),
        ApiNotFoundException(:final message) => (message, false),
        ApiValidationException() => ('Some of the information provided was not valid.', false),
        ApiUnavailableException(:final message) => (message, true),
        ApiServerException(:final message) => (message, true),
        ApiUnknownException(:final message) => (message, true),
      };
    }
    return ('Something went wrong.', true);
  }
}
