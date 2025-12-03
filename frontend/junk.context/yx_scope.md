{% cut "**Содержание**" %}

{% toc %}

{% endcut %}

## Введение

### Проблема связывания зависимостей

В любом нетривиальном приложении возникает задача организации взаимодействия между классами разных слоев и функций. Существует несколько подходов к решению этой проблемы:

**Singleton** — простейший способ, но с критическими недостатками:

- Невозможность управления ресурсами
- Невозможность контроля области видимости
- Неявные связи между компонентами
- Недетерминированное поведение, обнаруживаемое только в runtime

**ServiceLocator** — более гибкий подход с частичным контролем:

- Позволяет управлять ресурсами через Factory и работу с контейнером
- Но сохраняет проблемы с областью видимости и неявными зависимостями
- Любой компонент может обращаться к любому через локатор

**Dependency Injection** — получение зависимостей через конструктор:

- Полный контроль ресурсов со стороны контейнера
- Однозначный граф зависимостей, известный в compile time
- Потребители не знают о способе предоставления зависимостей

### Что такое yx\_scope

**yx\_scope** — это compile-safe DI фреймворк для Dart с продвинутыми возможностями управления областями видимости (скоупами).

Основные принципы библиотеки:

- **Compile-safety** — если код компилируется, он будет корректно работать
- **Прозрачность** — никакой "магии", полностью детерминированное и предсказуемое поведение
- **Простота** — в базовых сценариях практически не отличается от других DI решений
- **Масштабируемость** — легко создавать, связывать и изменять скоупы
- **Flutter-friendly** — чистый Dart, но с удобной интеграцией в UI

Характеристики:

- Чистый Dart без привязки к UI фреймворку
- DI-подход (не статика и не ServiceLocator)
- Отсутствие кодогенерации
- Нереактивное дерево зависимостей
- Декларативное описание зависимостей
- Поддержка асинхронных зависимостей
- Compile-safe доступ к зависимостям
- Скоупы любой вложенности

### Концепция скоупов

**Скоуп** — это группа зависимостей, ограниченная временным жизненным циклом. В отличие от простых технических жизненных циклов (singleton, factory), скоупы оперируют смысловыми жизненными циклами:

- Техническиие ЖЦ: время жизни приложения, время выполнения функции
- Смысловые ЖЦ: авторизованный пользователь, активная тренировка, открытый документ
- UI ЖЦ: видимый экран, активный компонент

Ключевой принцип yx\_scope: **скоупы должны отражать бизнес-процессы, а не UI элементы**. Это позволяет проектировать взаимосвязи зависимостей в терминах доменной логики, делая архитектуру более устойчивой к изменениям представления.

### Терминология

- **Контейнер** — группа объединенных зависимостей
- **Зависимость (Dep)** — сущность внутри контейнера, обеспечивающая доступ к инстансу класса
- **Скоуп** — жизненный цикл, в рамках которого существует только один инстанс контейнера
- **Скоуп холдер** — сущность, управляющая состоянием контейнера (создание/удаление)
- **Суперзависимость** — зависимость, от которой зависит текущая
- **Подзависимость** — зависимость, которая зависит от текущей
- **Инициализация** — процесс создания и подготовки зависимостей к использованию
- **Диспоуз** — процесс корректного освобождения ресурсов зависимостей

### Группа библиотек yx\_scope

Экосистема состоит из трех пакетов:

