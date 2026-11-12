# Design System

Everything visual comes from `lib/design_system/`. Screens never hard-code colours, font sizes,
spacing or radii — change a token and every screen follows.

```dart
import 'package:kamkaj_pro/design_system/tokens/tokens.dart';
import 'package:kamkaj_pro/design_system/components/components.dart';
```

## Tokens

| File | Contents |
|------|----------|
| `app_colors.dart` | Figma variables (`primary #205695`, `secondary #F97316`, `gray #555555`), backgrounds (`backgroundWarm` for auth, `background` for shop), text, borders, status (success/warning/info/error + soft & border tints), category tints, overlay/scrim |
| `app_typography.dart` | Poppins styles from Figma: `header2` 24/700, `subhead` 17/600, `callout` 16/400, `caption1` 14/400, `caption1Medium` 14/500, `caption4Medium` 10/500, plus `titleMedium`, `caption2*`, `button`, `label`, `overline`. All use −2 % letter spacing |
| `app_spacing.dart` | 4-pt scale `xxs 2 … giant 64`; `page` 20 (shop), `pageAuth` 37.5 (auth) |
| `app_radius.dart` | `xs 4, sm 8, md 12, lg 16, xl 24, pill`, plus `BorderRadius` constants |
| `app_shadows.dart` | `field`, `card`, `floating`, `topBar` |
| `app_dimensions.dart` | Measured sizes: button 47 / 58, input 56, icon sizes, card/media sizes |
| `app_durations.dart` | Animation durations, OTP resend 60 s, search debounce; `AppBreakpoints` |

Poppins is bundled in `assets/fonts/` (OFL licence included), so text renders the same offline
and in tests.

## Components

| Component | Use |
|-----------|-----|
| `AppButton` | `primary` (blue), `secondary` (orange), `outline`, `text`; `size: large`; `isLoading`; icons |
| `AppTextField` | `warm` (auth) or `outlined` (forms); `isPassword` adds the eye toggle |
| `AppOtpField` | 6-box code input with paste & backspace handling |
| `AppText` | Text bound to a typography variant (`AppText.header`, `AppText.subtitle`) |
| `AppCard` | White rounded card with shadow & ink |
| `AppAppBar`, `AppBackButton`, `AppMoreButton` | Back + title + actions (RTL aware) |
| `AppNetworkImage`, `AppAssetImage` | Cached / bundled images with placeholders |
| `AppLoader`, `AppErrorView`, `AppEmptyView` | Loading / error (with retry) / empty states |
| `AppDialog.confirm`, `AppBottomSheet.show`, `AppToast.show` | Overlays |
| `AppRatingChip`, `AppChoiceChip`, `AppTag`, `AppStatusBadge` | Chips & badges |
| `AppSectionHeader`, `AppPageDots`, `AppQuantityStepper`, `AppCircleIconButton`, `AppResponsiveCenter` | Layout helpers |
| `ViewStateBuilder` (core/base) | Renders `ViewState` → loader / content / empty / error / offline |

### Example

```dart
AppButton(
  label: 'Place Order',
  trailingIcon: Icons.arrow_forward_rounded,
  variant: AppButtonVariant.secondary,
  size: AppButtonSize.large,
  isLoading: state.submit.isSubmitting,
  onPressed: state.canPlaceOrder ? _placeOrder : null,
);

Padding(
  padding: const EdgeInsets.all(AppSpacing.page),
  child: Text('Fresh Today', style: AppTypography.subhead),
);
```

## Rules

- `AppTypography` styles are `final`, so a `Text` using them can't be `const` — that's expected.
- Need a new value? Add a token first, then use it.
- Accessibility: buttons and chips set `Semantics`; text scaling is respected up to 1.3×;
  RTL (Arabic, Urdu) flips icons and `Directional` paddings.
- Dark mode is not designed; `dark_theme.dart` mirrors light until it is.
