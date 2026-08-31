import 'package:caloris/core/utils/input_validators.dart';
import 'package:caloris/features/food/data/supabase_food_repository.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/presentation/controllers/food_diary_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MealBuilderPage extends ConsumerStatefulWidget {
  const MealBuilderPage({super.key});

  @override
  ConsumerState<MealBuilderPage> createState() => _MealBuilderPageState();
}

class _MealBuilderPageState extends ConsumerState<MealBuilderPage> {
  final List<FoodTemplate> _items = [];
  MealType _mealType = MealType.lunch;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (sum, item) => sum + item.calories);
    return Scaffold(
      appBar: AppBar(title: const Text('Susun Makanan Saya')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<MealType>(
            initialValue: _mealType,
            decoration: const InputDecoration(labelText: 'Waktu makan'),
            items: MealType.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.label)),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _mealType = value ?? _mealType),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tambahkan karbohidrat, protein, sayur, atau tambahan.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._items.indexed.map(
                      (entry) => ListTile(
                        title: Text(entry.$2.name),
                        subtitle: Text(
                          '${entry.$2.amount} ${entry.$2.unit.label}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${entry.$2.calories.round()} kcal'),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _items.removeAt(entry.$1)),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total estimasi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '${total.round()} kcal',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _addComponent,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah komponen'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _items.isEmpty || _saving ? null : _saveToDiary,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('Simpan ke Diary'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _items.isEmpty || _saving ? null : _saveFavorite,
            icon: const Icon(Icons.favorite_outline_rounded),
            label: const Text('Simpan sebagai favorit'),
          ),
        ],
      ),
    );
  }

  Future<void> _addComponent() async {
    final result = await showDialog<FoodTemplate>(
      context: context,
      builder: (_) => const _AddComponentDialog(),
    );
    if (result != null) setState(() => _items.add(result));
  }

  Future<void> _saveToDiary() async {
    setState(() => _saving = true);
    var success = true;
    final selected = ref.read(selectedDiaryDateProvider);
    final now = DateTime.now();
    for (final item in _items) {
      success =
          await ref
              .read(foodDiaryControllerProvider.notifier)
              .add(
                item.toLog(
                  userId: '',
                  mealType: _mealType,
                  loggedAt: DateTime(
                    selected.year,
                    selected.month,
                    selected.day,
                    now.hour,
                    now.minute,
                  ),
                ),
              ) &&
          success;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) context.pop();
  }

  Future<void> _saveFavorite() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nama menu favorit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Contoh: Menu ayam bakar',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.length < 2) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(foodRepositoryProvider)
          .saveFavorite(
            FavoriteMeal(
              id: '',
              userId: '',
              name: name,
              items: List.of(_items),
            ),
          );
      ref.invalidate(favoriteMealsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menu favorit disimpan.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AddComponentDialog extends StatefulWidget {
  const _AddComponentDialog();

  @override
  State<_AddComponentDialog> createState() => _AddComponentDialogState();
}

class _AddComponentDialogState extends State<_AddComponentDialog> {
  static const catalog = <String, List<String>>{
    'Karbohidrat': ['Nasi', 'Kentang', 'Mie', 'Roti', 'Lainnya'],
    'Protein': ['Ayam', 'Ikan', 'Bebek', 'Telur', 'Tahu', 'Tempe', 'Lainnya'],
    'Sayur': ['Kangkung', 'Bayam', 'Sawi', 'Kol', 'Wortel', 'Lainnya'],
    'Tambahan': [
      'Sambal',
      'Saus',
      'Minyak',
      'Santan',
      'Mayonnaise',
      'Kecap',
      'Keju',
      'Lainnya',
    ],
  };

  final _amount = TextEditingController(text: '1');
  final _calories = TextEditingController();
  String _category = 'Karbohidrat';
  String _food = 'Nasi';
  PortionUnit _unit = PortionUnit.portion;
  CookingMethod? _cooking;

  @override
  void dispose() {
    _amount.dispose();
    _calories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tambah komponen'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: catalog.keys
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _category = value ?? _category;
              _food = catalog[_category]!.first;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_category),
            initialValue: _food,
            decoration: const InputDecoration(labelText: 'Makanan'),
            items: catalog[_category]!
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _food = value ?? _food),
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
            decoration: const InputDecoration(labelText: 'Satuan'),
            items: PortionUnit.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.label)),
                )
                .toList(),
            onChanged: (value) => setState(() => _unit = value ?? _unit),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Estimasi kalori',
              helperText: 'Isi berdasarkan kemasan atau informasi penjual.',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CookingMethod?>(
            initialValue: _cooking,
            decoration: const InputDecoration(labelText: 'Cara memasak'),
            items: [
              const DropdownMenuItem<CookingMethod?>(
                child: Text('Tidak diketahui'),
              ),
              ...CookingMethod.values.map(
                (value) => DropdownMenuItem<CookingMethod?>(
                  value: value,
                  child: Text(value.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _cooking = value),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Tambah')),
    ],
  );

  void _submit() {
    final amount = InputValidators.parseDecimal(_amount.text);
    final calories = InputValidators.parseDecimal(_calories.text);
    if (amount == null || amount <= 0 || calories == null || calories < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah dan kalori harus valid.')),
      );
      return;
    }
    Navigator.pop(
      context,
      FoodTemplate(
        name: _food,
        amount: amount,
        unit: _unit,
        calories: calories,
        cookingMethod: _cooking,
      ),
    );
  }
}