1. [**yx\_scope**](https://github.com/yandex/yx_scope/tree/main/packages/yx_scope) — ядро фреймворка, основная логика DI
2. [**yx\_scope\_flutter**](https://github.com/yandex/yx_scope/tree/main/packages/yx_scope_flutter) — адаптер для интеграции в дерево виджетов Flutter
3. [**yx\_scope\_linter**](https://github.com/yandex/yx_scope/tree/main/packages/yx_scope_linter) — набор lint-правил для предотвращения типичных ошибок

---

## Getting Started

### Подключение

Добавьте зависимости в `pubspec.yaml`:

```yaml
dependencies:
  yx_scope: ^1.0.0
  yx_scope_flutter: ^1.0.0  # если используете Flutter

dev_dependencies:
  yx_scope_linter: ^1.0.0
  custom_lint: ^0.5.3
```

Для активации линтера добавьте в `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

### Минимальный пример

Создайте контейнер с зависимостями:

```dart
import 'package:yx_scope/yx_scope.dart';

class AppScopeContainer extends ScopeContainer {
  late final routerDep = dep(() => AppRouter());
  late final apiClientDep = dep(() => ApiClient());
  late final userManagerDep = dep(() => UserManager(apiClientDep.get));
}
```

Создайте холдер для управления жизненным циклом:

```dart
class AppScopeHolder extends ScopeHolder<AppScopeContainer> {
  @override
  AppScopeContainer createContainer() => AppScopeContainer();
}
```

Используйте в приложении:

```dart
Future<void> main() async {
  final appScopeHolder = AppScopeHolder();
  await appScopeHolder.create();

  final appScope = appScopeHolder.scope;
  if (appScope != null) {
    final userManager = appScope.userManagerDep.get;
    // Работайте с зависимостями
  }
  
  await appScopeHolder.drop(); // Освобождение ресурсов
}
```

### Интеграция с Flutter

```dart
class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {

  // Переменная для хранения состояния скоупа
  final _appScopeHolder = AppScopeHolder();

  @override
  void initState() {
    super.initState();
	// Создание скоупа
    _appScopeHolder.create();
  }

  @override
  void dispose() {
	// Удаление скоупа
    _appScopeHolder.drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
	// Предоставление скоупа всему поддереву виджетов
    return ScopeProvider(
      holder: _appScopeHolder,
      child: ScopeBuilder<AppScopeContainer>.withPlaceholder(
		// Извлечение скоупа внутри поддереве
        builder: (context, appScope) {
          return MaterialApp(
			// Использование зависимостей скоупа
            home: HomePage(appScope.config),
          );
        },
        placeholder: const CircularProgressIndicator(),
      ),
    );
  }
}
```

Этот минимальный пример демонстрирует основные концепции: контейнер описывает зависимости, холдер управляет жизненным циклом, а Flutter виджеты получают доступ к скоупу через провайдер и билдер.

---

## Основы

### ScopeContainer и Dep

#### Реализация контейнера

`ScopeContainer` — это группа зависимостей, объединенных по смыслу. В простейшем случае это все зависимости приложения:

```dart
class AppScopeContainer extends ScopeContainer {
  late final apiClientDep = dep(() => ApiClient());
  late final userRepositoryDep = dep(() => UserRepository(apiClientDep.get));
  late final authManagerDep = dep(() => AuthManager(userRepositoryDep.get));
}
```

**Ключевые правила:**

1. **Обязательно `late final`** — зависимости инициализируются лениво при первом обращении и остаются неизменными

2. **Приватность через подчеркивание** — скрывайте зависимости, которые не должны быть доступны извне:

   ```dart
   late final _internalServiceDep = dep(() => InternalService());
   late final publicServiceDep = dep(() => PublicService(_internalServiceDep.get));
   ```

3. **Явная декларация связей** — все суперзависимости должны быть видны внутри контейнера

4. **Принцип:** Контейнер и связи зависимостей внутри него обязаны быть описаны явно. Это концентрирует дерево зависимостей в одном месте и делает все связи видимыми в edit-time.

#### Использование Dep

`Dep` — обёртка над конкретной зависимостью, позволяющая контейнеру управлять инстанцированием:

```dart
class UserManager {
  final ApiClient _apiClient;
  UserManager(this._apiClient);
}

class AppScopeContainer extends ScopeContainer {
  late final apiClientDep = dep(() => ApiClient());
  
  // Доступ к зависимости через .get
  late final userManagerDep = dep(() => UserManager(apiClientDep.get));
}
```

**Важные характеристики:**

- **Единственность инстансов** — в рамках одного контейнера каждая зависимость создается только один раз при первом обращении
- **Ленивая инициализация** — зависимость создается только когда к ней впервые обращаются
- **Изоляция контейнеров** — разные контейнеры содержат полностью независимые инстансы
- **Принцип:** `Dep` должны использоваться только внутри `ScopeContainer`. Это изолирует механизм DI от бизнес-логики.

### ScopeHolder

#### Реализация ScopeHolder

`ScopeHolder` — хранилище с актуальным состоянием контейнера для скоупа:

```dart
class AppScopeHolder extends ScopeHolder<AppScopeContainer> {
  @override
  AppScopeContainer createContainer() => AppScopeContainer();
}
```

Использование `ScopeHolder` обязательно для доступа к контейнеру. Это обеспечивает два ключевых преимущества:

1. **Compile-time null-safety** — обязательная проверка существования скоупа
2. **Реактивность** — возможность подписаться на изменения состояния скоупа

#### Использование ScopeHolder

```dart
final appScopeHolder = AppScopeHolder();

// Создание скоупа (всегда асинхронно)
await appScopeHolder.create();

// Синхронный доступ к контейнеру (может быть null)
final appScope = appScopeHolder.scope;
if (appScope != null) {
  final userManager = appScope.userManagerDep.get;
}

// Реактивная подписка
appScopeHolder.stream.listen((scope) {
  if (scope != null) {
    // Скоуп существует
  } else {
    // Скоуп закрыт
  }
});

// Закрытие скоупа
await appScopeHolder.drop();
```

### Безопасная работа со скоупами

Все обращения к скоупу можно разделить на три типа:

#### Безопасные обращения

&[Работа с контейнером внутри дерева скоупов, где гарантирован доступ:](370164)

```dart
class UserScopeContainer extends ScopeContainer {
  late final userManagerDep = dep(() => UserManager());

  late final userServiceDep = dep(() => UserService(userManagerDep.get));
}

class UserService {
  final UserManager _userManager;

  UserService(this._userManager);
  
  void doWork() {
    // Безопасно — мы внутри скоупа,
	// значит userManager точно существует
    final userManager = _userManager;
  }
}
```

#### Небезопасные обращения

Обращение к холдеру без гарантий существования скоупа:

```dart
void someFunction(AppScopeHolder holder) {
  final scope = holder.scope; // Может быть null!
  if (scope != null) {
    final userManager = scope.userManagerDep.get;
    // Используем userManager
  } else {
    // Обрабатываем отсутствие скоупа
  }
}
```

#### Квазибезопасные обращения

После проверки на null, но до async gap:

```dart
void handleUser(AppScopeHolder holder) {
  final scope = holder.scope;
  if (scope != null) {
    // Квазибезопасно до первого await
    final userManager = scope.userManagerDep.get;
    
    // НЕ ДЕЛАЙТЕ ТАК — после async gap скоуп может быть закрыт
    // await someAsyncOperation();
    // final otherService = scope.otherServiceDep.get; // Опасно!
  }
}
```

> **Правило:** Не сохраняйте инстанс контейнера в поле класса или локальную переменную с доступом через async gap. Это может привести к обращению к закрытому скоупу.

### Асинхронные зависимости

#### Проблема инициализации в конструкторе

Многие сервисы требуют асинхронной инициализации. Выполнение её в конструкторе создает проблемы:

- Недетерминированный момент инициализации
- Несимметричность выделения/освобождения ресурсов
- Невозможность дождаться завершения асинхронной инициализации

```dart
// ПЛОХО
class DatabaseService {
  DatabaseService() {
    _init(); // Когда завершится?
  }
  
  Future<void> _init() async { /* ... */ }
}
```

#### Явные методы жизненного цикла

Рекомендуется использовать явные асинхронные методы `init`/`dispose`:

```dart
class DatabaseService implements AsyncLifecycle {
  Database? _db;
  
  @override
  Future<void> init() async {
    _db = await openDatabase('app.db');
  }
  
  @override
  Future<void> dispose() async {
    await _db?.close();
  }
  
  void query() {
    if (_db == null) throw StateError('Not initialized');
    // Используем _db
  }
}
```

#### rawAsyncDep

Для зависимостей с кастомной логикой жизненного цикла:

```dart
class AppScopeContainer extends ScopeContainer {
  late final databaseServiceDep = rawAsyncDep<DatabaseService>(
    () => DatabaseService(),
    init: (service) async => service.initilize(),
    dispose: (service) async => service.close(),
  );
}
```

#### asyncDep

Для зависимостей, реализующих `AsyncLifecycle`:

```dart
class AppScopeContainer extends ScopeContainer {
  late final databaseServiceDep = asyncDep(() => DatabaseService());
}
```

#### initializeQueue

Для контроля порядка инициализации зависимостей:

```dart
class AppScopeContainer extends ScopeContainer {
  @override
  List<Set<AsyncDep>> get initializeQueue => [
    // Первый этап — параллельная инициализация
    {configServiceDep, loggerServiceDep},
    // Второй этап — зависит от первого
    {databaseServiceDep},
    // Третий этап — зависит от второго
    {userRepositoryDep, authServiceDep},
  ];

  late final configServiceDep = asyncDep(() => ConfigService());
  late final loggerServiceDep = asyncDep(() => LoggerService());
  late final databaseServiceDep = asyncDep(() => DatabaseService(configServiceDep.get));
  late final userRepositoryDep = asyncDep(() => UserRepository(databaseServiceDep.get));
  late final authServiceDep = asyncDep(() => AuthService(userRepositoryDep.get));
}
```

> **Гарантия:** yx\_scope обеспечивает не только доступность инстансов, но и их полную готовность к использованию. Если доступ к контейнеру получен, все зависимости проинициализированы.

### ScopeModule

Для группировки связанных зависимостей без создания отдельного скоупа:

```dart
class AppScopeContainer extends ScopeContainer {
  late final userScopeHolderDep = dep(() => UserScopeHolder(this));
  
  // Группировка связанных зависимостей
  late final networkModule = NetworkAppScopeModule(this);
  late final storageModule = StorageAppScopeModule(this);
}

class NetworkAppScopeModule extends ScopeModule<AppScopeContainer> {
  NetworkAppScopeModule(super.container);

  late final httpClientDep = dep(() => HttpClient());
  late final apiClientDep = dep(() => ApiClient(httpClientDep.get));
  
  // Доступ к зависимостям контейнера
  late final authenticatedApiDep = dep(() => AuthenticatedApi(
    apiClientDep.get,
    container.userScopeHolderDep.get,
  ));
}
```

> **Принцип:** Не создавайте скоуп, если жизненный цикл сущностей одинаковый! Используйте `ScopeModule` для логической группировки.

---

## Интерфейсы и архитектура

### Container implements Scope

#### Проблема прямого доступа к контейнеру

При использовании контейнера напрямую возникают архитектурные проблемы:

```dart
// Проблематично
void someFunction(AppScopeHolder holder) {
  final scope = holder.scope;
  if (scope != null) {
    // 1. Зависимость на yx_scope (Dep<T>)
    final userManager = scope.userManagerDep.get;
    
    // 2. Доступ ко всем методам контейнера (dep, asyncDep, etc.)
    // 3. Доступ ко всем зависимостям, включая приватные
  }
}
```

#### Решение через интерфейс

Создайте интерфейс, описывающий только необходимые зависимости:

```dart
abstract class AppScope implements Scope {
  UserManager get userManager;
  AuthManager get authManager;
  // Только публичный контракт
}

class AppScopeContainer extends ScopeContainer implements AppScope {
  late final _internalServiceDep = dep(() => InternalService());
  late final userManagerDep = dep(() => UserManager(_internalServiceDep.get));
  late final authManagerDep = dep(() => AuthManager(userManagerDep.get));

  // Реализация интерфейса
  @override
  UserManager get userManager => userManagerDep.get;

  @override  
  AuthManager get authManager => authManagerDep.get;
}
```

#### Использование интерфейса

```dart
void businessLogic(AppScope appScope) {
  // Работаем только с доменными сущностями
  final userManager = appScope.userManager;
  final authManager = appScope.authManager;
  
  // Нет доступа к _internalServiceDep
  // Нет знания о yx_scope
}
```

### BaseScopeHolder vs ScopeHolder

#### Когда использовать BaseScopeHolder

`BaseScopeHolder` необходим для работы с интерфейсами:

```dart
// Обычный холдер — работает с конкретным контейнером
class AppScopeHolder extends ScopeHolder<AppScopeContainer> {
  @override
  AppScopeContainer createContainer() => AppScopeContainer();
}

// BaseScopeHolder — позволяет использовать интерфейс
class AppScopeHolder extends BaseScopeHolder<AppScope, AppScopeContainer> {
  @override
  AppScopeContainer createContainer() => AppScopeContainer();
}
```

**Сравнение доступа:**

```dart
final appScopeHolder = AppScopeHolder();

// ScopeHolder<AppScopeContainer>
AppScopeContainer? scope1 = appScopeHolder.scope; // Весь контейнер

// BaseScopeHolder<AppScope, AppScopeContainer>  
AppScope? scope2 = appScopeHolder.scope; // Только интерфейс
```

#### Практические преимущества

```dart
// Принимаем интерфейс, а не конкретную реализацию
class UserWidget extends StatelessWidget {
  final AppScope appScope;
  
  const UserWidget({required this.appScope, super.key});

  @override
  Widget build(BuildContext context) {
    // Работаем с доменными методами
    return Text(appScope.userManager.currentUser.name);
  }
}

// Используем в дереве виджетов
ScopeBuilder<AppScope>.withPlaceholder(
  builder: (context, appScope) => UserWidget(appScope: appScope),
  placeholder: const CircularProgressIndicator(),
)
```

### Holder implements Logic

#### Скрытие DI логики за доменными интерфейсами

Холдеры также можно интегрировать в доменный слой через интерфейсы:

```dart
// Доменный интерфейс
abstract class UserSessionManager {
  bool get isActive;
  Stream<bool> get isActiveStream;
  Future<void> startSession(User user);
  Future<void> endSession();
}

// Реализация через скоуп
class UserScopeHolder extends BaseDataScopeHolder<UserScope, UserScopeContainer, User>
    implements UserSessionManager {
    
  UserScopeHolder();

  @override
  UserScopeContainer createContainer(User data) => UserScopeContainer(user: data);

  // Доменные методы
  @override
  bool get isActive => scope != null;

  @override
  Stream<bool> get isActiveStream => stream.map((scope) => scope != null);

  @override
  Future<void> startSession(User user) => create(user);

  @override
  Future<void> endSession() => drop();
}
```

#### Использование в бизнес-логике

```dart
class AuthManager {
  final UserSessionManager _userSessionManager;
  
  AuthManager(this._userSessionManager);

  Future<void> login(String email, String password) async {
    final user = await _authenticate(email, password);
    
    // Доменная логика, не знающая о скоупах
    await _userSessionManager.startSession(user);
  }

  Future<void> logout() async {
    await _userSessionManager.endSession();
  }
}
```

#### Интеграция в контейнер

```dart
class AppScopeContainer extends ScopeContainer implements AppScope {
  late final userSessionManagerDep = dep(() => UserScopeHolder());
  late final authManagerDep = dep(() => AuthManager(userSessionManagerDep.get));

  @override
  UserSessionManager get userSessionManager => userSessionManagerDep.get;

  @override
  AuthManager get authManager => authManagerDep.get;
}
```

### Архитектурные принципы

#### 1. Интерфейсы в каждом слое

```dart
// DI слой
abstract class AppScope { /* публичные зависимости */ }
class AppScopeContainer implements AppScope { /* реализация */ }

// Доменный слой  
abstract class UserSessionManager { /* бизнес-операции */ }
class UserScopeHolder implements UserSessionManager { /* скоуп-логика */ }

// UI слой
abstract class NavigationDelegate { /* навигационные операции */ }
class FlutterNavigationDelegate implements NavigationDelegate { /* Flutter-специфика */ }
```

#### 2. Зависимости только на интерфейсы

```dart
class OrderManager {
  final UserSessionManager _userSession;     // Не UserScopeHolder
  final PaymentService _paymentService;      // Не PaymentScopeContainer
  final NavigationDelegate _navigation;      // Не FlutterNavigationDelegate
  
  OrderManager(this._userSession, this._paymentService, this._navigation);
}
```

#### 3. Скрытие реализации DI

```dart
// ПЛОХО — протекание DI абстракций
class BadUserWidget extends StatelessWidget {
  final ScopeStateHolder<UserScope?> userScopeHolder;
  
  const BadUserWidget({required this.userScopeHolder, super.key});
}

// ХОРОШО — только доменные интерфейсы
class GoodUserWidget extends StatelessWidget {
  final UserScope userScope;
  
  const GoodUserWidget({required this.userScope, super.key});
}
```

### Практические рекомендации

#### 1. Всегда создавайте интерфейсы для публичных контейнеров

```dart
// Для каждого ScopeContainer создавайте Scope интерфейс
abstract class FeatureScope implements Scope { /* ... */ }
class FeatureScopeContainer extends ScopeContainer implements FeatureScope { /* ... */ }
```

#### 2. Используйте BaseScopeHolder для интерфейсов

```dart
// Не ScopeHolder<Container>, а BaseScopeHolder<Interface, Container>
class FeatureScopeHolder extends BaseScopeHolder<FeatureScope, FeatureScopeContainer> {
  @override
  FeatureScopeContainer createContainer() => FeatureScopeContainer();
}
```

#### 3. Интегрируйте холдеры в доменный слой

```dart
// Холдеры должны реализовывать доменные интерфейсы
abstract class FeatureManager { /* доменные операции */ }
class FeatureScopeHolder extends BaseScopeHolder<FeatureScope, FeatureScopeContainer>
    implements FeatureManager { /* ... */ }
```

---

## Интеграция с Flutter

### ScopeProvider

#### Внедрение скоупа в дерево виджетов

`ScopeProvider` — это `InheritedWidget`, который делает скоуп доступным в любой части поддерева:

```dart
class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _appScopeHolder = AppScopeHolder();

  @override
  void initState() {
    super.initState();
    _appScopeHolder.create();
  }

  @override
  void dispose() {
    _appScopeHolder.drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopeProvider<AppScope>(
      holder: _appScopeHolder,
      child: MaterialApp(
        home: HomePage(),
      ),
    );
  }
}
```

#### Получение скоупа через контекст

```dart
class SomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Прямое получение холдера
    final appScopeHolder = ScopeProvider.of<AppScope>(context);
    
    // Проверяем наличие скоупа
    final appScope = appScopeHolder.scope;
    if (appScope != null) {
      return Text('User: ${appScope.userManager.currentUser.name}');
    } else {
      return const CircularProgressIndicator();
    }
  }
}
```

### ScopeBuilder

#### Реактивное построение UI

`ScopeBuilder` автоматически перестраивает виджет при изменении состояния скоупа:

```dart
class UserProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScopeBuilder<AppScope>(
      builder: (context, appScope) {
        if (appScope == null) {
          return const CircularProgressIndicator();
        }
        
        return Column(
          children: [
            Text('Welcome ${appScope.userManager.currentUser.name}'),
            ElevatedButton(
              onPressed: () => appScope.authManager.logout(),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
```

#### Использование withPlaceholder

Для улучшения читаемости кода используйте `withPlaceholder`:

```dart
ScopeBuilder<AppScope>.withPlaceholder(
  builder: (context, appScope) {
    // appScope гарантированно не null
    return UserDashboard(
      userManager: appScope.userManager,
      orderManager: appScope.orderManager,
    );
  },
  placeholder: const Center(
    child: CircularProgressIndicator(),
  ),
)
```

#### Передача конкретного холдера

Если нужно использовать холдер, недоступный через `ScopeProvider`:

```dart
class FeatureWidget extends StatelessWidget {
  final FeatureScopeHolder featureScopeHolder;
  
  const FeatureWidget({required this.featureScopeHolder, super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeBuilder<FeatureScope>(
      holder: featureScopeHolder,
      builder: (context, featureScope) {
        if (featureScope == null) {
          return const Text('Feature not available');
        }
        
        return FeatureContent(scope: featureScope);
      },
    );
  }
}
```

### ScopeListener

#### Выполнение побочных эффектов

`ScopeListener` позволяет реагировать на изменения скоупа без перестроения UI:

```dart
class NavigationHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScopeListener<UserScope>(
      listener: (context, userScope) {
        if (userScope == null) {
          // Пользователь разлогинился — переходим на экран входа
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          // Пользователь залогинился — переходим в главное меню
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      },
      child: const SizedBox.shrink(), // Невидимый виджет
    );
  }
}
```

#### Показ уведомлений

```dart
ScopeListener<OrderScope>(
  listener: (context, orderScope) {
    if (orderScope != null && orderScope.orderManager.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order completed!')),
      );
    }
  },
  child: OrderTrackingWidget(),
)
```

#### Комбинирование с другими виджетами

```dart
class OrderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScopeListener<OrderScope>(
        listener: (context, orderScope) {
          // Побочные эффекты
          if (orderScope?.orderManager.hasError == true) {
            _showErrorDialog(context);
          }
        },
        child: ScopeBuilder<OrderScope>.withPlaceholder(
          builder: (context, orderScope) {
            // Основной UI
            return OrderContent(orderManager: orderScope.orderManager);
          },
          placeholder: const OrderLoadingWidget(),
        ),
      ),
    );
  }
}
```

---

## Продвинутые скоупы

### Child scopes

#### ChildScopeContainer и ChildScopeHolder

&[Дочерние скоупы зависят от родительского скоупа и автоматически закрываются при его закрытии:](365728)

```dart
// Родительский скоуп
abstract class AppScope implements Scope {
  UserRepository get userRepository;
  NotificationService get notificationService;
}

class AppScopeContainer extends ScopeContainer implements AppScope {

  late final UserScopeHolder _userScopeHolder = dep(() => UserScopeHolder(this));

  late final userRepositoryDep = dep(() => UserRepository());
  late final notificationServiceDep = dep(() => NotificationService());
  
  @override
  UserRepository get userRepository => userRepositoryDep.get;
  
  @override
  NotificationService get notificationService => notificationServiceDep.get;
}

// Дочерний скоуп
abstract class UserScope implements Scope {
  UserManager get userManager;
  UserPreferences get userPreferences;
}

class UserScopeContainer extends ChildScopeContainer<AppScope> implements UserScope {
  UserScopeContainer({required super.parent});

  late final userManagerDep = dep(() => UserManager(
    parent.userRepository,
    parent.notificationService,
  ));
  
  late final userPreferencesDep = dep(() => UserPreferences());

  @override
  UserManager get userManager => userManagerDep.get;

  @override
  UserPreferences get userPreferences => userPreferencesDep.get;
}
```

#### Холдер для дочернего скоупа

```dart
class UserScopeHolder extends BaseChildScopeHolder<UserScope, UserScopeContainer, AppScope> {
  UserScopeHolder(AppScope parent) : super(parent);

  @override
  UserScopeContainer createContainer(AppScope parent) => UserScopeContainer(parent: parent);
}
```

#### Интеграция в родительский контейнер

```dart
class AppScopeContainer extends ScopeContainer implements AppScope {
  // Дочерний скоуп объявляется как зависимость
  late final userScopeHolderDep = dep(() => UserScopeHolder(this));

  late final userRepositoryDep = dep(() => UserRepository());
  late final notificationServiceDep = dep(() => NotificationService());

  @override
  UserRepository get userRepository => userRepositoryDep.get;
  
  @override
  NotificationService get notificationService => notificationServiceDep.get;
}
```

#### Использование дочернего скоупа

```dart
class UserManager {
  final AppScopeHolder _appScopeHolder;
  
  UserManager(this._appScopeHolder);

  Future<void> loginUser(User user) async {
    final appScope = _appScopeHolder.scope;
    if (appScope != null) {
      // Создаем дочерний скоуп для пользователя
      await appScope.userScopeHolder.create();
      
      // Скоуп автоматически закроется при закрытии appScope
    }
  }

  Future<void> logoutUser() async {
    final appScope = _appScopeHolder.scope;
    if (appScope != null) {
      // Явно закрываем дочерний скоуп
      await appScope.userScopeHolder.drop();
    }
  }
}
```

### Data scopes

#### DataScopeContainer и DataScopeHolder

Скоупы с данными принимают начальные данные при создании:

```dart
class Order {
  final String id;
  final List<OrderItem> items;
  
  Order({required this.id, required this.items});
}

abstract class OrderScope implements Scope {
  Order get order;
  OrderManager get orderManager;
  PaymentProcessor get paymentProcessor;
}

class OrderScopeContainer extends DataScopeContainer<Order> implements OrderScope {
  OrderScopeContainer({required super.data});

  late final orderManagerDep = dep(() => OrderManager(data));
  late final paymentProcessorDep = dep(() => PaymentProcessor(data));

  @override
  Order get order => data;

  @override
  OrderManager get orderManager => orderManagerDep.get;

  @override
  PaymentProcessor get paymentProcessor => paymentProcessorDep.get;
}
```

#### Холдер для скоупа с данными

```dart
class OrderScopeHolder extends BaseDataScopeHolder<OrderScope, OrderScopeContainer, Order> {
  @override
  OrderScopeContainer createContainer(Order data) => OrderScopeContainer(data: data);
}
```

#### Использование скоупа с данными

```dart
class OrderService {
  final OrderScopeHolder _orderScopeHolder;
  
  OrderService(this._orderScopeHolder);

  Future<void> processOrder(Order order) async {
    // Создаем скоуп с конкретными данными заказа
    await _orderScopeHolder.create(order);
    
    final orderScope = _orderScopeHolder.scope;
    if (orderScope != null) {
      await orderScope.orderManager.process();
      await orderScope.paymentProcessor.charge();
    }
    
    // Закрываем скоуп после обработки
    await _orderScopeHolder.drop();
  }
}
```

### ChildData scopes

#### Комбинирование Parent \+ Data

Скоупы, которые одновременно зависят от родителя и принимают данные:

```dart
abstract class OrderScope implements Scope {
  Order get order;
  OrderManager get orderManager;
  OrderTracker get orderTracker;
}

class OrderScopeContainer extends ChildDataScopeContainer<AppScope, Order> implements OrderScope {
  OrderScopeContainer({
    required super.parent,
    required super.data,
  });

  @override
  List<Set<AsyncDep>> get initializeQueue => [
    {orderTrackerDep}
  ];

  late final orderManagerDep = dep(() => OrderManager(
    data, // Order data
    parent.userRepository, // Из родительского скоупа
    parent.notificationService, // Из родительского скоупа
  ));

  late final orderTrackerDep = asyncDep(() => OrderTracker(
    data,
    parent.trackingService,
  ));

  @override
  Order get order => data;

  @override
  OrderManager get orderManager => orderManagerDep.get;

  @override
  OrderTracker get orderTracker => orderTrackerDep.get;
}
```

#### Холдер для ChildData скоупа

```dart
class OrderScopeHolder extends BaseChildDataScopeHolder<
  OrderScope,
  OrderScopeContainer,
  AppScope,
  Order
> {
  OrderScopeHolder(AppScope parent) : super(parent);

  @override
  OrderScopeContainer createContainer(AppScope parent, Order data) {
    return OrderScopeContainer(parent: parent, data: data);
  }
}
```

#### Интеграция и использование

```dart
class AppScopeContainer extends ScopeContainer implements AppScope {
  late final userRepositoryDep = dep(() => UserRepository());
  late final notificationServiceDep = dep(() => NotificationService());
  late final trackingServiceDep = dep(() => TrackingService());
  
  // Фабрика для создания скоупов заказов
  late final orderScopeHolderFactoryDep = dep(() => OrderScopeHolderFactory(this));

  @override
  UserRepository get userRepository => userRepositoryDep.get;
  
  @override
  NotificationService get notificationService => notificationServiceDep.get;
  
  @override
  TrackingService get trackingService => trackingServiceDep.get;
  
  OrderScopeHolderFactory get orderScopeHolderFactory => orderScopeHolderFactoryDep.get;
}

class OrderScopeHolderFactory {
  final AppScope _appScope;
  
  OrderScopeHolderFactory(this._appScope);

  OrderScopeHolder createOrderScopeHolder() {
    return OrderScopeHolder(_appScope);
  }
}

// Использование
class OrdersManager {
  final OrderScopeHolderFactory _factory;
  final Map<String, OrderScopeHolder> _activeOrders = {};
  
  OrdersManager(this._factory);

  Future<void> startOrderProcessing(Order order) async {
    final holder = _factory.createOrderScopeHolder();
    await holder.create(order);
    
    _activeOrders[order.id] = holder;
  }

  Future<void> completeOrder(String orderId) async {
    final holder = _activeOrders.remove(orderId);
    await holder?.drop();
  }
}
```

### Автоматическое управление жизненным циклом

#### Родительские скоупы автоматически закрывают дочерние

```dart
class OrderProcessingExample {
  final AppScopeHolder _appScopeHolder;
  
  OrderProcessingExample(this._appScopeHolder);

  Future<void> demonstrateLifecycle() async {
    // Создаем родительский скоуп
    await _appScopeHolder.create();
    
    final appScope = _appScopeHolder.scope!;
    
    // Создаем несколько дочерних скоупов
    final orderHolder1 = appScope.orderScopeHolderFactory.createOrderScopeHolder();
    final orderHolder2 = appScope.orderScopeHolderFactory.createOrderScopeHolder();
    
    await orderHolder1.create(Order(id: '1', items: []));
    await orderHolder2.create(Order(id: '2', items: []));
    
    print('Orders active: ${orderHolder1.scope != null}, ${orderHolder2.scope != null}');
    // Вывод: Orders active: true, true
    
    // Закрываем родительский скоуп
    await _appScopeHolder.drop();
    
    // Дочерние скоупы автоматически закрылись
    print('Orders active: ${orderHolder1.scope != null}, ${orderHolder2.scope != null}');
    // Вывод: Orders active: false, false
  }
}
```

#### Реактивное отслеживание состояния

```dart
class OrderStatusWidget extends StatelessWidget {
  final OrderScopeHolder orderScopeHolder;
  
  const OrderStatusWidget({required this.orderScopeHolder, super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeBuilder<OrderScope>(
      holder: orderScopeHolder,
      builder: (context, orderScope) {
        if (orderScope == null) {
          return const Text('Order completed or cancelled');
        }
        
        return Column(
          children: [
            Text('Order: ${orderScope.order.id}'),
            Text('Status: ${orderScope.orderManager.status}'),
            StreamBuilder<TrackingInfo>(
              stream: orderScope.orderTracker.trackingStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text('Location: ${snapshot.data!.location}');
                }
                return const Text('Tracking unavailable');
              },
            ),
          ],
        );
      },
    );
  }
}
```

### Типичные паттерны использования

#### 1. Пользовательские сессии (Child)

```dart
// App -> User session
AppScope -> UserScope
```

#### 2. Документы с данными (Data)

```dart
// Document processing with specific document data
DocumentScope(documentId, documentData)
```

#### 3. Фичи пользователя с конфигурацией (ChildData)

```dart
// App -> User -> Feature with config
AppScope -> UserScope -> FeatureScope(featureConfig)
```

#### 4. Временные операции (ChildData)

```dart
// App -> Operation with context
AppScope -> OperationScope(operationData)
```

---

## Связывание скоупов

### Parent interfaces

#### Проблема жесткой связанности

Без использования интерфейсов скоупы создают жесткие связи:

```dart
// ПЛОХО — жесткая связь с конкретной реализацией
class OnlineScopeContainer extends ChildScopeContainer<AccountScopeContainer> {
  OnlineScopeContainer({required super.parent});

