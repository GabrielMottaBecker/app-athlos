import 'dart:convert';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// ─── Handler de background (obrigatoriamente top-level) ──────────────────────
// Chamado pelo FCM quando uma mensagem chega com o app fechado/em background.
// Deve ser registrado ANTES de qualquer outra inicialização do Firebase.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(fcm.RemoteMessage message) async {
  await firebase_core.Firebase.initializeApp();
  // O FCM exibe a notificação automaticamente em background no Android.
  // Adicione aqui qualquer lógica offline necessária (ex.: salvar em SharedPrefs).
  debugPrint('[FCM Background] ${message.notification?.title}');
}

/// Serviço central de notificações push do Athlos.
///
/// Usa Firebase Cloud Messaging com a estratégia de **Topics**:
/// - Todo dispositivo assina o tópico [_topicEventos] ao inicializar.
/// - Quando o admin cria um evento, este serviço envia uma mensagem
///   diretamente para o tópico via HTTP Legacy API.
///
/// IMPORTANTE: substitua [_serverKey] pela Server Key do seu projeto
/// no Firebase Console → Configurações do projeto → Cloud Messaging.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // ─── Configuração ─────────────────────────────────────────────────────────

  /// Server Key (Legacy) — Firebase Console > Configurações > Cloud Messaging
  /// Mantenha essa chave fora do controle de versão em produção (use --dart-define).
  static const String _serverKey = 'SUA_SERVER_KEY_AQUI';

  /// Tópico que todos os membros assinam para receber notificações de eventos.
  static const String _topicEventos = 'eventos';

  static const String _fcmUrl =
      'https://fcm.googleapis.com/fcm/send';

  // ─── Dependências ─────────────────────────────────────────────────────────

  final fcm.FirebaseMessaging _messaging = fcm.FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Canal Android ────────────────────────────────────────────────────────

  static const _channel = AndroidNotificationChannel(
    'events_channel',
    'Eventos da Agenda',
    description: 'Notificações sobre novos eventos cadastrados na agenda.',
    importance: Importance.high,
  );

  // ─── Inicialização ────────────────────────────────────────────────────────

  /// Deve ser chamado uma única vez em [main()], após [Firebase.initializeApp()].
  ///
  /// [onNotificationTap] é chamado quando o usuário toca em uma notificação
  /// enquanto o app está em foreground ou volta do background.
  Future<void> init({
    void Function(fcm.RemoteMessage message)? onNotificationTap,
  }) async {
    if (_initialized) return;

    // 1. Registrar handler de background (deve ser top-level)
    fcm.FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // 2. Solicitar permissão (obrigatório no iOS e Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Status de permissão: ${settings.authorizationStatus}');

    // 3. Criar canal Android (necessário para Android 8+)
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Inicializar flutter_local_notifications para exibição em foreground
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // 5. Exibir notificação local quando o app está em foreground
    fcm.FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM Foreground] ${message.notification?.title}');
      _exibirNotificacaoLocal(message);
    });

    // 6. App voltou do background via toque na notificação
    fcm.FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM Tap] ${message.notification?.title}');
      onNotificationTap?.call(message);
    });

    // 7. App foi aberto a partir de uma notificação (estava encerrado)
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      onNotificationTap?.call(initial);
    }

    // 8. Assinar o tópico de eventos — todos os membros recebem as notificações
    await assinarTopicEventos();

    _initialized = true;
    debugPrint('[FCM] Inicializado e inscrito no tópico "$_topicEventos"');
  }

  // ─── Tópico ───────────────────────────────────────────────────────────────

  /// Assina o tópico de eventos. Chamado automaticamente no [init].
  /// Pode ser chamado novamente se necessário (ex.: após logout/login).
  Future<void> assinarTopicEventos() async {
    await _messaging.subscribeToTopic(_topicEventos);
    debugPrint('[FCM] Inscrito no tópico "$_topicEventos"');
  }

  /// Cancela a assinatura do tópico (ex.: ao desativar notificações nas configurações).
  Future<void> cancelarAssinaturaEventos() async {
    await _messaging.unsubscribeFromTopic(_topicEventos);
    debugPrint('[FCM] Desinscrito do tópico "$_topicEventos"');
  }

  // ─── Envio de notificação ─────────────────────────────────────────────────

  /// Envia uma notificação push para todos os dispositivos inscritos no tópico
  /// [_topicEventos] quando um novo evento é criado.
  ///
  /// Esta chamada é feita pelo **app do admin** diretamente via HTTP.
  /// Quando a API NestJS estiver pronta, mova esta lógica para o backend —
  /// o Flutter só precisará chamar o endpoint da API.
  ///
  /// Parâmetros:
  /// - [titulo]: nome do evento (ex.: "TREINO DE FUTEBOL")
  /// - [data]: data formatada (ex.: "JUN 14")
  /// - [local]: local do evento (ex.: "Campo de Treinamento Alpha")
  /// - [tipo]: tipo do evento para incluir nos dados (ex.: "TREINO")
  Future<void> notificarNovoEvento({
    required String titulo,
    required String data,
    required String local,
    required String tipo,
  }) async {
    // Não envia notificação se o servidor não foi configurado
    if (_serverKey == 'SUA_SERVER_KEY_AQUI') {
      debugPrint('[FCM] ⚠️  Server Key não configurada. Substitua em notification_service.dart');
      return;
    }

    try {
      final body = jsonEncode({
        'to': '/topics/$_topicEventos',
        'notification': {
          'title': '📅 Novo evento: $titulo',
          'body': '$data • $local',
          'sound': 'default',
        },
        'data': {
          'tipo': tipo,
          'titulo': titulo,
          'data': data,
          'local': local,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        // Garante entrega mesmo com o app em background no Android
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'events_channel',
            'notification_priority': 'PRIORITY_HIGH',
            'sound': 'default',
          },
        },
        // Exibe em foreground no iOS
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
              'content-available': 1,
            },
          },
        },
      });

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] ✅ Notificação enviada para o tópico "$_topicEventos"');
      } else {
        debugPrint('[FCM] ❌ Erro ao enviar: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Exceção ao enviar notificação: $e');
    }
  }

  // ─── Notificação local (foreground) ──────────────────────────────────────

  Future<void> _exibirNotificacaoLocal(fcm.RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}