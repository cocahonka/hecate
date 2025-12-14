import 'package:shared_preferences/shared_preferences.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class PrefsProvider implements AsyncLifecycle {
  SharedPreferences get prefs;
}

final class PrefsProviderImpl implements PrefsProvider {
  late SharedPreferences _prefs;

  @override
  SharedPreferences get prefs => _prefs;

  @override
  Future<void> init() async {
    SharedPreferences.setPrefix(
      const String.fromEnvironment('SHARED_PREFS_PREFIX'),
    );
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> dispose() async {}
}
