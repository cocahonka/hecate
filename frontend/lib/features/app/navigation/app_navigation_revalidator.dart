import 'package:flutter/foundation.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class AppNavigationRevalidator
    implements Listenable, AsyncLifecycle {
  void revalidate();
}

final class AppNavigationRevalidatorImpl
    with ChangeNotifier
    implements AppNavigationRevalidator {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  @override
  void revalidate() {
    notifyListeners();
  }
}
