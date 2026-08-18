import 'package:chat_app/core/widgets/no_internet_view.dart';
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  bool get _isOffline {
    final lower = message.toLowerCase();
    return lower.contains('internet') || lower.contains('offline');
  }

  bool get _isTimeout => message.toLowerCase().contains('timed out');

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return NoInternetView(onRetry: onRetry);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 12),
            Text(
              _isTimeout ? 'Request timed out' : 'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
