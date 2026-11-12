/// Bundled image paths. Export these from Figma (see FIGMA_ANALYSIS.md §6).
/// Missing files fall back to a placeholder, so the app runs before export.
abstract final class AppImages {
  static const _base = 'assets/images';

  static const splashBackground = '$_base/splash_background.png';
  static const appLogo = '$_base/app_logo.png';
  static const onboarding1 = '$_base/onboarding_1.png';
  static const onboarding2 = '$_base/onboarding_2.png';
  static const onboarding3 = '$_base/onboarding_3.png';
  static const mapPlaceholder = '$_base/map_placeholder.png';
  static const serviceExpressRide = '$_base/service_express_ride.png';
  static const serviceDeliveryPackage = '$_base/service_delivery_package.png';
  static const vehicleSedan = '$_base/vehicle_sedan.png';
  static const vehicleVan = '$_base/vehicle_van.png';
  static const vehicleTruck = '$_base/vehicle_truck.png';
}
