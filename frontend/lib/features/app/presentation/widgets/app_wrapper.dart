import 'package:flutter/material.dart';
import 'package:hecate/features/app/di/app_scope.dart';
import 'package:hecate/features/app/navigation/app_navigator.dart';
import 'package:hecate/features/app/presentation/widgets/bindings_state_banner.dart';
import 'package:yx_scope_flutter/yx_scope_flutter.dart';

class AppWrapper extends StatefulWidget {
  final AppScopeHolder appScopeHolder;
  final VoidCallback onDispose;

  AppWrapper({
    required this.appScopeHolder,
    required this.onDispose,
    super.key,
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopeProvider<AppScope>(
      holder: widget.appScopeHolder,
      child: ScopeBuilder<AppScope>.withPlaceholder(
        builder: (context, scope) {
          return MaterialApp(
            home: Stack(
              children: [
                AppNavigator.controlled(
                  controller: scope.navigationManager.controller,
                  guards: scope.navigationManager.guards,
                  observers: scope.navigationManager.observers,
                  revalidate: scope.navigationManager.revalidate,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    child: BindingStateBanner(
                      stateReadable: scope.bindings.stateReadable,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
