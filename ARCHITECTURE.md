# Architecture

Feature-first **Clean Architecture** with **MVVM** in the presentation layer.

```
Widget (View) ──watch/read──► ViewModel (Riverpod Notifier) ──► Use case ──► Repository (contract)
                                                                                 ▲
                                                Repository impl (data) ──► Remote / Mock data source ──► DioClient
```

Dependencies always point inwards: **presentation → domain ← data**. The domain layer has no
Flutter imports and only uses `equatable` for value equality (pure Dart).

## Folders

```
lib/
├── main.dart                 # calls bootstrap()
├── app/
│   ├── app.dart              # MaterialApp.router, theme, locale/RTL
│   ├── bootstrap.dart        # zone guard, SharedPreferences, ProviderScope overrides
│   ├── config/               # Environment + AppConfig (--dart-define)
│   ├── di/injection.dart     # ALL infrastructure, data sources, repositories, use cases
│   └── router/               # GoRouter, route names/paths, auth redirect
├── core/
│   ├── base/                 # ViewState, SubmitState, ViewStateBuilder
│   ├── errors/               # Failure (sealed), Result<T>, ErrorMapper
│   ├── exceptions/           # AppException (data-layer)
│   ├── logging/              # AppLogger (no-op in release)
│   ├── network/              # DioClient, interceptors, endpoints, SessionEvents
│   ├── storage/              # SecureStorage, PreferencesStorage, TokenStorage
│   └── utils/                # Validators, Money, JsonReader, DateFormatter
├── design_system/            # tokens, theme, components, asset paths
├── features/
│   ├── address/  app_settings/  auth/  cart/  catalog/  checkout/
│   ├── home/  onboarding/  orders/  profile/  services/  splash/
│   │   ├── data/        datasources/ models/ repositories/
│   │   ├── domain/      entities/ repositories/ usecases/
│   │   └── presentation/ pages/ widgets/ viewmodels/
└── shared/widgets/           # MainShell (bottom nav), NotFoundPage, CategoryVisuals
```

Not every feature needs every layer: `home`, `profile`, `splash` and `onboarding` are
presentation-only and reuse other features' domain contracts; `cart` is pure client state
(domain entity + ViewModel, no repository).

## Key decisions

| Decision | Why |
|----------|-----|
| **Riverpod 3 as both state management and DI** | One mechanism for object creation, lifetime and test overrides. `get_it` would duplicate it. |
| **Hand-written models instead of Freezed / json_serializable** | Keeps the build free of code generation (no stale `.g.dart` files, faster CI). `JsonReader` gives type-safe parsing. Add Freezed later if models grow — the layer boundaries don't change. |
| **`Result<T>` instead of throwing** | Errors are part of the type. Repositories never throw; ViewModels pattern-match. |
| **Mock data sources behind the same interface** | The app is fully usable before the backend exists (`USE_MOCK_API=true`). |
| **Money in minor units** | No floating-point rounding errors in totals. |
| **`SessionEvents` stream** | The network layer can signal "session expired" without depending on the auth feature. |

## State

- Screen state is immutable (`Equatable`) — `ViewState<T>` for loading data, `SubmitState` for actions.
- Screen ViewModels use `NotifierProvider.autoDispose`, so they are freed when the screen closes.
- App-wide state (`sessionProvider`, `cartProvider`, `addressesProvider`, `languageProvider`,
  `favoritesProvider`) is kept alive and resets itself when the signed-in user changes.

## How to add a feature

1. Create `lib/features/<name>/{domain,data,presentation}`.
2. **Domain** — entities (`final class … extends Equatable`), a repository contract
   (`abstract interface class`), use cases (one public `call`).
3. **Data** — a remote data source (interface + `DioClient` impl + mock), a mapper, and the
   repository impl that wraps calls in `ErrorMapper.guard`.
4. **Register** everything in `app/di/injection.dart`.
5. **Presentation** — ViewModel + provider, page, widgets. Add the route in `app_router.dart`.
6. Add tests (see TESTING.md).

### Example: a ViewModel

```dart
final class WalletViewModel extends Notifier<ViewState<Wallet>> {
  @override
  ViewState<Wallet> build() {
    Future.microtask(load);
    return const ViewLoading();
  }

  Future<void> load() async {
    final result = await ref.read(getWalletProvider).call();
    if (!ref.mounted) return;               // screen closed while loading
    state = result.when(
      success: (w) => ViewSuccess(w),
      failure: (f) => ViewFailure(f),
    );
  }
}

final walletViewModelProvider =
    NotifierProvider.autoDispose<WalletViewModel, ViewState<Wallet>>(WalletViewModel.new);
```

In the page: `ViewStateBuilder(state: ref.watch(walletViewModelProvider), onRetry: …, builder: …)`.

### Example: a repository + registration

```dart
// domain
abstract interface class WalletRepository { Future<Result<Wallet>> getWallet(); }

// data
final class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._remote);
  final WalletRemoteDataSource _remote;
  @override
  Future<Result<Wallet>> getWallet() => ErrorMapper.guard(_remote.wallet);
}

// app/di/injection.dart
final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>(
  (ref) => _useMock(ref) ? const WalletMockDataSource() : WalletRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);
final walletRepositoryProvider =
    Provider<WalletRepository>((ref) => WalletRepositoryImpl(ref.watch(walletRemoteDataSourceProvider)));
final getWalletProvider = Provider((ref) => GetWallet(ref.watch(walletRepositoryProvider)));
```

## Navigation

`app/router/app_router.dart` — a `StatefulShellRoute` holds the four tabs (Home, Explore,
Orders, Profile). Detail screens (`/store/:storeId`, `/product/:productId`, `/checkout`, profile
sub-pages) open on the root navigator above the bottom bar. `authRedirect` (pure, unit-tested)
keeps signed-out users on public routes and signed-in users off the auth screens; the router
re-evaluates whenever `sessionProvider` changes. Unknown routes show `NotFoundPage`.

Navigate by name: `context.pushNamed(RouteNames.storeDetail, pathParameters: {RouteParams.storeId: id})`.

## Encapsulation rules

- Private (`_`) for everything not used outside its library; widgets' sub-parts are private classes.
- `final class` by default; `abstract interface class` for contracts; `sealed` for closed hierarchies.
- Data sources and DTOs are never imported by presentation code.
