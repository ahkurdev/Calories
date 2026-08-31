import 'dart:io';

import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food_scan/domain/food_recognition_service.dart';
import 'package:caloris/features/food_scan/domain/food_scan_models.dart';
import 'package:caloris/features/food_scan/presentation/controllers/food_scan_controller.dart';
import 'package:caloris/features/food_scan/presentation/widgets/food_scan_result_view.dart';
import 'package:caloris/shared/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FoodScanPage extends ConsumerStatefulWidget {
  const FoodScanPage({super.key});

  @override
  ConsumerState<FoodScanPage> createState() => _FoodScanPageState();
}

class _FoodScanPageState extends ConsumerState<FoodScanPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(foodScanControllerProvider.notifier).recoverLostImage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodScanControllerProvider);
    final controller = ref.read(foodScanControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Makanan'),
        actions: [
          IconButton(
            tooltip: 'Riwayat scan',
            onPressed: () => context.push('/scan/history'),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/scan'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Kamera ini hanya untuk foto makanan atau minuman. Hasil selalu perlu kamu periksa sebelum disimpan.',
          ),
          const SizedBox(height: 16),
          if (state.image == null)
            _ImagePlaceholder(
              onCamera: () => controller.selectImage(FoodImageSource.camera),
              onGallery: () => controller.selectImage(FoodImageSource.gallery),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(
                  File(state.image!.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Colors.black12,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 54),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isWorking
                        ? null
                        : () => controller.selectImage(FoodImageSource.camera),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Scan ulang'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.isWorking ? null : controller.analyze,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analisis'),
                  ),
                ),
              ],
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Jangan simpan foto setelah analisis'),
            subtitle: const Text(
              'Aktif secara default. Riwayat hanya menyimpan hasil terstruktur.',
            ),
            value: state.doNotStorePhoto,
            onChanged: state.isWorking ? null : controller.setDoNotStorePhoto,
          ),
          if (state.isWorking) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Memproses…'),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(state.errorMessage!),
              ),
            ),
          ],
          if (state.result != null) ...[
            const SizedBox(height: 22),
            FoodScanResultView(
              result: state.result!,
              onEdit: _editItem,
              onRemove: controller.removeItem,
              onAdd: controller.addItem,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: state.isWorking || state.result!.foods.isEmpty
                  ? null
                  : _saveToDiary,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan ke Diary'),
            ),
          ] else if (state.image != null && !state.isWorking) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.addItem,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Masukkan komponen secara manual'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editItem(ScannedFoodItem item) async {
    final updated = await showDialog<ScannedFoodItem>(
      context: context,
      builder: (_) => _ScannedFoodDialog(item: item),
    );
    if (updated != null) {
      ref.read(foodScanControllerProvider.notifier).updateItem(updated);
    }
  }

  Future<void> _saveToDiary() async {
    final mealType = await showDialog<MealType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Simpan sebagai'),
        children: MealType.values
            .map(
              (meal) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, meal),
                child: Text(meal.label),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (mealType == null) return;
    final saved = await ref
        .read(foodScanControllerProvider.notifier)
        .saveToDiary(mealType);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Hasil yang sudah dikoreksi berhasil disimpan ke Diary.'
              : 'Hasil belum dapat disimpan. Periksa kembali datanya.',
        ),
      ),
    );
    if (saved) context.go('/diary');
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.onCamera, required this.onGallery});
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.restaurant_rounded, size: 62),
          const SizedBox(height: 12),
          Text(
            'Ambil foto makanan yang jelas',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Buka kamera'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pilih dari galeri'),
          ),
        ],
      ),
    ),
  );
}

class _ScannedFoodDialog extends StatefulWidget {
  const _ScannedFoodDialog({required this.item});
  final ScannedFoodItem item;

  @override
  State<_ScannedFoodDialog> createState() => _ScannedFoodDialogState();
}

class _ScannedFoodDialogState extends State<_ScannedFoodDialog> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _calories;
  late PortionUnit _unit;
  late CookingMethod? _method;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _amount = TextEditingController(
      text: widget.item.amount.toStringAsFixed(0),
    );
    _calories = TextEditingController(
      text: widget.item.calories.toStringAsFixed(0),
    );
    _unit = widget.item.unit;
    _method = widget.item.cookingMethod;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _calories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Koreksi komponen'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama makanan'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Jumlah'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PortionUnit>(
            initialValue: _unit,
            decoration: const InputDecoration(labelText: 'Unit'),
            items: PortionUnit.values
                .map(
                  (unit) =>
                      DropdownMenuItem(value: unit, child: Text(unit.label)),
                )
                .toList(growable: false),
            onChanged: (value) => setState(() => _unit = value ?? _unit),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Kalori'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CookingMethod?>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Cara memasak'),
            items: [
              const DropdownMenuItem<CookingMethod?>(
                value: null,
                child: Text('Tidak diketahui'),
              ),
              ...CookingMethod.values.map(
                (method) => DropdownMenuItem<CookingMethod?>(
                  value: method,
                  child: Text(method.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _method = value),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Terapkan')),
    ],
  );

  void _submit() {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    final calories = double.tryParse(_calories.text.replaceAll(',', '.'));
    if (amount == null || calories == null) return;
    final updated = widget.item.copyWith(
      name: _name.text,
      amount: amount,
      unit: _unit,
      calories: calories,
      cookingMethod: _method,
      clearCookingMethod: _method == null,
    );
    try {
      updated.validate();
      Navigator.pop(context, updated);
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa nama, jumlah, dan kalori.')),
      );
    }
  }
}
