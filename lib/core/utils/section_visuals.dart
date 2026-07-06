import 'package:flutter/material.dart';

class SectionVisuals {
  static IconData iconFor(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('hort')) return Icons.eco_outlined;
    if (normalized.contains('açou') || normalized.contains('acou')) {
      return Icons.set_meal_outlined;
    }
    if (normalized.contains('pad')) return Icons.bakery_dining_outlined;
    if (normalized.contains('frio')) return Icons.kitchen_outlined;
    if (normalized.contains('limp')) return Icons.cleaning_services_outlined;
    if (normalized.contains('hig')) return Icons.spa_outlined;
    if (normalized.contains('beb')) return Icons.local_drink_outlined;
    if (normalized.contains('cong')) return Icons.ac_unit_outlined;
    if (normalized.contains('merce')) return Icons.inventory_2_outlined;
    return Icons.category_outlined;
  }

  static Color colorFor(BuildContext context, String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('hort')) return Colors.green.shade700;
    if (normalized.contains('açou') || normalized.contains('acou')) {
      return Colors.red.shade700;
    }
    if (normalized.contains('pad')) return Colors.amber.shade800;
    if (normalized.contains('frio')) return Colors.indigo.shade600;
    if (normalized.contains('limp')) return Colors.blue.shade700;
    if (normalized.contains('hig')) return Colors.cyan.shade700;
    if (normalized.contains('beb')) return Colors.teal.shade700;
    if (normalized.contains('cong')) return Colors.lightBlue.shade700;
    if (normalized.contains('merce')) return Colors.deepOrange.shade700;
    return Theme.of(context).colorScheme.primary;
  }
}
