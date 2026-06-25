import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _storageKey = 'baha_ui_prototype_dark_mode';

  ThemeController({SharedPreferences? preferences})
      : _preferences = preferences;

  SharedPreferences? _preferences;
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _isDark = _preferences?.getBool(_storageKey) ?? false;
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    await _preferences?.setBool(_storageKey, value);
  }

  Future<void> toggle() => setDark(!_isDark);
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope(
      {super.key, required ThemeController controller, required super.child})
      : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope was not found above this context.');
    return scope!.notifier!;
  }
}
