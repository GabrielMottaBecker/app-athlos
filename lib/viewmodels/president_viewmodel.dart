import 'package:flutter/material.dart';
import '../core/theme/theme_notifier.dart';
import '../data/datasources/atletica_remote_datasource.dart';
import '../data/models/models.dart';

class PresidentOnboardingViewModel extends ChangeNotifier {
  final AtleticaRemoteDatasource _ds = AtleticaRemoteDatasource();

  int _step = 0;
  Color _primaryColor = const Color(0xFF2563EB);
  Color _backgroundColor = const Color(0xFFF8FAFC);
  String _atleticaName = '';
  String _presidentName = '';
  bool _isLoading = false;
  String? _error;

  int get step => _step;
  Color get primaryColor => _primaryColor;
  Color get backgroundColor => _backgroundColor;
  String get atleticaName => _atleticaName;
  String get presidentName => _presidentName;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get canGoNext => _step < 1;
  bool get canGoBack => _step > 0;

  void nextStep() {
    if (_atleticaName.trim().isEmpty || _presidentName.trim().isEmpty) {
      _error = 'Preencha o nome da atlética e do presidente.';
      notifyListeners();
      return;
    }
    _error = null;
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
    _error = null;
    notifyListeners();
  }

  void setPresidentName(String name) {
    _presidentName = name;
    _error = null;
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

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<AtleticaModel?> finish() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _ds.createAtletica(
        nome:           _atleticaName.trim(),
        nomePresidente: _presidentName.trim(),
        corPrimaria:    _colorToHex(_primaryColor),
        corFundo:       _colorToHex(_backgroundColor),
      );
      return AtleticaModel(
        id:                   data['id'] as String? ?? '',
        name:                 data['nome'] as String? ?? _atleticaName,
        presidentName:        data['nomePresidente'] as String? ?? _presidentName,
        primaryColorValue:    _primaryColor.toARGB32(),
        backgroundColorValue: _backgroundColor.toARGB32(),
      );
    } catch (e) {
      _error = 'Erro ao criar atlética. Tente novamente.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  AtleticaModel buildAtleticaModel() => AtleticaModel(
    id:                  '',  
    name:                 _atleticaName,
    presidentName:        _presidentName,
    primaryColorValue:    _primaryColor.toARGB32(),
    backgroundColorValue: _backgroundColor.toARGB32(),
  );
}