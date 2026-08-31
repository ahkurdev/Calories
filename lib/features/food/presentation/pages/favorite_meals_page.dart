import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/presentation/controllers/food_diary_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteMealsPage extends ConsumerWidget {
  const FavoriteMealsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteMealsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Makanan favorit')),
      body: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada menu favorit.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final meal = items[index];
                  final calories = meal.items.fold<double>(
                    0,
                    (sum, item) => sum + item.calories,
                  );
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(meal.name),
                      subtitle: Text(
                        '${meal.items.length} komponen • ${calories.round()} kcal',
                      ),
                      trailing: const Icon(Icons.add_circle_outline_rounded),
                      onTap: () => _addFavorite(context, ref, meal),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _addFavorite(
    BuildContext context,
    WidgetRef ref,
    FavoriteMeal meal,
  ) async {
    final mealType = await showDialog<MealType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Tambahkan sebagai'),
        children: MealType.values
            .map(
              (type) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, type),
                child: Text(type.label),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (mealType == null) return;
    final success = await ref
        .read(foodDiaryControllerProvider.notifier)
        .addFavorite(meal, mealType);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Menu favorit ditambahkan.'
                : 'Menu belum dapat ditambahkan.',
          ),
        ),
      );
    }
  }
}
