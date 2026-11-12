import 'package:flutter/material.dart';

import '../../design_system/tokens/tokens.dart';
import '../../features/catalog/domain/entities/catalog_entities.dart';

/// Maps domain category keys / tints to Material icons and colour tokens.
abstract final class CategoryVisuals {
  static const Map<String, IconData> _icons = {
    'food': Icons.restaurant_rounded,
    'grocery': Icons.shopping_cart_outlined,
    'pharmacy': Icons.medical_services_outlined,
    'flowers': Icons.local_florist_outlined,
    'pets': Icons.pets_rounded,
    'bakery': Icons.bakery_dining_outlined,
    'drinks': Icons.local_bar_outlined,
    'gifts': Icons.card_giftcard_rounded,
    'household': Icons.house_outlined,
    'essentials': Icons.inventory_2_outlined,
    'electronics': Icons.devices_other_outlined,
    'home_decor': Icons.chair_outlined,
    'toys': Icons.toys_outlined,
    'sports': Icons.sports_basketball_outlined,
    'healthcare': Icons.healing_outlined,
    'books': Icons.menu_book_outlined,
    'hardware': Icons.handyman_outlined,
    'beauty': Icons.spa_outlined,
    'stationery': Icons.edit_outlined,
    'laundry': Icons.local_laundry_service_outlined,
    'baby': Icons.child_friendly_outlined,
    'party': Icons.celebration_outlined,
    'garden': Icons.yard_outlined,
    'office': Icons.business_center_outlined,
    'meat': Icons.set_meal_outlined,
    'organic': Icons.eco_outlined,
    'dessert': Icons.icecream_outlined,
    'coffee': Icons.local_cafe_outlined,
    'tailor': Icons.checkroom_outlined,
    'shoe': Icons.do_not_step_outlined,
    'key': Icons.key_outlined,
    'photo': Icons.photo_camera_outlined,
    'fitness': Icons.fitness_center_outlined,
    'yoga': Icons.self_improvement_outlined,
    'auto': Icons.car_repair_outlined,
    'car_wash': Icons.local_car_wash_outlined,
    'bike': Icons.pedal_bike_outlined,
    'music': Icons.music_note_outlined,
    'art': Icons.palette_outlined,
    'cleaning': Icons.cleaning_services_outlined,
    'electrician': Icons.electrical_services_outlined,
    'plumber': Icons.plumbing_outlined,
  };

  static IconData icon(String key) => _icons[key] ?? Icons.storefront_outlined;

  static ({Color background, Color foreground}) colors(CategoryTint tint) => switch (tint) {
        CategoryTint.red => (background: AppColors.tintRed, foreground: AppColors.tintRedIcon),
        CategoryTint.green => (background: AppColors.tintGreen, foreground: AppColors.tintGreenIcon),
        CategoryTint.yellow => (background: AppColors.tintYellow, foreground: AppColors.tintYellowIcon),
        CategoryTint.blue => (background: AppColors.tintBlue, foreground: AppColors.tintBlueIcon),
        CategoryTint.purple => (background: AppColors.tintPurple, foreground: AppColors.tintPurpleIcon),
      };
}
