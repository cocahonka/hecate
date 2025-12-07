import 'package:flutter/material.dart';

class AppScopeFailedScreen extends StatefulWidget {
  AppScopeFailedScreen({
    required this.error,
    required this.stackTrace,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final StackTrace stackTrace;
  final Future<void> Function() onRetry;

  @override
  State<AppScopeFailedScreen> createState() => _AppScopeFailedScreenState();
}

class _AppScopeFailedScreenState extends State<AppScopeFailedScreen> {
  final _inProgress = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _inProgress.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    _inProgress.value = true;
    await widget.onRetry();
    _inProgress.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: _inProgress,
            builder: (context, inProgress, _) {
              final theme = Theme.of(context);
              final typography = theme.textTheme;
              final colorScheme = theme.colorScheme;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Main scope initialization failed',
                        style: typography.headlineMedium,
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: inProgress ? null : () => _retry(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    '${widget.error}',
                    style: typography.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      '${widget.stackTrace}',
                      style: typography.bodyLarge,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
