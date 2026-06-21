# Relatório Técnico — Athlos (App Flutter)

**Projeto Integrador — Desenvolvimento de aplicativo Flutter com foco em arquitetura, integração e persistência de dados**

---

## 1. Introdução

### 1.1 Problema abordado

Atléticas universitárias geralmente gerenciam associados, eventos, comunicação e produtos de forma manual ou fragmentada entre planilhas, grupos de mensagens e cadernos físicos. Isso dificulta o controle de quem está ativo, a divulgação de eventos/treinos, a organização financeira e a venda de produtos da atlética.

### 1.2 Proposta da solução

O **Athlos** é uma plataforma mobile para gestão de atléticas universitárias, composta por um app Flutter e um backend de microsserviços. O app permite que presidentes e administradores cadastrem a atlética, gerenciem associados e cargos, publiquem posts/eventos no feed, controlem o catálogo da lojinha e (módulo planejado) acompanhem o financeiro — enquanto os usuários comuns consultam o feed, a agenda de eventos e confirmam presença.

O app foi desenvolvido com arquitetura **MVVM + Clean Architecture**, consumindo uma API de microsserviços via REST e persistindo dados localmente tanto para autenticação quanto para uso offline de conteúdo.

---

## 2. Arquitetura MVVM

### 2.1 Como foi organizada

O projeto segue MVVM combinado com camadas inspiradas em Clean Architecture, organizadas em `lib/`:

```
lib/
├── core/        # Infraestrutura transversal (rede, erros, tema)
├── data/        # Implementação: datasources, models, repositories
├── domain/      # Regras de negócio: entities, usecases, contratos de repository
├── viewmodels/  # Estado e lógica de apresentação (ChangeNotifier)
└── views/       # Widgets — apenas leitura de estado e disparo de ações
```

- **Model** — representado pelas `entities` (domínio) e pelos `models` (dados, com (de)serialização JSON), além dos `usecases` que encapsulam regras de negócio isoladas (`LoginUsecase`, `LogoutUsecase`, `RefreshTokenUsecase`).
- **ViewModel** — classes que estendem `ChangeNotifier` (ex.: `FeedViewModel`, `AuthViewModel`, `MembersViewModel`, `LojaViewModel`), responsáveis por orquestrar chamadas aos repositories/datasources, manter estado de UI (`isLoading`, `error`, listas) e notificar a View via `notifyListeners()`.
- **View** — widgets em `views/`, que apenas leem o estado do ViewModel (via `Provider`/`Consumer`/`context.watch`) e disparam ações (`context.read<X>().metodo()`). Não há regra de negócio nas Views: validações, parsing e chamadas de API ficam nas camadas inferiores.

### 2.2 Divisão de responsabilidades

| Camada | Responsabilidade | Não faz |
|---|---|---|
| `views/` | Renderizar UI, capturar interação do usuário | Chamar API diretamente, lógica de negócio |
| `viewmodels/` | Orquestrar estado, decidir o que exibir (loading/erro/sucesso/cache) | Detalhes de serialização ou de transporte HTTP |
| `domain/` | Regras de negócio puras (usecases, contratos) | Conhecer Dio, SharedPreferences ou qualquer detalhe de implementação |
| `data/` | Implementação concreta: chamadas HTTP (Dio), persistência local, mapeamento JSON ↔ Model | Lógica de apresentação |

Essa separação evita que widgets concentrem regras de negócio: por exemplo, o fluxo de login (`AuthViewModel` → `LoginUsecase` → `AuthRepositoryImpl` → `AuthRemoteDatasource`) trafega por todas as camadas sem que a `LoginView` conheça detalhes de token, JWT ou armazenamento seguro.

---

## 3. Padrão de projeto adicional

Foram aplicados dois padrões além do MVVM:

### 3.1 Singleton

**Onde:** `TokenLocalDatasource` (armazenamento de tokens) e `DioClient` (instâncias HTTP por microsserviço).

**Por quê:** o app consome 6 microsserviços diferentes (identidade, associação, feed, financeiro, lojinha, notificações). Criar uma nova instância de `Dio` ou reabrir o `FlutterSecureStorage` a cada chamada seria custoso e arriscaria estados de token inconsistentes entre partes do app (ex.: um logout em uma tela não refletir em outra). O Singleton garante:

- uma única fonte de verdade para o estado de sessão (tokens, role, atleticaId) em memória + disco, evitando leituras divergentes;
- reaproveitamento de uma única instância `Dio` por serviço (com seus interceptors já configurados), evitando overhead de recriação.

```dart
class TokenLocalDatasource {
  static final TokenLocalDatasource _instance = TokenLocalDatasource._internal();
  factory TokenLocalDatasource({FlutterSecureStorage? storage}) => _instance;
  TokenLocalDatasource._internal() : _storage = const FlutterSecureStorage();
  ...
}
```

```dart
class DioClient {
  static Dio? _identidade;
  static Dio get identidade => _identidade ??= _make('http://localhost:4002/v1');
  ...
}
```

### 3.2 Observer (via `ChangeNotifier` / `Provider`)

**Onde:** todos os ViewModels (`FeedViewModel`, `AuthViewModel`, `MembersViewModel` etc.) e o `ThemeNotifier`.

**Por quê:** a UI precisa reagir automaticamente a mudanças de estado (novo post carregado, erro de rede, tema customizado da atlética aplicado) sem acoplamento direto entre quem produz a mudança e quem a exibe. O `ChangeNotifier` implementa o padrão Observer nativamente: ViewModels emitem `notifyListeners()` e qualquer View inscrita (via `Consumer`/`context.watch`) é reconstruída automaticamente.

