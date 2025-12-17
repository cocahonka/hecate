import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hecate/features/app/di/app_scope.dart';
import 'package:hecate/features/app/presentation/screens/app_scope_failed_screen.dart';
import 'package:hecate/features/app/presentation/widgets/app_wrapper.dart';
import 'package:l/l.dart';

void main() {
  l.capture<void>(
    () => runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        Future<void> createScopeAndRun() async {
          final appScopeHolder = AppScopeHolder();
          try {
            await appScopeHolder.create();
            runApp(
              AppWrapper(
                onDispose: () async => {
                  await appScopeHolder.drop(),
                },
                appScopeHolder: appScopeHolder,
              ),
            );
          } on Object catch (error, stackTrace) {
            runApp(
              AppScopeFailedScreen(
                error: error,
                stackTrace: stackTrace,
                onRetry: () async => createScopeAndRun(),
              ),
            );
          }
        }

        await createScopeAndRun();
      },
      l.e,
    ),
  );
}
