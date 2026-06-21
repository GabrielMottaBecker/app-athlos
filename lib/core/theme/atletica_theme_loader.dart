import 'theme_notifier.dart';
import '../../data/datasources/atletica_remote_datasource.dart';
import '../../data/datasources/token_local_datasource.dart';

Future<void> loadAtleticaTheme(ThemeNotifier themeNotifier) async {
  final atleticaId = await TokenLocalDatasource().getAtleticaId();

  if (atleticaId == null) {
    themeNotifier.resetToDefault();
    return;
  }

  try {
    final data = await AtleticaRemoteDatasource().getAtletica(atleticaId);
    themeNotifier.applyHexColors(
      primaryHex: data['corPrimaria'] as String?,
      backgroundHex: data['corFundo'] as String?,
    );
    themeNotifier.setIdentidade(
      nome: data['nome'] as String?,
      logoUrl: data['logoUrl'] as String?,
    );
  } catch (_) {
    themeNotifier.resetToDefault();
  }
}