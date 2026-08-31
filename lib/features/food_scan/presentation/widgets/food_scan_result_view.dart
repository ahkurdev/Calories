import 'package:caloris/features/food_scan/domain/food_scan_models.dart';
import 'package:flutter/material.dart';

class FoodScanResultView extends StatelessWidget {
  const FoodScanResultView({
    required this.result,
    required this.onEdit,
    required this.onRemove,
    required this.onAdd,
    super.key,
  });

  final FoodScanResult result;
  final ValueChanged<ScannedFoodItem> onEdit;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.auto_awesome_outlined),
          const SizedBox(width: 10),
          Text(
            'Estimasi AI',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Kalori diperkirakan berdasarkan foto dan ukuran porsi. Nilai sebenarnya dapat berbeda.',
      ),
      if (result.isDevelopmentMock) ...[
        const SizedBox(height: 10),
        const Chip(
          avatar: Icon(Icons.science_outlined),
          label: Text('MODE MOCK DEVELOPMENT — bukan AI nyata'),
        ),
      ],
      const SizedBox(height: 14),
      if (result.foods.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(result.notes),
          ),
        )
      else
        ...result.foods.map(
          (food) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
              title: Text(food.name),
              subtitle: Text(
                '${food.amount.toStringAsFixed(0)} ${food.unit.label} • ${food.calories.toStringAsFixed(0)} kcal • confidence ${(food.confidence * 100).round()}%',
              ),
              onTap: () => onEdit(food),
              trailing: IconButton(
                tooltip: 'Hapus komponen',
                onPressed: () => onRemove(food.id),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          ),
        ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Text(
              'Total ${result.totalEstimatedCalories.toStringAsFixed(0)} kcal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah komponen'),
          ),
        ],
      ),
      if (result.notes.isNotEmpty && result.foods.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(result.notes, style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );
}
