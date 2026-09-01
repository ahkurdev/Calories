import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/presentation/controllers/food_diary_controller.dart';
import 'package:caloris/shared/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class FoodDiaryPage extends ConsumerWidget {
  const FoodDiaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDiaryDateProvider);
    final diary = ref.watch(foodDiaryControllerProvider);
    final pendingMutations = ref.watch(pendingFoodMutationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary makanan'),
        actions: [
          IconButton(
            tooltip: 'Pilih tanggal',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _pickDate(context, ref, selectedDate),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/diary'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/food/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(foodDiaryControllerProvider);
          ref.invalidate(pendingFoodMutationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(selectedDate),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (pendingMutations.value case final count? when count > 0) ...[
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.sync_outlined),
                  title: Text('$count perubahan menunggu sinkronisasi'),
                  subtitle: const Text(
                    'Catatan tersimpan di perangkat dan akan dicoba lagi saat layanan tersedia.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Tambahkan lagi'),
                  onPressed: diary.value?.isNotEmpty == true
                      ? () => ref
                            .read(foodDiaryControllerProvider.notifier)
                            .addAgain(diary.value!.last)
                      : null,
                ),
                ActionChip(
                  avatar: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('Dari kemarin'),
                  onPressed: diary.isLoading
                      ? null
                      : () => _copyYesterday(context, ref),
                ),
                ActionChip(
                  avatar: const Icon(Icons.favorite_outline_rounded, size: 18),
                  label: const Text('Dari favorit'),
                  onPressed: () => context.push('/favorites'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.restaurant_menu_rounded, size: 18),
                  label: const Text('Susun makanan'),
                  onPressed: () => context.push('/meal-builder'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            diary.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _DiaryError(
                message: error.toString(),
                onRetry: () => ref.invalidate(foodDiaryControllerProvider),
              ),
              data: (logs) => logs.isEmpty
                  ? const _EmptyDiary()
                  : Column(
                      children: MealType.values
                          .map(
                            (mealType) => _MealSection(
                              mealType: mealType,
                              logs: logs
                                  .where((log) => log.mealType == mealType)
                                  .toList(growable: false),
                              onAdd: () => context.push(
                                '/food/new?meal=${mealType.databaseValue}',
                              ),
                              onDelete: (id) => ref
                                  .read(foodDiaryControllerProvider.notifier)
                                  .delete(id),
                              onAddAgain: (food) => ref
                                  .read(foodDiaryControllerProvider.notifier)
                                  .addAgain(food),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime selected,
  ) async {
    final result = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (result != null) {
      ref.read(selectedDiaryDateProvider.notifier).select(result);
    }
  }

  Future<void> _copyYesterday(BuildContext context, WidgetRef ref) async {
    final count = await ref
        .read(foodDiaryControllerProvider.notifier)
        .copyFromYesterday();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Tidak ada makanan kemarin untuk disalin.'
                : '$count makanan ditambahkan dari kemarin.',
          ),
        ),
      );
    }
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.mealType,
    required this.logs,
    required this.onAdd,
    required this.onDelete,
    required this.onAddAgain,
  });

  final MealType mealType;
  final List<FoodLog> logs;
  final VoidCallback onAdd;
  final Future<bool> Function(String id) onDelete;
  final Future<bool> Function(FoodLog food) onAddAgain;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mealType.label,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${logs.fold<double>(0, (sum, item) => sum + item.calories).round()} kcal',
              ),
              IconButton(
                tooltip: 'Tambah ${mealType.label}',
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          if (logs.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Belum ada catatan.'),
              ),
            )
          else
            ...logs.map(
              (food) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(food.foodName),
                subtitle: Text(
                  '${food.amount == food.amount.roundToDouble() ? food.amount.toInt() : food.amount.toStringAsFixed(1)} ${food.unit.label}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${food.calories.round()} kcal'),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'again') onAddAgain(food);
                        if (value == 'delete') onDelete(food.id);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'again',
                          child: Text('Tambahkan lagi'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        Icon(Icons.restaurant_outlined, size: 56),
        SizedBox(height: 12),
        Text('Belum ada makanan pada hari ini.'),
      ],
    ),
  );
}

class _DiaryError extends StatelessWidget {
  const _DiaryError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
}
