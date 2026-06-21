import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../data/datasources/token_local_datasource.dart';
import '../core/network/dio_client.dart';

class PerfilViewModel extends ChangeNotifier {
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();
  final ImagePicker _picker = ImagePicker();

  String _nome = '';
  String _email = '';
  String _cargo = 'Membro';
  String _role = '';
  String? _fotoUrl;
  bool _isLoading = false;
  bool _isUploadingFoto = false;
  String? _uploadError;

  String get nome => _nome;
  String get email => _email;
  String get cargo => _cargo;
  String get role => _role;
  String? get fotoUrl => _fotoUrl;
  bool get isLoading => _isLoading;
  bool get isUploadingFoto => _isUploadingFoto;
  String? get uploadError => _uploadError;

  /// Admin e Super Admin enxergam a seção "Administração" no Perfil.
  /// Membro comum não tem acesso a Gestão de Associados.
  bool get isAdmin => _role == 'ADMINISTRADOR' || _role == 'SUPER_ADMIN';

  String get initials => _nome.trim().isEmpty
      ? '?'
      : _nome.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();

  PerfilViewModel();

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      _role            = await _tokenDs.getRole() ?? 'MEMBRO';

      // Busca os dados do próprio usuário autenticado.
      // Usa /usuarios/me (em vez de /usuarios/:id) porque membro comum não
      // tem a permissão administrativa USERS_READ — /me é self-service e
      // funciona para qualquer usuário logado, seja membro ou admin.
      final userResponse = await DioClient.identidade.get('/usuarios/me');
      _nome    = userResponse.data['nome'] as String? ?? '';
      _email   = userResponse.data['email'] as String? ?? '';
      _fotoUrl = userResponse.data['fotoUrl'] as String?;

      // Busca cargo do associado se tiver atleticaId
      if (atleticaId != null) {
        try {
          final assocResponse = await DioClient.associacao
              .get('/associados/atletica/$atleticaId');
          final List<dynamic> items = assocResponse.data is List
              ? assocResponse.data as List
              : (assocResponse.data['data'] ?? assocResponse.data['items'] ?? []) as List;

          final associado = items.firstWhere(
            (a) => a['email'] == _email,
            orElse: () => null,
          );
          if (associado != null) {
            _cargo = associado['cargo']?['nome'] as String? ?? _roleLabel(_role);
          } else {
            _cargo = _roleLabel(_role);
          }
        } catch (_) {
          _cargo = _roleLabel(_role);
        }
      } else {
        _cargo = _roleLabel(_role);
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Abre a galeria ou câmera, e já envia a foto escolhida para o backend.
  /// Atualiza [fotoUrl] com a URL pública devolvida pela API em caso de sucesso.
  Future<void> pickAndUploadFoto(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null) return;

    _isUploadingFoto = true;
    _uploadError = null;
    notifyListeners();

    try {
      final bytes = await picked.readAsBytes();
      final formData = FormData.fromMap({
        'foto': MultipartFile.fromBytes(
          bytes,
          filename: picked.name,
        ),
      });

      final response = await DioClient.identidade.post(
        '/usuarios/me/foto',
        data: formData,
      );

      _fotoUrl = response.data['fotoUrl'] as String?;
    } on DioException catch (e) {
      _uploadError = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? 'Não foi possível enviar a foto.')
          : 'Não foi possível enviar a foto. Verifique sua conexão.';
    } catch (_) {
      _uploadError = 'Não foi possível enviar a foto.';
    } finally {
      _isUploadingFoto = false;
      notifyListeners();
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMINISTRADOR': return 'Administrador';
      case 'SUPER_ADMIN':   return 'Super Admin';
      default:              return 'Membro';
    }
  }
}