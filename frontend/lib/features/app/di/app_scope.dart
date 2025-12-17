import 'package:dio/dio.dart';
import 'package:hecate/core/logger_interceptor.dart';
import 'package:hecate/core/prefs_provider.dart';
import 'package:hecate/features/app/navigation/di/navigation_scope.dart';
import 'package:hecate/features/auth/di/auth_scope.dart';
import 'package:hecate/features/bindings/di/bindings_scope.dart';
import 'package:hecate/features/chats/di/chats_scope.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class AppScope implements Scope {
  BindingsScope get bindings;

  AuthScope get auth;

  NavigationScope get navigation;

  Dio get dio;

  PrefsProvider get prefs;

  ChatsScopeHolder get chatsScopeHolder;
}

final class AppScopeContainer extends ScopeContainer
    implements
        AppScope,
        BindingsParentScope,
        AuthParentScope,
        NavigationParentScope {
  @override
  List<Set<AsyncDep<Object>>> get initializeQueue => [
    {
      navigationScopeHolderDep.get.revalidatorDep,
      bindingsScopeHolderDep.get.stateManagerDep,
      prefsDep,
      authScopeHolderDep.get.stateManagerDep,
    },
    {
      navigationScopeHolderDep.get.managerDep,
      bindingsScopeHolderDep.get.interactorDep,
    },
    {
      authScopeHolderDep.get.observerDep,
      authScopeHolderDep.get.interactorDep,
    },
  ];

  late final bindingsScopeHolderDep = dep(
    () => BindingsScopeModule(this),
  );

  late final authScopeHolderDep = dep(
    () => AuthScopeModule(this),
  );

  late final navigationScopeHolderDep = dep(
    () => NavigationScopeModule(this),
  );

  late final chatsScopeHolderDep = dep(
    () => ChatsScopeHolder(this),
  );

  late final dioDep = dep(
    () =>
        Dio(
            BaseOptions(
              baseUrl: const String.fromEnvironment('API_BASE_URL'),
            ),
          )
          ..interceptors.add(
            LoggerInterceptorImpl(),
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
  NavigationScope get navigation => navigationScopeHolderDep.get;

  @override
  Dio get dio => dioDep.get;

  @override
  PrefsProvider get prefs => prefsDep.get;

  @override
  ChatsScopeHolder get chatsScopeHolder => chatsScopeHolderDep.get;
}

final class AppScopeHolder
    extends BaseScopeHolder<AppScope, AppScopeContainer> {
  @override
  AppScopeContainer createContainer() => AppScopeContainer();
}
