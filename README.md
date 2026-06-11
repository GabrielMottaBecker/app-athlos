# Athlos — App Flutter

Plataforma mobile para gerenciamento de Atléticas Universitárias.

## Stack

- **Flutter 3** + Dart SDK `>=3.0.0 <4.0.0`
- **Provider** — gerenciamento de estado (MVVM)
- **Dio** — cliente HTTP com interceptor de autenticação automática
- **flutter_secure_storage** — armazenamento seguro de tokens JWT
- **Google Fonts** — tipografia
- **fl_chart** — gráficos e dashboards financeiros
- Arquitetura: **MVVM + Clean Architecture** (Domain / Data / Views / ViewModels)

---

## Pré-requisitos

- Flutter `>=3.x` instalado e no PATH
- Dart SDK `>=3.0.0 <4.0.0`
- Backend Athlos rodando localmente (ver [app-athlos-backend](../app-athlos-backend))

---

## Instalação e execução

```bash
# 1. Clone / extraia o projeto
cd app-athlos

# 2. Instale as dependências
flutter pub get

# 3. Suba o backend antes de rodar o app (requer Docker)
# Veja o README do backend para detalhes

# 4. Execute o app
flutter run
```

> **Emulador Android**: certifique-se de usar `10.0.2.2` no lugar de `localhost`
> ao apontar para as APIs locais. Edite `lib/core/network/dio_client.dart` conforme necessário.

---

## Configuração de APIs

O cliente HTTP (`DioClient`) aponta por padrão para os microsserviços rodando localmente:

| Serviço | Base URL padrão |
|---------|----------------|
| Identidade (auth) | `http://localhost:4002/v1` |
| Associação | `http://localhost:4001/v1` |
| Feed | `http://localhost:4003/v1` |
| Financeiro | `http://localhost:4004/v1` |
| Lojinha | `http://localhost:4005/v1` |
| Notificações | `http://localhost:4006/v1` |

Para alterar as URLs, edite `lib/core/network/dio_client.dart`.

---

## Autenticação

O app consome o serviço `identidade` (porta 4002) para login e renovação de tokens.

- O `accessToken` e o `refreshToken` são armazenados com segurança via `flutter_secure_storage`.
- O `AuthInterceptor` injeta automaticamente o `Authorization: Bearer <token>` em todas as requisições autenticadas.
- Em caso de resposta `401`, o interceptor tenta renovar o token silenciosamente via `/v1/auth/refresh`. Em caso de falha, os tokens são limpos e o usuário é redirecionado ao login.

**Fluxo de login:**

```
POST /v1/auth/login
{ "email": "admin@atletica.com", "senha": "password" }
```

---

## Funcionalidades

### Onboarding do Presidente
Cadastro da atlética na primeira utilização, com configuração de nome, nome do presidente e paleta de cores personalizada.

### Autenticação
Tela de login com validação de credenciais e splash screen de verificação de sessão ativa.

### Feed
Listagem de posts e eventos publicados pela atlética, com suporte a imagens e categorização por tipo (`TREINO`, `EVENTO`, `EXTRA`).

### Agenda
Visualização dos próximos eventos e treinos, com confirmação de presença.

### Associados
Gerenciamento de membros da atlética: cadastro, edição, controle de status (ativo / inativo) e atribuição de cargos.

### Loja
Catálogo de produtos da atlética com controle de estoque e geração de link de pedido via WhatsApp.

### Financeiro *(integração planejada)*
Dashboard com gráficos de transações e categorias financeiras. Módulo backend já disponível.

### Painel Administrativo
Shell com navegação unificada para acesso às funcionalidades de gestão: cadastro de eventos, posts, membros e produtos.

---

## Estrutura do Projeto

```
lib/
├── core/
│   ├── errors/
│   │   └── failures.dart              # Classes de falha tipadas
│   ├── network/
│   │   ├── auth_interceptor.dart      # Interceptor JWT + refresh automático
│   │   └── dio_client.dart            # Instâncias Dio por microsserviço
│   └── theme/
│       └── theme_notifier.dart        # Tema dinâmico com paleta personalizável
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart
│   │   └── token_local_datasource.dart
│   ├── models/
│   │   ├── auth_model.dart
│   │   └── models.dart                # PostModel, ProductModel, etc.
│   └── repositories/
│       ├── auth_repository_impl.dart
│       └── repositories.dart
├── domain/
│   ├── entities/
│   │   └── auth_entity.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── login_usecase.dart
│       ├── logout_usecase.dart
│       └── refresh_token_usecase.dart
├── viewmodels/
│   ├── auth_viewmodel.dart
│   ├── feed_viewmodel.dart
│   ├── agenda_viewmodel.dart
│   ├── loja_viewmodel.dart
│   ├── members_viewmodel.dart
│   └── president_viewmodel.dart
├── views/
│   ├── auth/
│   │   ├── login_view.dart
│   │   └── splash_view.dart
│   ├── admin/
│   │   ├── admin_shell_view.dart
│   │   ├── register_event_view.dart
│   │   ├── register_member_view.dart
│   │   ├── register_post_view.dart
│   │   └── register_product_view.dart
│   ├── president/
│   │   └── president_onboarding_view.dart
│   ├── user/
│   │   └── user_main_view.dart
│   └── shared/
│       └── widgets/
│           └── widgets.dart           # Componentes reutilizáveis
└── main.dart
```

---

## Temas e Personalização

O app suporta temas dinâmicos configurados por atlética. O `ThemeNotifier` (Provider) expõe:

- **Cor primária** — 8 opções (Azul, Roxo, Rosa, Vermelho, Laranja, Verde, Teal, Índigo)
- **Cor de fundo** — 8 opções, incluindo modos escuros (Escuro, Grafite)
- Alternância automática entre modo claro e escuro com base na luminância da cor de fundo escolhida

As cores são definidas no onboarding do presidente e aplicadas globalmente via `ThemeData`.

---

## Dependências principais

| Pacote | Versão | Uso |
|--------|--------|-----|
| `provider` | `^6.1.2` | Gerenciamento de estado (MVVM) |
| `dio` | `^5.9.2` | Cliente HTTP |
| `flutter_secure_storage` | `^10.2.0` | Armazenamento seguro de tokens |
| `google_fonts` | `^6.1.0` | Tipografia |
| `fl_chart` | `^0.66.2` | Gráficos financeiros |
| `url_launcher` | `^6.3.0` | Links externos (WhatsApp, etc.) |
| `image_picker` | `^1.1.2` | Upload de imagens |

---

## Microsserviços consumidos

Este app consome exclusivamente o backend **app-athlos-backend**. O serviço legado `user-auth` (porta 4007) **não é utilizado** pelo app.

Para subir o backend completo, consulte o [README do backend](../app-athlos-backend/README.md).

---

## Comandos úteis

```bash
# Checar dependências e versões
flutter pub deps

# Build Android (APK debug)
flutter build apk --debug

# Build iOS (requer macOS e Xcode)
flutter build ios --debug

# Rodar testes
flutter test

# Analisar código
flutter analyze
```
