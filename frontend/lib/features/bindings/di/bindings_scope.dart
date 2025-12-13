import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:hecate/features/bindings/domain/bindings_interactor.dart';
import 'package:hecate/features/bindings/domain/bindings_state.dart';
import 'package:hecate/features/bindings/domain/bindings_state_manager.dart';
import 'package:piv_bindings/piv_bindings.dart';
import 'package:yx_scope/yx_scope.dart';
import 'package:yx_state/yx_state.dart';

abstract interface class BindingsScope {
  StateReadable<BindingsState> get stateReadable;

  BindingsInteractor get interactor;
}

abstract interface class BindingsParentScope extends ScopeContainer {}

final class BindingsScopeModule<
  ParentScopeContainer extends BindingsParentScope
>
    extends ScopeModule<ParentScopeContainer>
    implements BindingsScope {
  BindingsScopeModule(super.container);

  late final _libraryDep = dep<DynamicLibrary>(
    () => DynamicLibrary.open(
      const String.fromEnvironment('BINDINGS_DYLIB_NAME'),
    ),
  );

  late final _pivBindingsDep = dep<PivBindings>(
    () => PivBindings(
      library: _libraryDep.get,
    ),
  );

  late final stateManagerDep = asyncDep<BindingsStateManager>(
    () => BindingsStateManagerImpl(),
  );

  late final interactorDep = rawAsyncDep<BindingsInteractor>(
    () => BindingsInteractorImpl(
      bindings: _pivBindingsDep.get,
      stateManager: stateManagerDep.get,
    ),
    init: (dep) async {
      if (kDebugMode) {
        // due to hot restart, we need to close all sessions,
        // because flutter kill the main isolate without calling dispose,
        // therefore yubikey session is not closed after hot restart.
        _pivBindingsDep.get.closeAllDevices();
      }
      return dep.init();
    },
    dispose: (dep) async {
      return dep.dispose();
    },
  );

  @override
  StateReadable<BindingsState> get stateReadable => stateManagerDep.get;

  @override
  BindingsInteractor get interactor => interactorDep.get;
}
