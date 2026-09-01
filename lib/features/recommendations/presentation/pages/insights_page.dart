import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/recommendations/domain/health_statistics.dart';
import 'package:caloris/features/recommendations/presentation/controllers/recommendations_controller.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:caloris/shared/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  final _preference = TextEditingController();
  MealType _mealType = MealType.dinner;
  bool _practicalMode = true;

  @override
  void dispose() {
    _preference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(healthInsightsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Insight & Rekomendasi')),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/home'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(healthInsightsProvider),
        child: snapshot.when(
          loading: () => ListView(
            children: const [
              SizedBox(height: 240),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _MessageCard(
                icon: Icons.cloud_off_outlined,
                message: 'Insight belum dapat dimuat: $error',
              ),
            ],
          ),
          data: _content,
        ),
      ),
    );
  }

  Widget _content(HealthInsightsSnapshot snapshot) {
    final state = ref.watch(recommendationsControllerProvider);
    final controller = ref.read(recommendationsControllerProvider.notifier);
    final localActivity = ScheduleGapAdvisor.recommend(
      snapshot.schedules,
      dayOfWeek: snapshot.daily.day.weekday,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Statistikmu lebih dulu',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Angka di bawah dihitung dari catatanmu. AI hanya membantu menyusun '
          'bahasa dan pilihan praktis, bukan menentukan fakta kesehatan.',
        ),
        const SizedBox(height: 16),
        _DailyStatisticsCard(statistics: snapshot.daily),
        const SizedBox(height: 12),
        _WeeklyStatisticsCard(statistics: snapshot.weekly),
        const SizedBox(height: 24),
        Text(
          'Rekomendasi makanan',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                DropdownButtonFormField<MealType>(
                  initialValue: _mealType,
                  decoration: const InputDecoration(labelText: 'Waktu makan'),
                  items: MealType.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setState(() => _mealType = value ?? _mealType),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _preference,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Preferensi (opsional)',
                    hintText: 'Contoh: tanpa santan',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mode makanan praktis'),
                  subtitle: const Text(
                    'Untuk kos, jadwal sibuk, atau sering membeli makanan.',
                  ),
                  value: _practicalMode,
                  onChanged: (value) => setState(() => _practicalMode = value),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.loading.contains(RecommendationKind.meal)
                        ? null
                        : () => controller.recommendMeal(
                            snapshot,
                            mealType: _mealType,
                            preference: _preference.text,
                            practicalMode: _practicalMode,
                          ),
                    icon: state.loading.contains(RecommendationKind.meal)
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restaurant_menu_rounded),
                    label: Text(
                      'Cari pilihan sekitar ${snapshot.daily.remainingCalories} kcal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _result(state, RecommendationKind.meal),
        const SizedBox(height: 24),
        Text(
          'Aktivitas & ringkasan',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _MessageCard(
          icon: Icons.schedule_outlined,
          title: 'Analisis jadwal lokal',
          message: localActivity,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          title: 'Rekomendasi aktivitas ringan',
          subtitle:
              'Mengirim jadwal hari ini tanpa ID atau identitas pengguna.',
          loading: state.loading.contains(RecommendationKind.activity),
          onPressed: () => controller.recommendActivity(snapshot),
        ),
        _result(state, RecommendationKind.activity),
        const SizedBox(height: 10),
        _ActionCard(
          title: 'Ringkasan hari ini',
          subtitle: 'Target, konsumsi, air, dan aktivitas yang sudah dihitung.',
          loading: state.loading.contains(RecommendationKind.dailySummary),
          onPressed: () => controller.generateDailySummary(snapshot),
        ),
        _result(state, RecommendationKind.dailySummary),
        const SizedBox(height: 10),
        _ActionCard(
          title: 'Ringkasan 7 hari',
          subtitle: 'Pola mingguan dengan bahasa netral dan tidak menghakimi.',
          loading: state.loading.contains(RecommendationKind.weeklySummary),
          onPressed: () => controller.generateWeeklySummary(snapshot),
        ),
        _result(state, RecommendationKind.weeklySummary),
        const SizedBox(height: 16),
        const Text(
          'Rekomendasi AI bersifat pilihan dan bukan nasihat medis. Kamu tetap '
          'menentukan apa yang disimpan atau dilakukan.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _result(RecommendationsState state, RecommendationKind kind) {
    final result = state.results[kind];
    if (result == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _MessageCard(
        icon: result.isAiGenerated
            ? Icons.auto_awesome_outlined
            : Icons.edit_note_outlined,
        title: result.isAiGenerated ? 'Insight AI' : 'Fallback aman',
        message: result.message,
      ),
    );
  }
}

class _DailyStatisticsCard extends StatelessWidget {
  const _DailyStatisticsCard({required this.statistics});

  final DailyHealthStatistics statistics;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hari ini', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 14,
            children: [
              _Metric(
                'Kalori',
                '${statistics.consumedCalories}/${statistics.targetCalories}',
              ),
              _Metric('Tersisa', '${statistics.remainingCalories} kcal'),
              _Metric(
                'Air',
                '${statistics.waterMl}/${statistics.waterTargetMl} ml',
              ),
              _Metric('Aktivitas', '${statistics.activityMinutes} menit'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _WeeklyStatisticsCard extends StatelessWidget {
  const _WeeklyStatisticsCard({required this.statistics});

  final WeeklyHealthStatistics statistics;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7 hari terakhir',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 14,
            children: [
              _Metric(
                'Rata-rata kalori',
                '${statistics.averageCaloriesOnTrackedDays} kcal',
              ),
              _Metric('Hari tercatat', '${statistics.calorieTrackingDays}/7'),
              _Metric('Aktivitas', '${statistics.totalActivityMinutes} menit'),
              _Metric(
                'Perubahan berat',
                statistics.weightChangeKg == null
                    ? 'Belum cukup data'
                    : '${statistics.weightChangeKg! >= 0 ? '+' : ''}${statistics.weightChangeKg!.toStringAsFixed(1)} kg',
              ),
            ],
          ),
          if (statistics.frequentFoods.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Sering dicatat: ${statistics.frequentFoods.join(', ')}'),
          ],
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 135,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: loading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward_rounded),
      onTap: loading ? null : onPressed,
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message, this.title});

  final IconData icon;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(icon),
      title: title == null ? null : Text(title!),
      subtitle: Text(message),
    ),
  );
}
