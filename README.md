# Athlos — App Flutter

Plataforma mobile multi-tenant para gerenciamento de Atléticas Universitárias.

## Stack

- **Flutter 3** + Dart SDK `>=3.0.0 <4.0.0`
- **Provider** — gerenciamento de estado (MVVM)
- **Dio** — cliente HTTP com interceptor de autenticação automática
- **flutter_secure_storage** — armazenamento seguro de tokens JWT
- **shared_preferences** — cache local de conteúdo (Feed) e carrinho da Loja
- **Google Fonts** — tipografia
- **fl_chart** — gráficos e dashboards financeiros
- **image_picker** — seleção de imagens (posts, produtos, foto de perfil)
- **url_launcher** / **share_plus** — links externos e compartilhamento (WhatsApp, etc.)
- Arquitetura: **MVVM + Clean Architecture** (Domain / Data / ViewModels / Views)

---

## Pré-requisitos

- Flutter `>=3.x` instalado e no PATH
- Dart SDK `>=3.0.0 <4.0.0`
- Backend Athlos rodando localmente (ver [app-athlos-backend](https://github.com/GabrielMottaBecker/app-athlos-backend))

---

## Instalação e execução

```bash
# 1. Clone o projeto
git clone https://github.com/GabrielMottaBecker/app-athlos.git
cd app-athlos

# 2. Instale as dependências
flutter pub get

# 3. Suba o backend antes de rodar o app (requer Docker)
# Veja o README do app-athlos-backend para detalhes

# 4. Execute o app
flutter run
```

> **Emulador Android**: use `10.0.2.2` no lugar de `localhost` ao apontar para as APIs locais. Edite `lib/core/network/dio_client.dart` conforme necessário.

---

## Configuração de APIs

O cliente HTTP (`DioClient`) aponta por padrão para os microsserviços rodando localmente:

| Serviço           | Base URL padrão            |
| ------------------ | --------------------------- |
| Identidade (auth)  | `http://localhost:4002/v1` |
| Associação         | `http://localhost:4001/v1` |
| Feed               | `http://localhost:4003/v1` |
| Financeiro         | `http://localhost:4004/v1` |
| Lojinha            | `http://localhost:4005/v1` |
| Notificações       | `http://localhost:4006/v1` |

Para alterar as URLs (ex.: apontar para um servidor remoto), edite `lib/core/network/dio_client.dart`.

> O serviço legado `user-auth` (porta 4007) **não é consumido** pelo app.

---

## Arquitetura

O projeto segue **MVVM + Clean Architecture**, organizado em camadas dentro de `lib/`:

```
View  ──(watch/read)──▶  ViewModel  ──▶  UseCase  ──▶  Repository  ──▶  Datasource  ──▶  API/Storage
 ▲                          │
 └──────── notifyListeners() ┘
```

- **`domain/`** — regras de negócio puras: `entities`, contratos de `repositories` e `usecases` (ex.: `LoginUseCase`). Não conhece Dio, SharedPreferences ou qualquer detalhe de infraestrutura.
- **`data/`** — implementação concreta: `datasources` (chamadas HTTP via Dio, leitura/escrita local), `models` (parsing JSON ↔ objeto Dart) e `repositories` (implementações dos contratos do domínio).
- **`viewmodels/`** — classes `ChangeNotifier` que orquestram chamadas aos datasources/repositories, mantêm estado de UI (`isLoading`, `error`, listas) e notificam as Views.
- **`views/`** — widgets que apenas leem o estado via `Provider`/`context.watch` e disparam ações via `context.read<X>().metodo()`. Não contêm lógica de negócio.

Padrões adicionais aplicados:

- **Singleton** — `TokenLocalDatasource` e `DioClient`, garantindo uma única fonte de verdade para sessão e reaproveitamento das instâncias HTTP por microsserviço.
- **Observer** — todos os ViewModels e o `ThemeNotifier` via `ChangeNotifier`/`Provider`, permitindo que a UI reaja automaticamente a mudanças de estado.

Mais detalhes de arquitetura e decisões de projeto estão em [`RelatorioTecnico.md`](./RelatorioTecnico.md).

---

## Fluxo de autenticação e onboarding

```
SplashView
  │
  ├─ sem sessão válida ──▶ LoginView
  │                           │
  │                           ├─ login normal (e-mail + senha)
  │                           │     └─▶ navega por role (ver abaixo)
  │                           │
  │                           └─ "Primeiro acesso" ──▶ ConfirmarAssociadoView
  │                                 (confirma e-mail + telefone        │
  │                                  cadastrados pelo presidente)      ▼
  │                                                          DefinirSenhaView
  │                                                          (define senha e ativa a conta)
  │
  └─ sessão válida ──▶ navega direto por role
```

- **`SplashView`** — verifica token local (`TokenLocalDatasource`) e, se válido, carrega o tema da atlética (`atletica_theme_loader.dart`) antes de redirecionar.
- **`LoginView`** — login padrão. Sempre reseta o tema para o padrão (azul/branco) ao abrir, independente da última atlética logada.
- **`ConfirmarAssociadoView`** → **`DefinirSenhaView`** — fluxo de ativação de conta para membros cadastrados pelo presidente/admin: confirma identidade via e-mail + telefone (`POST /auth/verificar-associado`), recebe um token de sessão válido por 10 minutos e define a senha definitiva (`POST /auth/definir-senha`), que já efetua o login.

### Navegação por role

O `role` é extraído do payload do JWT (`AuthModel.fromJson`) e determina a tela inicial:

| Role            | Tela                     |
| --------------- | ------------------------- |
| `SUPER_ADMIN`   | `SuperAdminShellView`     |
| `ADMINISTRADOR` | `AdminShellView`          |
| `MEMBRO`        | `UserMainView`            |

- O `accessToken` e o `refreshToken` são armazenados com segurança via `flutter_secure_storage`, com expiração local de 24h.
- O `AuthInterceptor` injeta automaticamente `Authorization: Bearer <token>` em todas as requisições autenticadas e tenta renovar silenciosamente o token via `/v1/auth/refresh` em caso de `401`; se a renovação falhar, os tokens são limpos e o usuário volta para o login.

**Login:**
```json
POST /v1/auth/login
{ "email": "admin@atletica.com", "senha": "password" }
```

---

## Funcionalidades por perfil

### Membro (`UserMainView`)

Navegação por abas: **Início (Feed)**, **Loja**, **Agenda**, **Membros**, **Perfil**.

- **Feed** — posts/avisos da atlética por categoria (`PRESIDÊNCIA`, `TREINO`, `COMPETIÇÃO`, `AVISO`, `EVENTO`, `EXTRA`), com curtidas, comentários e compartilhamento **locais à sessão** (não persistem no backend). Suporta cache offline (ver seção abaixo).
- **Loja** — catálogo de produtos com filtro por categoria, carrinho persistido localmente (`shared_preferences`) e geração de link de pedido via WhatsApp.
- **Agenda** — eventos/treinos da atlética, com filtro por tipo (Treinos, Eventos, Extras) e confirmação/cancelamento de presença.
- **Membros (Participantes)** — listagem e busca de associados da atlética.
- **Perfil** — dados do usuário autenticado, upload de foto de perfil, e (para Admin/Super Admin) acesso rápido às telas de administração.
- **Notificações** — sino no app bar com contagem de não lidas, marcação individual ou em massa como lida.

### Administrador (`AdminShellView`)

Navegação por abas: **Loja**, **Feed**, **Membros**.

- **Loja** — CRUD de produtos (nome, preço, categoria, imagem, estoque, status: `DISPONIVEL` / `ESGOTADO` / `INATIVO`).
- **Feed** — CRUD de posts e eventos unificados em uma única tela administrativa, com menu de criação (`_openCreateMenu`) para escolher entre post (aviso) ou evento/treino; inclui visualização e gestão de presença confirmada por evento (`_PresenceListSheet`).
- **Membros** — CRUD de associados: cadastro, edição, atribuição de cargo e ativação/inativação.
- **Configurações da Atlética** (`atletica_settings_view.dart`) — edição de nome, nome do presidente e paleta de cores (primária/fundo) da atlética.

### Super Admin (`SuperAdminShellView`)

Tela exclusiva da Athlos (não vinculada a nenhuma atlética):

- Listagem de todas as atléticas cadastradas na plataforma, com detalhe individual.
- Cadastro de novas atléticas (`RegisterAtleticaView`).
- Edição (`EditAtleticaView`) e ativação/inativação/exclusão de atléticas.

### Onboarding do Presidente (`PresidentOnboardingView`)

Fluxo de criação de uma nova atlética: nome da atlética, nome do presidente e escolha de paleta de cores (primária e fundo), com pré-visualização em tempo real (`_MiniPreview`) antes de confirmar (`AtleticaCreatedView`).

### Financeiro *(integração planejada)*

Módulo já disponível no backend (categorias e transações); a tela correspondente no app ainda não foi implementada nesta entrega.

---

## Persistência local

Duas camadas de armazenamento local, cada uma adequada ao tipo de dado:

| Tecnologia | Uso | Por quê |
| --- | --- | --- |
| `flutter_secure_storage` | Sessão: `accessToken`, `refreshToken`, `role`, `userId`, `atleticaId`, validade (24h) | Armazenamento criptografado (Keystore/Keychain), adequado para dados sensíveis como JWT |
| `shared_preferences` | Cache de conteúdo do Feed (`FeedLocalDatasource`) e itens do carrinho da Loja | Leve e suficiente para dados não sensíveis que precisam sobreviver entre aberturas do app |

**Sessão** — recuperada automaticamente pela `SplashView` para manter o usuário logado entre aberturas do app, sem necessidade de novo login.

**Cache do Feed** — a lista de posts retornada pela API é salva por `atleticaId` junto com o timestamp da última sincronização:

1. Ao abrir o Feed, o cache local é exibido imediatamente.
2. Em paralelo, o app sincroniza com a API.
3. Em caso de sucesso, a tela é atualizada e o cache é regravado.
4. Em caso de falha de rede, o conteúdo em cache permanece visível, com indicador de "dados salvos localmente" e o horário da última sincronização — em vez de uma tela vazia ou erro bloqueante.

---

## Estrutura do projeto

```
lib/
├── core/
│   ├── errors/
│   │   └── failures.dart                  # Classes de falha tipadas (ServerFailure, UnauthorizedFailure, NetworkFailure)
│   ├── network/
│   │   ├── auth_interceptor.dart          # Interceptor JWT + refresh automático em 401
│   │   └── dio_client.dart                # Instâncias Dio singleton por microsserviço
│   └── theme/
│       ├── theme_notifier.dart            # ChangeNotifier de tema dinâmico + paletas + ThemeExtension
│       └── atletica_theme_loader.dart     # Carrega e aplica as cores/identidade da atlética do usuário logado
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart        # Login, refresh, logout, verificar-associado, definir-senha
│   │   ├── atletica_remote_datasource.dart    # CRUD de atléticas (Identidade)
│   │   ├── feed_remote_datasource.dart        # Posts, eventos, presenças (Feed)
│   │   ├── feed_local_datasource.dart         # Cache local dos posts do Feed (shared_preferences)
│   │   ├── loja_remote_datasource.dart        # Produtos e link de carrinho WhatsApp (Lojinha)
│   │   ├── members_remote_datasource.dart     # Associados e cargos (Associação)
│   │   ├── notificacoes_remote_datasource.dart# Inbox e contagem de não lidas (Notificações)
│   │   └── token_local_datasource.dart        # Singleton de sessão (flutter_secure_storage)
│   ├── models/
│   │   ├── auth_model.dart                # Decodifica o JWT e deriva role/atleticaId
│   │   └── models.dart                    # PostModel, EventModel, EventPresenceModel, ProductModel, MemberModel, AtleticaModel, AgendaItemModel, CommentModel
│   └── repositories/
│       ├── auth_repository_impl.dart      # Implementação do contrato de domínio de auth
│       └── repositories.dart              # Repositórios em memória usados como fallback/mock (Feed, Product, Event, Member, Agenda)
├── domain/
│   ├── entities/
│   │   └── auth_entity.dart               # Entidade pura de autenticação
│   ├── repositories/
│   │   └── auth_repository.dart           # Contrato abstrato de autenticação
│   └── usecases/
│       ├── login_usecase.dart
│       ├── logout_usecase.dart
│       └── refresh_token_usecase.dart
├── viewmodels/
│   ├── auth_viewmodel.dart                # AuthViewModel (login) + AtivacaoContaViewModel (primeiro acesso)
│   ├── feed_viewmodel.dart                # Feed do membro: filtros, cache, likes/comentários locais
│   ├── agenda_viewmodel.dart              # Agenda do membro: filtros e confirmação de presença
│   ├── loja_viewmodel.dart                # Catálogo, carrinho (persistido) e CartItem
│   ├── members_viewmodel.dart             # Participantes (membro) + gestão de associados (admin)
│   ├── notificacoes_viewmodel.dart        # Inbox de notificações e contagem de não lidas
│   ├── perfil_viewmodel.dart              # Dados do usuário logado e upload de foto
│   ├── president_viewmodel.dart           # Onboarding de criação de atlética
│   ├── atletica_settings_viewmodel.dart   # Edição de nome/cores da atlética (admin)
│   ├── super_admin_viewmodel.dart         # Listagem e gestão de atléticas (super admin)
│   └── viewmodels.dart                    # Barrel file (exports)
└── views/
    ├── auth/
    │   ├── splash_view.dart               # Verificação de sessão + roteamento por role
    │   ├── login_view.dart                # Tela de login
    │   ├── confirmar_associado_view.dart  # Primeiro acesso — etapa 1 (e-mail + telefone)
    │   └── definir_senha_view.dart        # Primeiro acesso — etapa 2 (nova senha)
    ├── admin/
    │   ├── admin_shell_view.dart          # Shell com abas Loja / Feed / Membros (CRUD completo)
    │   ├── atletica_settings_view.dart    # Configurações da atlética
    │   ├── register_event_view.dart       # Form de criação/edição de evento ou treino
    │   ├── register_post_view.dart        # Form de criação/edição de post/aviso
    │   ├── register_member_view.dart      # Form de cadastro/edição de associado
    │   └── register_product_view.dart     # Form de cadastro/edição de produto
    ├── superadmin/
    │   └── super_admin_shell_view.dart    # Listagem, cadastro, edição e detalhe de atléticas
    ├── president/
    │   └── president_onboarding_view.dart # Wizard de criação de atlética + tela de sucesso
    ├── user/
    │   └── user_main_view.dart            # Shell do membro: Feed, Loja, Agenda, Participantes, Perfil
    └── shared/
        └── widgets/
            └── widgets.dart               # AthlosAvatar, AthlosAppBar, StatusBadge, AthlosCard, FilterChipRow, SectionHeader, AthlosTextField, ColorPickerSection
└── main.dart                              # Bootstrap: ChangeNotifierProvider<ThemeNotifier> + MaterialApp
```

---

## Temas e personalização

O app suporta temas dinâmicos por atlética via `ThemeNotifier` (Provider), aplicados globalmente através de um `ThemeExtension` (`AthlosThemeExtension`, acessível com `context.athlos`):

- **Cor primária** — 8 opções (Azul, Roxo, Rosa, Vermelho, Laranja, Verde, Teal, Índigo)
- **Cor de fundo** — 8 opções, incluindo modos escuros (Escuro, Grafite)
- Alternância automática entre modo claro e escuro com base na luminância da cor de fundo escolhida
- Identidade visual (nome da atlética + logo) carregada junto com as cores via `atletica_theme_loader.dart`
- Super Admin e telas sem atlética vinculada sempre usam o tema padrão (`resetToDefault()`)

As cores são definidas no onboarding do presidente ou nas Configurações da Atlética, e persistidas no backend (`identidade`).

---

## Dependências principais

| Pacote                   | Versão    | Uso                              |
| ------------------------ | --------- | --------------------------------- |
| `provider`               | `^6.1.2`  | Gerenciamento de estado (MVVM)    |
| `dio`                    | `^5.9.2`  | Cliente HTTP                      |
| `flutter_secure_storage` | `^10.2.0` | Armazenamento seguro de tokens    |
| `shared_preferences`     | `^2.3.2`  | Cache local (Feed) e carrinho     |
| `google_fonts`           | `^6.1.0`  | Tipografia                        |
| `fl_chart`               | `^0.66.2` | Gráficos financeiros              |
| `url_launcher`           | `^6.3.0`  | Links externos (WhatsApp, etc.)   |
| `share_plus`             | `^7.2.2`  | Compartilhamento de conteúdo      |
| `image_picker`           | `^1.1.2`  | Upload de imagens                 |

---

## Microsserviços consumidos

Este app consome exclusivamente o backend **app-athlos-backend** (Identidade, Associação, Feed, Financeiro, Lojinha, Notificações). O serviço legado `user-auth` (porta 4007) **não é utilizado** pelo app.

Para subir o backend completo, consulte o [README do backend](https://github.com/GabrielMottaBecker/app-athlos-backend).

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

# Analisar código (lints)
flutter analyze
```

---

## Documentação adicional

- [`RelatorioTecnico.md`](./RelatorioTecnico.md) — relatório técnico do Projeto Integrador, com detalhamento da arquitetura MVVM, padrões de projeto (Singleton, Observer), estratégia de integração com a API e persistência local.