  late final acceptOrderManagerDep = dep(() => AcceptOrderManager(
    parent.orderRepositoryDep.get,  // Прямая зависимость на Dep
    parent.notificationServiceDep.get,
    parent.userManagerDep.get,
  ));
}
```

Проблемы такого подхода:

- Знание о внутренней структуре родительского контейнера
- Невозможность переиспользования с другими родительскими скоупами
- Сложность тестирования

#### Решение через Parent интерфейсы

Определите интерфейс, описывающий ожидания дочернего скоупа от родителя:

```dart
// Интерфейс для дочернего скоупа
abstract class OnlineScope implements Scope {
  AcceptOrderManager get acceptOrderManager;
}

// Интерфейс, описывающий требования к родителю
abstract class OnlineScopeParent implements Scope {
  OrderRepository get orderRepository;
  NotificationService get notificationService;
  UserManager get userManager;
}

// Дочерний скоуп зависит от интерфейса, а не от реализации
class OnlineScopeContainer extends ChildScopeContainer<OnlineScopeParent> 
    implements OnlineScope {
  OnlineScopeContainer({required super.parent});

  late final acceptOrderManagerDep = dep(() => AcceptOrderManager(
    parent.orderRepository,     // Используем интерфейс
    parent.notificationService,
    parent.userManager,
  ));

  @override
  AcceptOrderManager get acceptOrderManager => acceptOrderManagerDep.get;
}

