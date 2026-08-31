import 'package:caloris/core/utils/input_validators.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/presentation/controllers/food_diary_controller.dart';
import 'package:caloris/shared/widgets/async_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManualFoodPage extends ConsumerStatefulWidget {
  const ManualFoodPage({super.key, this.initialMealType});

  final MealType? initialMealType;

  @override
  ConsumerState<ManualFoodPage> createState() => _ManualFoodPageState();
}

class _ManualFoodPageState extends ConsumerState<ManualFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController(text: '1');
  final _calories = TextEditingController();
  final _protein = TextEditingController(text: '0');
  final _carbohydrate = TextEditingController(text: '0');
  final _fat = TextEditingController(text: '0');
  final _fiber = TextEditingController(text: '0');
  late MealType _mealType;
  PortionUnit _unit = PortionUnit.portion;
  CookingMethod? _cookingMethod;

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType ?? MealType.breakfast;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbohydrate.dispose();
    _fat.dispose();
    _fiber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diary = ref.watch(foodDiaryControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah makanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('food-name-field'),
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nama makanan',
                    ),
                    validator: (value) =>
                        InputValidators.requiredText(value, 'Nama makanan'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MealType>(
                    initialValue: _mealType,
                    decoration: const InputDecoration(labelText: 'Waktu makan'),
                    items: MealType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _mealType = value ?? _mealType),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _numberField(_amount, 'Jumlah', minimum: 0.01),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<PortionUnit>(
                          initialValue: _unit,
                          decoration: const InputDecoration(
                            labelText: 'Satuan',
                          ),
                          items: PortionUnit.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _unit = value ?? _unit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _numberField(_calories, 'Kalori (kcal)', maximum: 10000),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CookingMethod?>(
                    initialValue: _cookingMethod,
                    decoration: const InputDecoration(
                      labelText: 'Cara memasak',
                    ),
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
                    onChanged: (value) =>
                        setState(() => _cookingMethod = value),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nutrisi opsional',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _numberField(_protein, 'Protein (g)')),
                      const SizedBox(width: 12),
                      Expanded(child: _numberField(_carbohydrate, 'Karbo (g)')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _numberField(_fat, 'Lemak (g)')),
                      const SizedBox(width: 12),
                      Expanded(child: _numberField(_fiber, 'Serat (g)')),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AsyncActionButton(
                    label: 'Simpan ke Diary',
                    isLoading: diary.isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _numberField(
    TextEditingController controller,
    String label, {
    double minimum = 0,
    double maximum = 2000,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final number = InputValidators.parseDecimal(value ?? '');
      if (number == null) return 'Masukkan angka.';
      if (number < minimum || number > maximum) return '$minimum–$maximum';
      return null;
    },
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = ref.read(selectedDiaryDateProvider);
    final now = DateTime.now();
    final success = await ref
        .read(foodDiaryControllerProvider.notifier)
        .add(
          FoodLog(
            id: '',
            userId: '',
            mealType: _mealType,
            foodName: _name.text.trim(),
            amount: InputValidators.parseDecimal(_amount.text)!,
            unit: _unit,
            calories: InputValidators.parseDecimal(_calories.text)!,
            protein: InputValidators.parseDecimal(_protein.text)!,
            carbohydrate: InputValidators.parseDecimal(_carbohydrate.text)!,
            fat: InputValidators.parseDecimal(_fat.text)!,
            fiber: InputValidators.parseDecimal(_fiber.text)!,
            cookingMethod: _cookingMethod,
            loggedAt: DateTime(
              selected.year,
              selected.month,
              selected.day,
              now.hour,
              now.minute,
            ),
          ),
        );
    if (!mounted) return;
    if (success) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(foodDiaryControllerProvider).error?.toString() ??
                'Makanan belum dapat disimpan.',
          ),
        ),
      );
    }
  }
}
