import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../core/theme/theme_notifier.dart';

class PresidentOnboardingViewModel extends ChangeNotifier {
  int _step = 0;
  Color _primaryColor = const Color(0xFF2563EB);
  Color _backgroundColor = const Color(0xFFF8FAFC);
  String _atleticaName = '';
  String _presidentName = '';

  int get step => _step;
  Color get primaryColor => _primaryColor;
  Color get backgroundColor => _backgroundColor;
  String get atleticaName => _atleticaName;
  String get presidentName => _presidentName;

  bool get canGoNext => _step < 1;
  bool get canGoBack => _step > 0;

  void nextStep() {
    if (_step < 1) {
      _step++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (_step > 0) {
      _step--;
      notifyListeners();
    }
  }

  void setAtleticaName(String name) {
    _atleticaName = name;
    notifyListeners();
  }

  void setPresidentName(String name) {
    _presidentName = name;
    notifyListeners();
  }

  void setPrimaryColor(Color color, ThemeNotifier themeNotifier) {
    _primaryColor = color;
    themeNotifier.setPrimaryColor(color);
    notifyListeners();
  }

  void setBackgroundColor(Color color, ThemeNotifier themeNotifier) {
    _backgroundColor = color;
    themeNotifier.setBackgroundColor(color);
    notifyListeners();
  }

  AtleticaModel buildAtleticaModel() => AtleticaModel(
    name: _atleticaName,
    presidentName: _presidentName,
    primaryColorValue: _primaryColor.toARGB32(),
    backgroundColorValue: _backgroundColor.toARGB32(),
  );
}