class OnlineScopeHolder extends BaseChildScopeHolder<OnlineScope, 
    OnlineScopeContainer, OnlineScopeParent> {
  OnlineScopeHolder(OnlineScopeParent parent) : super(parent);

  @override
  OnlineScopeContainer createContainer(OnlineScopeParent parent) =>
      OnlineScopeContainer(parent: parent);
}
```

#### Реализация Parent интерфейса

Родительский скоуп реализует требуемый интерфейс:

```dart
class AccountScopeContainer extends ChildDataScopeContainer<AppScope, User>
    implements AccountScope, OnlineScopeParent {  // Реализует интерфейс родителя
  AccountScopeContainer({
    required super.parent,
    required super.data,
  });

  late final _orderRepositoryDep = dep(() => OrderRepository(data));
  late final _notificationServiceDep = dep(() => NotificationService());
  late final _userManagerDep = dep(() => UserManager(data));
  
  // Дочерний скоуп создается с использованием интерфейса
  late final _onlineScopeHolderDep = dep(() => OnlineScopeHolder(this));

  // Реализация AccountScope
  @override
  User get user => data;

  // Реализация OnlineScopeParent
  @override
  OrderRepository get orderRepository => _orderRepositoryDep.get;

  @override
  NotificationService get notificationService => _notificationServiceDep.get;

  @override
  UserManager get userManager => _userManagerDep.get;

  // Публичный доступ к дочернему скоупу
  OnlineScopeHolder get onlineScopeHolder => _onlineScopeHolderDep.get;
}
```

### Преимущества Parent интерфейсов

#### 1. Переиспользуемость

Дочерний скоуп может работать с любым родителем, реализующим нужный интерфейс:

```dart
// Разные родительские скоупы могут предоставлять OnlineScope
class AdminScopeContainer extends ScopeContainer 
    implements AdminScope, OnlineScopeParent {
  // Другая реализация, но тот же интерфейс
  @override
  OrderRepository get orderRepository => adminOrderRepositoryDep.get;
  // ...
}