Exemplo: quando o `ThemeNotifier` aplica as cores da atlética vindas da API (`applyHexColors`), todas as telas que dependem do tema (`context.athlos`) são notificadas e repintadas, sem que cada tela precise consultar o backend individualmente.

---

## 4. Integração com API

### 4.1 Endpoints e fluxo de consumo

O app consome 6 microsserviços REST via `Dio`, cada um com base URL própria (`DioClient`):

| Serviço | Porta | Exemplo de uso no app |
|---|---|---|
| Identidade | 4002 | Login, refresh token |
| Associação | 4001 | Associados, cargos |
| Feed | 4003 | Posts/eventos, confirmação de presença |
| Financeiro | 4004 | *(módulo planejado no app — backend já disponível)* |
| Lojinha | 4005 | Produtos, link de pedido |
| Notificações | 4006 | Notificações, device tokens |

Fluxo típico (Feed): `FeedView` → `FeedViewModel.load()` → `FeedRemoteDatasource.getPosts()` → `Dio` (instância singleton do serviço `feed`) → API → `PostModel.fromJson()` → estado do ViewModel → `notifyListeners()` → UI atualizada.

Um `AuthInterceptor` é registrado em cada instância `Dio`, injetando automaticamente o header `Authorization: Bearer <token>` e renovando o token via `/v1/auth/refresh` em caso de `401`, deslogando o usuário apenas se a renovação falhar.

### 4.2 Tratamento de erros e estados

Cada ViewModel expõe explicitamente os três estados exigidos:

- **Carregamento** — flag `isLoading`, exibida na View como `CircularProgressIndicator`.
- **Sucesso** — dados atualizados (`posts`, `members` etc.) e `notifyListeners()`.
- **Erro** — campo `error`/`errorMessage` capturado em `try/catch` (timeout, falha de conexão, resposta inválida do Dio), exibido na UI (ex.: `login_view.dart` mostra a mensagem de erro abaixo do formulário).

No caso específico do Feed, o tratamento de erro foi reforçado: se a chamada à API falhar mas houver dados em cache local, o app **não exibe tela de erro vazia** — mantém o conteúdo já conhecido na tela e sinaliza visualmente que os dados podem estar desatualizados (ver seção 5).

---

## 5. Persistência local

### 5.1 Tecnologia adotada

Duas tecnologias foram usadas, cada uma adequada ao tipo de dado:

| Tecnologia | Uso | Motivo da escolha |
|---|---|---|
| `flutter_secure_storage` | Sessão (tokens, role, ids) | Armazenamento criptografado (Keystore/Keychain), adequado para dados sensíveis como JWT |
| `shared_preferences` | Cache de conteúdo (posts do Feed) | Leve, simples, suficiente para dados não sensíveis que só precisam sobreviver entre aberturas do app |

### 5.2 Quais dados são persistidos e por quê

**a) Sessão de autenticação** (`TokenLocalDatasource`)
`accessToken`, `refreshToken`, `role`, `userId`, `atleticaId` e validade da sessão (24h). Persistidos para que o usuário não precise logar a cada abertura do app — a `SplashView` verifica a sessão local antes de decidir se redireciona para o login ou direto para a tela principal.

**b) Conteúdo do Feed** (`FeedLocalDatasource`)
A lista de posts retornada pela API é serializada em JSON e salva por `atleticaId`, junto com o timestamp da última sincronização. Fluxo:

1. Ao abrir o Feed, o cache local é exibido **imediatamente** (recuperação de dados ao reabrir o app).
2. Em paralelo, o app sincroniza com a API.
3. Em caso de sucesso, a tela é atualizada e o cache é regravado.
4. Em caso de falha de rede, o conteúdo em cache permanece visível, com um indicador (`"Exibindo dados salvos localmente"`) informando o horário da última sincronização — em vez de uma tela vazia ou erro bloqueante.

Essa camada foi adicionada especificamente para cobrir o requisito de persistir **dados úteis da aplicação** (não apenas credenciais) e garantir que eles sejam **recuperados ao reabrir o app**, inclusive em cenários offline.

---

## 6. Conclusão

### 6.1 Principais decisões

- Separação rígida entre `domain`, `data`, `viewmodels` e `views`, mantendo a UI livre de regras de negócio.
- Uso de Singleton para garantir consistência de sessão e eficiência nas instâncias HTTP por microsserviço.
- Uso do padrão Observer (`ChangeNotifier`/`Provider`) como mecanismo nativo do Flutter para reatividade entre ViewModel e View.
- Persistência local em duas camadas complementares: segurança (tokens) e disponibilidade offline (conteúdo).

### 6.2 Limitações e melhorias futuras

- O módulo **Financeiro** já está disponível no backend, mas a integração no app ainda está planejada (não implementada nesta entrega).
- O cache local cobre hoje apenas o **Feed**; o mesmo padrão (`*LocalDatasource` com `shared_preferences`) pode ser replicado para Agenda e Lojinha em iterações futuras, ampliando a experiência offline.
- Não há sincronização em segundo plano (background sync) — a atualização do cache ocorre apenas quando a tela correspondente é aberta.
- Testes automatizados (unitários/widget) ainda são limitados; recomenda-se ampliar a cobertura, especialmente sobre ViewModels e o fluxo de cache/erro do Feed.