import 'package:hecate/features/app/navigation/app_navigation_manager.dart';
import 'package:hecate/features/bindings/di/bindings_scope.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class AppScope implements Scope {
  BindingsScope get bindings;

  AppNavigationManager get navigationManager;
}

final class AppScopeContainer extends ScopeContainer implements AppScope {
  @override
  List<Set<AsyncDep<Object>>> get initializeQueue => [
    {
      navigationManagerDep,
      bindingsScopeHolderDep.get.stateManagerDep,
    },
    {
      bindingsScopeHolderDep.get.interactorDep,
    },
  ];

  late final bindingsScopeHolderDep = dep(
    () => BindingsScopeModule(this),
  );

  late final navigationManagerDep = asyncDep(
    () => AppNavigationManagerImpl(),
  );

  @override
  BindingsScope get bindings => bindingsScopeHolderDep.get;

  @override
  AppNavigationManager get navigationManager => navigationManagerDep.get;
}

final class AppScopeHolder
    extends BaseScopeHolder<AppScope, AppScopeContainer> {
  @override
  AppScopeContainer createContainer() => AppScopeContainer();
}