class GuestScopeContainer extends ScopeContainer 
    implements GuestScope, OnlineScopeParent {
  // Еще одна реализация
  @override
  OrderRepository get orderRepository => guestOrderRepositoryDep.get;
  // ...
}
```

#### 2. Тестируемость

Легко создавать mock-реализации для тестирования:

```dart
class MockOnlineScopeParent implements OnlineScopeParent {
  @override
  OrderRepository get orderRepository => MockOrderRepository();

  @override
  NotificationService get notificationService => MockNotificationService();

  @override
  UserManager get userManager => MockUserManager();
}

void testOnlineScope() {
  final mockParent = MockOnlineScopeParent();
  final onlineHolder = OnlineScopeHolder(mockParent);
  // Тестируем изолированно
}
```

#### 3. Минимальные контракты

Интерфейс описывает только то, что действительно нужно дочернему скоупу:

```dart
// OnlineScope нужны только эти три зависимости
abstract class OnlineScopeParent implements Scope {
  OrderRepository get orderRepository;
  NotificationService get notificationService;
  UserManager get userManager;
  
  // Не нужны:
  // - DatabaseService
  // - AuthManager  
  // - NavigationService
  // и другие зависимости из AccountScope
}
```

### Внешние зависимости

#### Сценарий изолированного модуля

Когда ваш модуль разрабатывается отдельно или должен интегрироваться в разные хост-приложения.

Это может быть необходимо, когда внешний изолированный модуль не гарантирует наследование от Scope.

```dart
// Внешние зависимости, предоставляемые хостом
abstract class ExternalDependencies {
  HttpClient get httpClient;
  SecureStorage get secureStorage;
  Logger get logger;
}

