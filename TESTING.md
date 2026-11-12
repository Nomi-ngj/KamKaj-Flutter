# Testing

```bash
flutter test --exclude-tags widget     # unit tests
flutter test --tags widget             # widget tests
flutter test --coverage                # everything + coverage/lcov.info
flutter test integration_test          # critical journey on a device/simulator
```

## Layout

```
test/
├── helpers/test_helpers.dart     # createTestContainer(), pumpApp(), InMemorySecureStorage
├── app/auth_redirect_test.dart   # router guard rules
├── core/                         # Validators, Money, ErrorMapper
├── design_system/                # component widget tests (tag: widget)
└── features/
    ├── auth/        use cases (mocktail), repository impl, SignIn ViewModel, Sign In page
    ├── catalog/     GetDashboard / SearchCategories, Dashboard page
    ├── cart/        Cart business rules
    ├── checkout/    pricing rules
    ├── address/     SaveAddress validation, default ordering, add flow
    └── orders/      PlaceOrder validation, OrdersViewModel, My Orders page
integration_test/app_flow_test.dart   # sign in → store → basket → checkout → orders
```

## Patterns

**Use case / repository** — mock the contract with Mocktail:

```dart
class _MockAuthRepository extends Mock implements AuthRepository {}

when(() => repo.signIn(email: any(named: 'email'), password: any(named: 'password')))
    .thenAnswer((_) async => const Result.success(user));
```

**ViewModel** — use the real graph with zero-latency mocks:

```dart
final container = await createTestContainer();
final sub = container.listen(ordersViewModelProvider, (_, _) {}); // keep autoDispose alive
addTearDown(sub.close);
await container.read(ordersViewModelProvider.notifier).refresh();
```

**Widget** — `pumpApp(tester, const MyOrdersPage(), container: container)` then
`pumpAndSettle()`. Widget test files start with `@Tags(['widget'])` so CI can run them separately.

## What is (and isn't) covered

Covered: validation, money maths, error mapping, token storage on sign-in/out, session expiry,
reset-token flow, dashboard partial failures, cart rules, pricing, address default ordering,
order payment, router guards, key components, Sign In / Dashboard / My Orders screens.

Not yet: golden (pixel) tests — add them once the Figma images are exported, so goldens include
real artwork.
