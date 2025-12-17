import 'package:meta/meta.dart';
import 'package:yx_scope/yx_scope.dart';
import 'package:yx_state/yx_state.dart';

base class BaseStateManager<State> extends StateManager<State>
    implements AsyncLifecycle {
  BaseStateManager(super.state);

  @override
  @mustCallSuper
  Future<void> init() async {}

  @override
  @mustCallSuper
  Future<void> dispose() => close();
}