// Ваш модульный скоуп принимает внешние зависимости
class FeatureModuleScopeContainer extends ScopeContainer implements FeatureModuleScope {
  final ExternalDependencies _externalDeps;
  
  FeatureModuleScopeContainer(this._externalDeps);

  late final apiClientDep = dep(() => ApiClient(_externalDeps.httpClient));
  late final authServiceDep = dep(() => AuthService(
    apiClientDep.get,
    _externalDeps.secureStorage,
  ));
  late final featureManagerDep = dep(() => FeatureManager(
    authServiceDep.get,
    _externalDeps.logger,
  ));

  @override
  FeatureManager get featureManager => featureManagerDep.get;
}

class FeatureModuleScopeHolder extends ScopeHolder<FeatureModuleScopeContainer> {
  final ExternalDependencies _externalDeps;
  
  FeatureModuleScopeHolder(this._externalDeps);

  @override
  FeatureModuleScopeContainer createContainer() => 
      FeatureModuleScopeContainer(_externalDeps);
}
```

#### Интеграция внешних зависимостей

```dart
// В хост-приложении
class HostExternalDependencies implements ExternalDependencies {
  @override
  HttpClient get httpClient => _httpClient;

  @override
  SecureStorage get secureStorage => _secureStorage;

  @override
  Logger get logger => _logger;

  final HttpClient _httpClient = HttpClient();
  final SecureStorage _secureStorage = FlutterSecureStorage();
  final Logger _logger = ConsoleLogger();
}

// Интеграция в основной скоуп
class AppScopeContainer extends ScopeContainer implements AppScope {
  late final _externalDepsDep = dep(() => HostExternalDependencies());
  
  // Модульный скоуп как зависимость
  late final featureModuleScopeHolderDep = dep(() => 
      FeatureModuleScopeHolder(_externalDepsDep.get));

  @override
  FeatureModuleScopeHolder get featureModuleScopeHolder => 
      featureModuleScopeHolderDep.get;
}
```

#### Условная интеграция

```dart
// Разные реализации для разных сред
class ProductionExternalDependencies implements ExternalDependencies {
  @override
  HttpClient get httpClient => ProductionHttpClient();
  // ...
}

class DevelopmentExternalDependencies implements ExternalDependencies {
  @override
  HttpClient get httpClient => DevelopmentHttpClient();
  // ...
}

class TestExternalDependencies implements ExternalDependencies {
  @override
  HttpClient get httpClient => MockHttpClient();
  // ...
}

// Фабрика зависимостей
class ExternalDependenciesFactory {
  static ExternalDependencies create() {
    if (kDebugMode) {
      return DevelopmentExternalDependencies();
    } else if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return TestExternalDependencies();
    } else {
      return ProductionExternalDependencies();
    }
  }
}

// Использование в приложении
class AppScopeContainer extends ScopeContainer {
  late final _externalDepsDep = dep(() => ExternalDependenciesFactory.create());
  
  late final featureModuleScopeHolderDep = dep(() => 
      FeatureModuleScopeHolder(_externalDepsDep.get));
}
```

### Сложные иерархии скоупов

#### Многоуровневая архитектура

```dart
// Уровень 1: Приложение
abstract class AppScopeParent implements Scope {
  ConfigService get configService;
  LoggingService get loggingService;
}

// Уровень 2: Пользователь  
abstract class UserScopeParent implements Scope {
  UserRepository get userRepository;
  AuthService get authService;
}

// Уровень 3: Фича
abstract class FeatureScopeParent implements Scope {
  FeatureConfigService get featureConfigService;
}

// Глубоко вложенный скоуп
class DeepFeatureScopeContainer extends ChildScopeContainer<FeatureScopeParent> 
    implements DeepFeatureScope {
  DeepFeatureScopeContainer({required super.parent});

  // Может обращаться только к своему непосредственному родителю
  late final deepFeatureManagerDep = dep(() => DeepFeatureManager(
    parent.featureConfigService,
  ));
}
```

#### Прокидывание зависимостей через иерархию

```dart
class AppScopeContainer extends ScopeContainer implements AppScope, UserScopeParent {
  late final configServiceDep = dep(() => ConfigService());
  late final loggingServiceDep = dep(() => LoggingService());
  late final userRepositoryDep = dep(() => UserRepository());
  late final authServiceDep = dep(() => AuthService());

  // Реализует как AppScope, так и UserScopeParent
  @override
  ConfigService get configService => configServiceDep.get;

  @override
  UserRepository get userRepository => userRepositoryDep.get;
  // ...
}

class UserScopeContainer extends ChildScopeContainer<UserScopeParent> 
    implements UserScope, FeatureScopeParent {
  UserScopeContainer({required super.parent});

  late final featureConfigServiceDep = dep(() => FeatureConfigService(
    parent.userRepository,
    parent.authService,
  ));

  // Реализует FeatureScopeParent для дочерних скоупов
  @override
  FeatureConfigService get featureConfigService => featureConfigServiceDep.get;
}
```

### Best practices для связывания скоупов

#### 1. Всегда используйте Parent интерфейсы

```dart
// ПЛОХО
class ChildScopeContainer extends ChildScopeContainer<ConcreteScopeContainer>

// ХОРОШО  
class ChildScopeContainer extends ChildScopeContainer<ParentScopeInterface>
```

#### 2. Минимизируйте Parent интерфейсы

```dart
// Включайте только действительно необходимые зависимости
abstract class MinimalParent implements Scope {
  ServiceA get serviceA;  // Используется
  // ServiceB get serviceB;  // НЕ включаем, если не используется
}
```

#### 3. Группируйте логически связанные зависимости

```dart
abstract class DatabaseParent implements Scope {
  UserRepository get userRepository;
  OrderRepository get orderRepository;
  ProductRepository get productRepository;
}

abstract class NetworkParent implements Scope {
  ApiClient get apiClient;
  WebSocketClient get webSocketClient;
}
```

#### 4. Используйте композицию интерфейсов

```dart
abstract class ComplexScopeParent implements DatabaseParent, NetworkParent {
  // Наследует все методы из DatabaseParent и NetworkParent
  ConfigService get configService;  // Дополнительные зависимости
}
```

---

## Best Practices

### Принципы проектирования скоупов

#### 1. Скоупы отражают бизнес-процессы, не UI

```dart
// ПЛОХО — привязка к UI
class LoginPageScopeContainer extends ScopeContainer {
  late final loginFormControllerDep = dep(() => LoginFormController());
  late final submitButtonControllerDep = dep(() => SubmitButtonController());
}

// ХОРОШО — бизнес-процесс
class AuthenticationScopeContainer extends ScopeContainer {
  late final credentialsValidatorDep = dep(() => CredentialsValidator());
  late final authenticationServiceDep = dep(() => AuthenticationService());
  late final sessionManagerDep = dep(() => SessionManager());
}
```

#### 2. Статичность зависимостей

Все зависимости скоупа должны быть известны на этапе компиляции:

```dart
// ПЛОХО — динамическое добавление зависимостей
class BadScopeContainer extends ScopeContainer {
  final Map<String, Dep> _dynamicDeps = {};
  
  void addDependency<T>(String key, T Function() factory) {
    _dynamicDeps[key] = dep(factory);  // НЕ ДЕЛАЙТЕ ТАК
  }
}

// ХОРОШО — статичное объявление
class GoodScopeContainer extends ScopeContainer {
  late final serviceADep = dep(() => ServiceA());
  late final serviceBDep = dep(() => ServiceB());
  late final serviceCDep = dep(() => ServiceC());
}
```

#### 3. Правило одинакового жизненного цикла

Не создавайте отдельный скоуп, если жизненный цикл сущностей совпадает:

```dart
// ПЛОХО — избыточные скоупы с одинаковым ЖЦ
class UserScopeContainer extends ScopeContainer { /* ... */ }
class UserPreferencesScopeContainer extends ScopeContainer { /* ... */ }  // Тот же ЖЦ!

