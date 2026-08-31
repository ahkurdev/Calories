import 'package:caloris/core/utils/input_validators.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:caloris/shared/widgets/async_action_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({
    required this.userId,
    required this.onSubmit,
    required this.isLoading,
    super.key,
    this.initialProfile,
    this.submitLabel = 'Simpan profil',
  });

  final String userId;
  final UserProfile? initialProfile;
  final bool isLoading;
  final String submitLabel;
  final Future<void> Function(UserProfile profile) onSubmit;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _height;
  late final TextEditingController _currentWeight;
  late final TextEditingController _targetWeight;
  late final TextEditingController _waterTarget;
  late DateTime? _birthDate;
  late Gender _gender;
  late ActivityLevel _activityLevel;
  late HealthGoal _goal;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _name = TextEditingController(text: profile?.name);
    _height = TextEditingController(text: _number(profile?.heightCm));
    _currentWeight = TextEditingController(
      text: _number(profile?.currentWeightKg),
    );
    _targetWeight = TextEditingController(
      text: _number(profile?.targetWeightKg),
    );
    _waterTarget = TextEditingController(
      text: (profile?.waterTargetMl ?? 2000).toString(),
    );
    _birthDate = profile?.birthDate;
    _gender = profile?.gender ?? Gender.preferNotToSay;
    _activityLevel = profile?.activityLevel ?? ActivityLevel.sedentary;
    _goal = profile?.goal ?? HealthGoal.maintainWeight;
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _currentWeight.dispose();
    _targetWeight.dispose();
    _waterTarget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama'),
          validator: (value) => InputValidators.requiredText(value, 'Nama'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: widget.isLoading ? null : _pickBirthDate,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _birthDate == null
                  ? 'Pilih tanggal lahir'
                  : 'Tanggal lahir: ${DateFormat('dd MMMM yyyy').format(_birthDate!)}',
            ),
          ),
        ),
        if (_birthDate == null)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 12),
            child: Text('Usia dihitung otomatis dari tanggal lahir.'),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Gender>(
          initialValue: _gender,
          decoration: const InputDecoration(labelText: 'Jenis kelamin'),
          items: Gender.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: widget.isLoading
              ? null
              : (value) => setState(() => _gender = value ?? _gender),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _numberField(_height, 'Tinggi (cm)', 100, 250)),
            const SizedBox(width: 12),
            Expanded(
              child: _numberField(
                _currentWeight,
                'Berat saat ini (kg)',
                25,
                400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _numberField(_targetWeight, 'Target berat (kg)', 25, 400),
        const SizedBox(height: 16),
        DropdownButtonFormField<ActivityLevel>(
          initialValue: _activityLevel,
          decoration: const InputDecoration(labelText: 'Tingkat aktivitas'),
          items: ActivityLevel.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: widget.isLoading
              ? null
              : (value) =>
                    setState(() => _activityLevel = value ?? _activityLevel),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<HealthGoal>(
          initialValue: _goal,
          decoration: const InputDecoration(labelText: 'Tujuan'),
          items: HealthGoal.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: widget.isLoading
              ? null
              : (value) => setState(() => _goal = value ?? _goal),
        ),
        const SizedBox(height: 16),
        _numberField(_waterTarget, 'Target air harian (ml)', 250, 10000),
        const SizedBox(height: 28),
        AsyncActionButton(
          label: widget.submitLabel,
          isLoading: widget.isLoading,
          onPressed: _submit,
        ),
      ],
    ),
  );

  TextFormField _numberField(
    TextEditingController controller,
    String label,
    double minimum,
    double maximum,
  ) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final number = InputValidators.parseDecimal(value ?? '');
      if (number == null) return 'Masukkan angka.';
      if (number < minimum || number > maximum) {
        return '$minimum–$maximum';
      }
      return null;
    },
  );

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(today.year - 25),
      firstDate: DateTime(today.year - 100),
      lastDate: DateTime(today.year - 13, today.month, today.day),
    );
    if (result != null) setState(() => _birthDate = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lahir terlebih dahulu.')),
      );
      return;
    }
    final profile = UserProfile(
      id: widget.userId,
      name: _name.text,
      gender: _gender,
      birthDate: _birthDate!,
      heightCm: InputValidators.parseDecimal(_height.text)!,
      currentWeightKg: InputValidators.parseDecimal(_currentWeight.text)!,
      targetWeightKg: InputValidators.parseDecimal(_targetWeight.text)!,
      activityLevel: _activityLevel,
      goal: _goal,
      waterTargetMl: InputValidators.parseDecimal(_waterTarget.text)!.round(),
    );
    try {
      profile.validate();
      await widget.onSubmit(profile);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  static String _number(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}
