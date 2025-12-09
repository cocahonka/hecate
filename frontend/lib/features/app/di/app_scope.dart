import 'package:dio/dio.dart';
import 'package:hecate/core/prefs_provider.dart';
import 'package:hecate/features/app/navigation/app_navigation_manager.dart';
import 'package:hecate/features/auth/di/auth_scope.dart';
import 'package:hecate/features/bindings/di/bindings_scope.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class AppScope implements Scope {
  BindingsScope get bindings;

  AuthScope get auth;

  AppNavigationManager get navigationManager;

  Dio get dio;

  PrefsProvider get prefs;
}

final class AppScopeContainer extends ScopeContainer
    implements AppScope, AuthParentScope {
  @override
  List<Set<AsyncDep<Object>>> get initializeQueue => [
    {
      navigationManagerDep,
      bindingsScopeHolderDep.get.stateManagerDep,
      prefsDep,
      authScopeHolderDep.get.stateManagerDep,
    },
    {
      bindingsScopeHolderDep.get.interactorDep,
    },
    {
      authScopeHolderDep.get.interactorDep,
    },
  ];

  late final bindingsScopeHolderDep = dep(
    () => BindingsScopeModule(this),
  );

  late final authScopeHolderDep = dep(
    () => AuthScopeModule(this),
  );

  late final navigationManagerDep = asyncDep(
    () => AppNavigationManagerImpl(),
  );

  late final dioDep = dep(
    () => Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment('API_BASE_URL'),
      ),
    ),
  );

  late final prefsDep = asyncDep<PrefsProvider>(
    () => PrefsProviderImpl(),
  );

  @override
  BindingsScope get bindings => bindingsScopeHolderDep.get;

  @override
  AuthScope get auth => authScopeHolderDep.get;

  @override
  AppNavigationManager get navigationManager => navigationManagerDep.get;

  @override
  Dio get dio => dioDep.get;

  @override
  PrefsProvider get prefs => prefsDep.get;
}

final class AppScopeHolder
    extends BaseScopeHolder<AppScope, AppScopeContainer> {
  @override
  AppScopeContainer createContainer() => AppScopeContainer();
}