// ХОРОШО — один скоуп с группировкой через модули
class UserScopeContainer extends ScopeContainer {
  late final coreModule = UserCoreModule(this);
  late final preferencesModule = UserPreferencesModule(this);
  late final notificationsModule = UserNotificationsModule(this);
}
```

### Организация кода

#### Структура проекта со скоупами

```
lib/
├── di/                          # DI слой
│   ├── app/
│   │   ├── app_scope.dart      # AppScope + AppScopeContainer + AppScopeHolder
│   │   └── app_modules.dart    # Модули приложения
│   ├── user/
│   │   ├── user_scope.dart
│   │   └── user_modules.dart
│   └── feature/
│       ├── feature_scope.dart
│       └── feature_modules.dart
├── domain/                     # Доменный слой
│   ├── auth/
│   ├── user/
│   └── feature/
├── data/                       # Слой данных
└── ui/                         # UI слой
```

#### Соглашения по именованию

```dart
// Интерфейсы скоупов
abstract class FeatureScope implements Scope { /* ... */ }

// Контейнеры скоупов
class FeatureScopeContainer extends ScopeContainer implements FeatureScope { /* ... */ }

// Холдеры скоупов
class FeatureScopeHolder extends BaseScopeHolder<FeatureScope, FeatureScopeContainer> { /* ... */ }

// Parent интерфейсы
abstract class FeatureScopeParent implements Scope { /* ... */ }

// Модули
class FeatureNetworkModule extends ScopeModule<FeatureScopeContainer> { /* ... */ }

// Зависимости
late final featureManagerDep = dep(() => FeatureManager());  // Суффикс Dep
```

#### Разделение ответственности

```dart
// DI слой — только сборка зависимостей
abstract class OrderScope implements Scope {
  OrderManager get orderManager;
  PaymentProcessor get paymentProcessor;
}

// Доменный слой — бизнес-логика
class OrderManager {
  final OrderRepository _orderRepository;
  final NotificationService _notificationService;
  
  OrderManager(this._orderRepository, this._notificationService);
  
  Future<void> processOrder(Order order) async {
    // Бизнес-логика без знания о DI
  }
}

// UI слой — представление
class OrderWidget extends StatelessWidget {
  final OrderScope orderScope;
  
  const OrderWidget({required this.orderScope, super.key});
  
  @override
  Widget build(BuildContext context) {
    // UI логика без знания о DI
    return StreamBuilder<OrderStatus>(
      stream: orderScope.orderManager.statusStream,
      builder: (context, snapshot) => OrderStatusWidget(snapshot.data),
    );
  }
}
```

### Использование линтера

#### Подключение и настройка

```yaml
# pubspec.yaml
dev_dependencies:
  yx_scope_linter: ^1.0.0
  custom_lint: ^0.5.3

# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - consider_dep_suffix      # Проверка суффикса Dep
    - final_dep               # Проверка late final для зависимостей
    - dep_cycle               # Обнаружение циклических зависимостей
```

#### Ключевые правила линтера

**1. `consider_dep_suffix`** — зависимости должны заканчиваться на `Dep`:

```dart
// ПЛОХО
late final userManager = dep(() => UserManager());

// ХОРОШО
late final userManagerDep = dep(() => UserManager());
```

**2. `final_dep`** — зависимости должны быть `late final`:

```dart
// ПЛОХО
final userManagerDep = dep(() => UserManager());
var userManagerDep = dep(() => UserManager());

// ХОРОШО
late final userManagerDep = dep(() => UserManager());
```

**3. `dep_cycle`** — обнаружение циклических зависимостей:

```dart
// ПЛОХО — циклическая зависимость
late final serviceADep = dep(() => ServiceA(serviceBDep.get));
late final serviceBDep = dep(() => ServiceB(serviceADep.get));  // Цикл!

// ХОРОШО — разрыв цикла через интерфейс или рефакторинг
late final serviceADep = dep(() => ServiceA());
late final serviceBDep = dep(() => ServiceB(serviceADep.get));
```

---

## Частые сценарии

### Factory pattern через скоупы

Когда нужно создавать множественные экземпляры с одинаковой логикой:

```dart
// Фабрика для создания скоупов документов
class DocumentScopeFactory {
  final AppScope _appScope;
  
  DocumentScopeFactory(this._appScope);

  DocumentScopeHolder createDocumentScope() {
    return DocumentScopeHolder(_appScope);
  }
}

// Менеджер документов
class DocumentManager {
  final DocumentScopeFactory _factory;
  final Map<String, DocumentScopeHolder> _openDocuments = {};
  
  DocumentManager(this._factory);

  Future<void> openDocument(String documentId, DocumentData data) async {
    final scopeHolder = _factory.createDocumentScope();
    await scopeHolder.create(data);
    _openDocuments[documentId] = scopeHolder;
  }

  Future<void> closeDocument(String documentId) async {
    final scopeHolder = _openDocuments.remove(documentId);
    await scopeHolder?.drop();
  }

  DocumentScope? getDocumentScope(String documentId) {
    return _openDocuments[documentId]?.scope;
  }
}
```

### Условная инициализация

Когда нужно инициализировать зависимости только при определенных условиях:

```dart
class ConditionalScopeContainer extends ScopeContainer implements ConditionalScope {
  final bool shouldInitializeFeatureA;
  final bool shouldInitializeFeatureB;
  
  ConditionalScopeContainer({
    required this.shouldInitializeFeatureA,
    required this.shouldInitializeFeatureB,
  });

  @override
  List<Set<AsyncDep>> get initializeQueue {
    final queue = <Set<AsyncDep>>[];
    
    // Базовые зависимости всегда инициализируются
    queue.add({coreServiceDep});
    
    // Условная инициализация
    final conditionalDeps = <AsyncDep>{};
    if (shouldInitializeFeatureA) {
      conditionalDeps.add(featureAServiceDep);
    }
    if (shouldInitializeFeatureB) {
      conditionalDeps.add(featureBServiceDep);
    }
    
    if (conditionalDeps.isNotEmpty) {
      queue.add(conditionalDeps);
    }
    
    return queue;
  }

  late final coreServiceDep = asyncDep(() => CoreService());
  
  late final featureAServiceDep = asyncDep(() => FeatureAService());
  
  late final featureBServiceDep = asyncDep(() => FeatureBService());

  @override
  CoreService get coreService => coreServiceDep.get;

  @override
  FeatureAService? get featureAService => 
      shouldInitializeFeatureA ? featureAServiceDep.get : null;

  @override
  FeatureBService? get featureBService => 
      shouldInitializeFeatureB ? featureBServiceDep.get : null;
}
```

### Навигационные скоупы

Скоупы, связанные с навигацией и жизненным циклом экранов:

```dart
// Скоуп для экрана с навигационным состоянием
class ScreenScopeContainer extends DataScopeContainer<ScreenParams> 
    implements ScreenScope {
  ScreenScopeContainer({required super.data});

  late final navigationStateDep = dep(() => NavigationState(data.initialRoute));
  late final screenManagerDep = dep(() => ScreenManager(
    data,
    navigationStateDep.get,
  ));

  @override
  NavigationState get navigationState => navigationStateDep.get;

  @override
  ScreenManager get screenManager => screenManagerDep.get;
}

// Интеграция с Flutter Router
class ScreenPageWrapper extends StatefulWidget {
  final ScreenParams params;
  
  const ScreenPageWrapper({required this.params, super.key});

  @override
  State<ScreenPageWrapper> createState() => _ScreenPageWrapperState();
}

class _ScreenPageWrapperState extends State<ScreenPageWrapper> {
  late final ScreenScopeHolder _scopeHolder;

  @override
  void initState() {
    super.initState();
    _scopeHolder = ScreenScopeHolder();
    _scopeHolder.create(widget.params);
  }

