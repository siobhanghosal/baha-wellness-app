import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeController extends ChangeNotifier {
  static const _darkModeStorageKey = 'baha_ui_prototype_dark_mode';
  static const _colorThemeStorageKey = 'baha_ui_color_theme';

  ThemeController({SharedPreferences? preferences}) : this._(preferences);

  ThemeController._(this._preferences);

  SharedPreferences? _preferences;
  bool _isDark = false;
  AppColorTheme _colorTheme = AppColorTheme.growth;

  bool get isDark => _isDark;
  AppColorTheme get colorTheme => _colorTheme;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _isDark = _preferences?.getBool(_darkModeStorageKey) ?? false;
    _colorTheme = AppColorTheme.fromStorageKey(
      _preferences?.getString(_colorThemeStorageKey),
    );
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) {
      return;
    }
    _isDark = value;
    notifyListeners();
    await _preferences?.setBool(_darkModeStorageKey, value);
  }

  Future<void> toggle() => setDark(!_isDark);

  Future<void> setColorTheme(AppColorTheme value) async {
    if (_colorTheme == value) {
      return;
    }
    _colorTheme = value;
    notifyListeners();
    await _preferences?.setString(_colorThemeStorageKey, value.storageKey);
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope?.notifier;
  }

  static ThemeController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'ThemeScope was not found above this context.');
    return controller!;
  }
}
