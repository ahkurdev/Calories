import 'package:caloris/features/auth/presentation/controllers/auth_controller.dart';
import 'package:caloris/features/dashboard/presentation/controllers/dashboard_providers.dart';
import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:caloris/shared/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).value;
    final calculation = ref.watch(calorieCalculationProvider);
    final foodSummary = ref.watch(dailyFoodSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caloris'),
        actions: [
          IconButton(
            tooltip: 'Jadwal dan reminder',
            onPressed: () => context.push('/schedule'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Profil saya',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/home'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileControllerProvider);
          ref.invalidate(dailyFoodSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Halo, ${profile?.name ?? 'teman'}',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now())),
            const SizedBox(height: 24),
            foodSummary.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Ringkasan makanan belum tersedia: $error'),
                ),
              ),
              data: (summary) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _CalorieValue(
                              label: 'Target',
                              value: summary.targetCalories,
                            ),
                          ),
                          Expanded(
                            child: _CalorieValue(
                              label: 'Consumed',
                              value: summary.consumedCalories,
                            ),
                          ),
                          Expanded(
                            child: _CalorieValue(
                              label: 'Remaining',
                              value: summary.remainingCalories,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: summary.progress),
                      if (summary.overTargetCalories > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Hari ini sekitar ${summary.overTargetCalories} kcal '
                          'di atas target. Tidak apa-apa—lanjutkan catatan '
                          'secara konsisten.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Berat sekarang',
                    value: '${profile?.currentWeightKg ?? '-'} kg',
                    icon: Icons.monitor_weight_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Target berat',
                    value: '${profile?.targetWeightKg ?? '-'} kg',
                    icon: Icons.flag_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.calculate_outlined),
                title: const Text('Perhitungan dasar'),
                subtitle: Text(
                  calculation == null
                      ? 'Belum tersedia'
                      : 'BMI ${calculation.bmi.toStringAsFixed(1)} • '
                            'BMR ${calculation.bmr.round()} • '
                            'TDEE ${calculation.tdee.round()} kcal',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.track_changes_rounded),
                title: Text(profile?.goal.label ?? 'Tujuan belum tersedia'),
                subtitle: Text(profile?.activityLevel.label ?? ''),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/profile'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/diary'),
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: const Text('Buka Diary Makanan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/schedule'),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Jadwal & Reminder'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieValue extends StatelessWidget {
  const _CalorieValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      Text(
        '$value',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const Text('kcal'),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 18),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    ),
  );
}