  @override
  void dispose() {
    _scopeHolder.drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopeProvider<ScreenScope>(
      holder: _scopeHolder,
      child: ScopeBuilder<ScreenScope>.withPlaceholder(
        builder: (context, scope) => ScreenContent(scope: scope),
        placeholder: const ScreenLoadingWidget(),
      ),
    );
  }
}
```

### Тестирование скоупов

#### Unit тестирование контейнеров

```dart
void main() {
  group('UserScopeContainer', () {
    late UserScopeContainer container;
    late MockAppScope mockAppScope;

    setUp(() {
      mockAppScope = MockAppScope();
      container = UserScopeContainer(parent: mockAppScope, data: testUser);
    });

    tearDown(() async {
      await container.dispose();
    });

    test('should provide user manager', () {
      final userManager = container.userManager;
      expect(userManager, isNotNull);
      expect(userManager.user, equals(testUser));
    });

    test('should initialize async dependencies', () async {
      await container.init();
      
      final asyncService = container.asyncService;
      expect(asyncService.isInitialized, isTrue);
    });
  });
}
```

#### Integration тестирование с Flutter

```dart
void main() {
  group('UserScope Integration', () {
    testWidgets('should display user info when scope is ready', (tester) async {
      final mockAppScope = MockAppScope();
      final userScopeHolder = UserScopeHolder(mockAppScope);
      
      await userScopeHolder.create(testUser);

      await tester.pumpWidget(
        MaterialApp(
          home: ScopeProvider<UserScope>(
            holder: userScopeHolder,
            child: const UserProfileWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(testUser.name), findsOneWidget);
      expect(find.text(testUser.email), findsOneWidget);
      
      await userScopeHolder.drop();
    });

    testWidgets('should show placeholder when scope is null', (tester) async {
      final userScopeHolder = UserScopeHolder(MockAppScope());
      // НЕ создаем скоуп

      await tester.pumpWidget(
        MaterialApp(
          home: ScopeProvider<UserScope>(
            holder: userScopeHolder,
            child: ScopeBuilder<UserScope>.withPlaceholder(
              builder: (context, scope) => const UserProfileWidget(),
              placeholder: const Text('Loading...'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });
  });
}
```

---

## Reference

### Полный API Overview

#### Core классы

**ScopeContainer**

- `dep<T>(T Function() factory)` — синхронная зависимость
- `asyncDep<T>(T Function() factory)` — асинхронная зависимость с `AsyncLifecycle`
- `rawAsyncDep<T>(...)` — асинхронная зависимость с кастомными `init`/`dispose`
- `List<Set<AsyncDep>> get initializeQueue` — порядок инициализации асинхронных зависимостей

**ScopeHolder/BaseScopeHolder**

- `Future<void> create()` — создание скоупа
- `Future<void> drop()` — закрытие скоупа
- `T? get scope` — синхронный доступ к скоупу
- `Stream<T?> get stream` — реактивная подписка на изменения

**Специализированные контейнеры**

- `ChildScopeContainer<Parent>` — дочерний скоуп
- `DataScopeContainer<Data>` — скоуп с данными
- `ChildDataScopeContainer<Parent, Data>` — комбинированный скоуп

**Специализированные холдеры**

- `BaseChildScopeHolder<Scope, Container, Parent>`
- `BaseDataScopeHolder<Scope, Container, Data>`
- `BaseChildDataScopeHolder<Scope, Container, Parent, Data>`

#### Flutter интеграция

**ScopeProvider**

- `ScopeProvider<T>({required holder, required child})`
- `ScopeProvider.of<T>(context)` — получение холдера из контекста

**ScopeBuilder**

- `ScopeBuilder<T>({required builder, holder?})`
- `ScopeBuilder<T>.withPlaceholder({required builder, placeholder, holder?})`

**ScopeListener**

- `ScopeListener<T>({required listener, required child, holder?})`

### Типичные ошибки и решения

#### 1. Обращение к закрытому скоупу

```dart
// ОШИБКА
void badMethod(ScopeHolder holder) async {
  final scope = holder.scope;
  if (scope != null) {
    await someAsyncOperation();
    scope.service.doWork();  // Скоуп может быть уже закрыт!
  }
}

// РЕШЕНИЕ
void goodMethod(ScopeHolder holder) async {
  await someAsyncOperation();
  final scope = holder.scope;  // Проверяем после async операции
  if (scope != null) {
    scope.service.doWork();
  }
}
```

#### 2. Циклические зависимости

```dart
// ОШИБКА
late final serviceADep = dep(() => ServiceA(serviceBDep.get));
late final serviceBDep = dep(() => ServiceB(serviceADep.get));

// РЕШЕНИЕ — через интерфейс
late final serviceADep = dep(() => ServiceA());
late final serviceBDep = dep(() => ServiceB(serviceADep.get));
// или рефакторинг архитектуры
```

#### 3. Неправильная инициализация асинхронных зависимостей

```dart
// ОШИБКА — не указаны в initializeQueue
class BadScopeContainer extends ScopeContainer {
  late final asyncServiceDep = asyncDep(() => AsyncService());
  // initializeQueue не переопределен — зависимость не инициализируется!
}

// РЕШЕНИЕ
class GoodScopeContainer extends ScopeContainer {
  @override
  List<Set<AsyncDep>> get initializeQueue => [
    {asyncServiceDep}
  ];

  late final asyncServiceDep = asyncDep(() => AsyncService());
}
```

### Performance considerations

#### 1. Ленивая инициализация

Зависимости создаются только при первом обращении. Это экономит ресурсы, но может привести к задержкам:

```dart
// При необходимости можно принудительно инициализировать
void preloadCriticalServices(AppScope scope) {
  // Обращение к критически важным сервисам для их создания
  final _ = scope.criticalService;
  final _ = scope.anotherCriticalService;
}
```

#### 2. Оптимизация initializeQueue

Группируйте независимые зависимости для параллельной инициализации:

```dart
@override
List<Set<AsyncDep>> get initializeQueue => [
  // Параллельная инициализация независимых сервисов
  {configServiceDep, loggerServiceDep, metricsServiceDep},
  // Последовательная инициализация зависимых сервисов
  {databaseServiceDep},
  {repositoryServiceDep},
];
```

#### 3. Избегание излишних скоупов

Не создавайте скоуп для каждой сущности — группируйте по жизненному циклу:

```dart
// ПЛОХО — слишком много скоупов
class UserScopeContainer extends ScopeContainer { /* ... */ }
class UserPreferencesScopeContainer extends ScopeContainer { /* ... */ }
class UserNotificationsScopeContainer extends ScopeContainer { /* ... */ }

// ХОРОШО — один скоуп с модулями
class UserScopeContainer extends ScopeContainer {
  late final preferencesModule = UserPreferencesModule(this);
  late final notificationsModule = UserNotificationsModule(this);
}
```

---

## Заключение

yx\_scope предоставляет мощный и гибкий инструментарий для управления зависимостями в Dart/Flutter приложениях. Ключевые преимущества библиотеки:

- **Compile-time safety** — большинство ошибок выявляются на этапе компиляции
- **Прозрачность** — детерминированное и предсказуемое поведение
- **Масштабируемость** — от простых приложений до сложных enterprise решений
- **Flutter-friendly** — естественная интеграция с виджетной архитектурой

**Основные принципы для успешного использования:**

1. **Проектируйте скоупы по бизнес-процессам**, а не по UI
2. **Используйте интерфейсы** для снижения связанности
3. **Следуйте правилу одинакового жизненного цикла** при создании скоупов
4. **Используйте линтер** для предотвращения типичных ошибок
5. **Тестируйте скоупы** как обычные классы

yx\_scope позволяет создавать чистую, поддерживаемую и масштабируемую архитектуру, где управление зависимостями становится естественной частью разработки, а не препятствием.

---

**Полезные ссылки:**

- [GitHub репозиторий](https://github.com/yandex/yx_scope)
- [Пример приложения](https://github.com/yandex/yx_scope/tree/main/packages/yx_scope_flutter/example)
- [Документация yx\_scope](https://pub.dev/packages/yx_scope)
- [Документация yx\_scope\_flutter](https://pub.dev/packages/yx_scope_flutter)
- [yx\_scope\_linter](https://pub.dev/packages/yx_scope_linter)