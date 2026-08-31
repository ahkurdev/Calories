import 'package:caloris/features/food_scan/presentation/controllers/food_scan_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ScanHistoryPage extends ConsumerWidget {
  const ScanHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scanHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Scan')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(scanHistoryProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada riwayat scan.'))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        item.imagePath == null
                            ? Icons.no_photography_outlined
                            : Icons.image_outlined,
                      ),
                      title: Text(
                        '${item.result.totalEstimatedCalories.toStringAsFixed(0)} kcal',
                      ),
                      subtitle: Text(
                        '${item.result.foods.map((food) => food.name).join(', ')}\n${DateFormat('d MMM yyyy, HH:mm').format(item.scannedAt.toLocal())}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
