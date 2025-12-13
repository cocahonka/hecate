import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hecate/core/prefs_provider.dart';
import 'package:hecate/features/app/navigation/app_navigation_revalidator.dart';
import 'package:hecate/features/auth/data/api/auth_api.dart';
import 'package:hecate/features/auth/data/api/auth_api_paths.dart';
import 'package:hecate/features/auth/data/repository/auth_repository.dart';
import 'package:hecate/features/auth/data/storage/auth_storage.dart';
import 'package:hecate/features/auth/domain/auth_interactor.dart';
import 'package:hecate/features/auth/domain/auth_interceptor.dart';
import 'package:hecate/features/auth/domain/auth_observer.dart';
import 'package:hecate/features/auth/domain/auth_state.dart';
import 'package:hecate/features/auth/domain/auth_state_manager.dart';
import 'package:hecate/features/bindings/di/bindings_scope.dart';
import 'package:yx_scope/yx_scope.dart';
import 'package:yx_state/yx_state.dart';

abstract interface class AuthScope {
  StateReadable<AuthState> get stateReadable;

  AuthInteractor get interactor;
}

abstract interface class AuthParentScope extends ScopeContainer {
  Dio get dio;

  PrefsProvider get prefs;

  BindingsScope get bindings;

  AppNavigationRevalidator get navigationRevalidator;
}

final class AuthScopeModule<ParentScopeContainer extends AuthParentScope>
    extends ScopeModule<AuthParentScope>
    implements AuthScope {
  AuthScopeModule(super.container);

  late final _pathsDep = dep<AuthApiPaths>(
    () => AuthApiPathsImpl(),
  );

  late final _apiDep = dep<AuthApi>(
    () => AuthApiImpl(
      dio: container.dio,
      paths: _pathsDep.get,
    ),
  );

  late final _secureStorageDep = dep(
    () => FlutterSecureStorage(),
  );

  late final _storageDep = dep<AuthStorage>(
    () => AuthStorageImpl(
      secureStorage: _secureStorageDep.get,
      prefs: container.prefs.prefs,
    ),
  );

  late final _repositoryDep = dep<AuthRepository>(
    () => AuthRepositoryImpl(
      storage: _storageDep.get,
      api: _apiDep.get,
    ),
  );

  late final stateManagerDep = asyncDep<AuthStateManager>(
    () => AuthStateManagerImpl(),
  );

  late final interceptorDep = dep<AuthInterceptor>(
    () => AuthInterceptorImpl(
      dio: container.dio,
      repository: _repositoryDep.get,
      stateManager: stateManagerDep.get,
    ),
  );

  late final interactorDep = asyncDep<AuthInteractor>(
    () => AuthInteractorImpl(
      repository: _repositoryDep.get,
      stateManager: stateManagerDep.get,
      bindingsInteractor: container.bindings.interactor,
    ),
  );

  late final observerDep = asyncDep<AuthObserver>(
    () => AuthObserverImpl(
      authStateManager: stateManagerDep.get,
      dio: container.dio,
      refreshInterceptor: interceptorDep.get,
      navigationRevalidator: container.navigationRevalidator,
    ),
  );

  @override
  StateReadable<AuthState> get stateReadable => stateManagerDep.get;

  @override
  AuthInteractor get interactor => interactorDep.get;
}
