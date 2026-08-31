import 'dart:math' as math;

import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:caloris/features/progress/domain/progress_models.dart';
import 'package:caloris/features/progress/presentation/controllers/progress_controller.dart';
import 'package:caloris/shared/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weights = ref.watch(weightLogsProvider);
    final water = ref.watch(todayWaterSummaryProvider);
    final activities = ref.watch(todayActivitiesProvider);
    final profile = ref.watch(profileControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/progress'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weightLogsProvider);
          ref.invalidate(todayWaterLogsProvider);
          ref.invalidate(todayActivitiesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(
              title: 'Perjalanan berat',
              actionLabel: 'Catat berat',
              onPressed: () => _showWeightDialog(context, ref),
            ),
            const SizedBox(height: 10),
            weights.when(
              loading: _LoadingCard.new,
              error: (error, _) => _ErrorCard(message: '$error'),
              data: (logs) => _WeightCard(
                logs: logs,
                currentWeightKg: profile?.currentWeightKg,
                targetWeightKg: profile?.targetWeightKg,
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Air hari ini'),
            const SizedBox(height: 10),
            water.when(
              loading: _LoadingCard.new,
              error: (error, _) => _ErrorCard(message: '$error'),
              data: (summary) => _WaterCard(
                summary: summary,
                onAdd: (amount) => _runAction(
                  context,
                  () => ref.read(progressActionsProvider).addWater(amount),
                  'Air berhasil dicatat.',
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Aktivitas hari ini',
              actionLabel: 'Tambah',
              onPressed: () => _showActivityDialog(context, ref),
            ),
            const SizedBox(height: 10),
            activities.when(
              loading: _LoadingCard.new,
              error: (error, _) => _ErrorCard(message: '$error'),
              data: (logs) => _ActivityCard(logs: logs),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWeightDialog(BuildContext context, WidgetRef ref) async {
    final weight = TextEditingController();
    final note = TextEditingController();
    final result = await showDialog<(double, String?)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catat berat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weight,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Berat (kg)',
                hintText: 'Contoh: 68.5',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(weight.text.replaceAll(',', '.'));
              if (value == null || value < 25 || value > 400) return;
              Navigator.pop(context, (value, note.text));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    weight.dispose();
    note.dispose();
    if (result == null || !context.mounted) return;
    await _runAction(
      context,
      () => ref.read(progressActionsProvider).addWeight(result.$1, result.$2),
      'Berat berhasil dicatat.',
    );
  }

  Future<void> _showActivityDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_ActivityInput>(
      context: context,
      builder: (_) => const _ActivityDialog(),
    );
    if (result == null || !context.mounted) return;
    await _runAction(
      context,
      () => ref
          .read(progressActionsProvider)
          .addActivity(
            type: result.type,
            durationMinutes: result.durationMinutes,
            distanceKm: result.distanceKm,
            estimatedCalories: result.estimatedCalories,
          ),
      'Aktivitas berhasil dicatat.',
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onPressed});

  final String title;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      if (actionLabel != null)
        TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded),
          label: Text(actionLabel!),
        ),
    ],
  );
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.logs,
    required this.currentWeightKg,
    required this.targetWeightKg,
  });

  final List<WeightLog> logs;
  final double? currentWeightKg;
  final double? targetWeightKg;

  @override
  Widget build(BuildContext context) {
    final current = logs.isEmpty ? currentWeightKg : logs.last.weightKg;
    final start = logs.isEmpty ? currentWeightKg : logs.first.weightKg;
    final target = targetWeightKg;
    final progress = start == null || current == null || target == null
        ? null
        : WeightProgress.calculate(
            startingWeightKg: start,
            currentWeightKg: current,
            targetWeightKg: target,
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (logs.length >= 2)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WeightChartPainter(
                    weights: logs.map((log) => log.weightKg).toList(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Catat berat dua kali untuk melihat grafik.'),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Value(label: 'Awal', value: _kg(start)),
                ),
                Expanded(
                  child: _Value(label: 'Sekarang', value: _kg(current)),
                ),
                Expanded(
                  child: _Value(label: 'Target', value: _kg(target)),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 18),
              LinearProgressIndicator(value: progress.progress),
              const SizedBox(height: 8),
              Text(
                'Perubahan ${progress.totalChangeKg >= 0 ? '+' : ''}'
                '${progress.totalChangeKg.toStringAsFixed(1)} kg • '
                '${progress.remainingKg.toStringAsFixed(1)} kg menuju target',
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _kg(double? value) =>
      value == null ? '-' : '${value.toStringAsFixed(1)} kg';
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.summary, required this.onAdd});

  final WaterSummary summary;
  final ValueChanged<int> onAdd;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_outlined),
              const SizedBox(width: 10),
              Text(
                '${summary.consumedMl} / ${summary.targetMl} ml',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: summary.progress),
          const SizedBox(height: 8),
          Text('${summary.remainingMl} ml tersisa hari ini'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: () => onAdd(250),
                child: const Text('+250 ml'),
              ),
              FilledButton.tonal(
                onPressed: () => onAdd(500),
                child: const Text('+500 ml'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.logs});

  final List<ActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Belum ada aktivitas yang dicatat hari ini.'),
        ),
      );
    }
    final totalMinutes = logs.fold(0, (sum, log) => sum + log.durationMinutes);
    final totalCalories = logs.fold<double>(
      0,
      (sum, log) => sum + (log.estimatedCalories ?? 0),
    );
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Expanded(child: Text('$totalMinutes menit total')),
                Text('${totalCalories.round()} kcal estimasi'),
              ],
            ),
          ),
          ...logs.map(
            (log) => ListTile(
              leading: const Icon(Icons.directions_walk_rounded),
              title: Text(log.activityType),
              subtitle: Text(
                '${log.durationMinutes} menit'
                '${log.distanceKm == null ? '' : ' • ${log.distanceKm} km'}',
              ),
              trailing: Text(
                DateFormat('HH:mm').format(log.loggedAt.toLocal()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityDialog extends StatefulWidget {
  const _ActivityDialog();

  @override
  State<_ActivityDialog> createState() => _ActivityDialogState();
}

class _ActivityDialogState extends State<_ActivityDialog> {
  static const _types = [
    'Jalan kaki',
    'Jogging ringan',
    'Bersepeda',
    'Latihan ringan',
    'Lainnya',
  ];
  String _type = _types.first;
  final _customType = TextEditingController();
  final _duration = TextEditingController();
  final _distance = TextEditingController();
  final _calories = TextEditingController();

  @override
  void dispose() {
    _customType.dispose();
    _duration.dispose();
    _distance.dispose();
    _calories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tambah aktivitas'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Jenis aktivitas'),
            items: _types
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(growable: false),
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          if (_type == 'Lainnya') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customType,
              decoration: const InputDecoration(labelText: 'Nama aktivitas'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Durasi (menit)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _distance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Jarak km (opsional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Estimasi kalori (opsional)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Simpan')),
    ],
  );

  void _submit() {
    final duration = int.tryParse(_duration.text);
    final type = _type == 'Lainnya' ? _customType.text.trim() : _type;
    final distance = double.tryParse(_distance.text.replaceAll(',', '.'));
    final calories = double.tryParse(_calories.text.replaceAll(',', '.'));
    if (type.isEmpty ||
        type.length > 80 ||
        duration == null ||
        duration < 1 ||
        duration > 1440) {
      return;
    }
    if ((distance != null && (distance < 0 || distance > 1000)) ||
        (calories != null && (calories < 0 || calories > 10000))) {
      return;
    }
    Navigator.pop(
      context,
      _ActivityInput(
        type: type,
        durationMinutes: duration,
        distanceKm: distance,
        estimatedCalories: calories,
      ),
    );
  }
}

class _ActivityInput {
  const _ActivityInput({
    required this.type,
    required this.durationMinutes,
    this.distanceKm,
    this.estimatedCalories,
  });

  final String type;
  final int durationMinutes;
  final double? distanceKm;
  final double? estimatedCalories;
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 3),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter({required this.weights, required this.color});

  final List<double> weights;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final minWeight = weights.reduce(math.min);
    final maxWeight = weights.reduce(math.max);
    final range = math.max(1, maxWeight - minWeight);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < weights.length; i++) {
      final x = size.width * i / (weights.length - 1);
      final y = size.height - ((weights[i] - minWeight) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.weights != weights || oldDelegate.color != color;
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('Progress belum tersedia: $message'),
    ),
  );
}
