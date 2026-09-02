import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:caloris/features/walking/presentation/controllers/walking_tracker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalkingTrackerPage extends ConsumerWidget {
  const WalkingTrackerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walkingTrackerControllerProvider);
    final profile = ref.watch(profileControllerProvider).value;
    final controller = ref.read(walkingTrackerControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Pelacak Jalan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lokasi hanya dibaca selama sesi ini untuk memfilter '
                      'gerak berkecepatan kendaraan. Rute dan koordinat tidak disimpan.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StatusCard(state: state),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.directions_walk_rounded,
                  label: 'Langkah sesi',
                  value: '${state.steps}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Estimasi energi',
                  value: '${state.estimatedCalories.toStringAsFixed(1)} kcal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.timer_outlined,
                  label: 'Durasi',
                  value: _duration(state.elapsed),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.speed_rounded,
                  label: 'Kecepatan',
                  value: '${state.speedKmh.toStringAsFixed(1)} km/j',
                ),
              ),
            ],
          ),
          if (state.message case final message?) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(message),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (state.isTracking)
            FilledButton.icon(
              onPressed: controller.stop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Hentikan sesi'),
            )
          else
            FilledButton.icon(
              onPressed: () =>
                  controller.start(weightKg: profile?.currentWeightKg ?? 70),
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Mulai jalan'),
            ),
          if (!state.isTracking && state.steps > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset sesi'),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Filter memakai sensor langkah, status pejalan, dan kecepatan GPS. '
            'Hasil adalah estimasi dan tidak dapat menjamin klasifikasi kendaraan '
            'secara sempurna pada setiap ponsel atau kondisi lalu lintas.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _duration(Duration value) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final WalkingTrackerState state;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = state.isVehicleFiltered
        ? (
            Icons.directions_car_filled_outlined,
            'Langkah sedang dijeda',
            'Gerak cepat/kendaraan terdeteksi atau sinyal lokasi tidak tersedia.',
          )
        : state.isWalking
        ? (
            Icons.directions_walk_rounded,
            'Sedang berjalan',
            'Langkah pada kecepatan pejalan sedang dihitung.',
          )
        : state.isTracking
        ? (
            Icons.pause_circle_outline_rounded,
            'Menunggu langkah',
            'Mulai berjalan sambil membawa ponsel.',
          )
        : (
            Icons.radio_button_unchecked_rounded,
            'Pelacakan belum aktif',
            'Mulai sesi ketika kamu siap berjalan.',
          );
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: Icon(icon, size: 36),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(label),
        ],
      ),
    ),
  );
}
