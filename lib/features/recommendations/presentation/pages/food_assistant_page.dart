import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/recommendations/domain/recommendation_models.dart';
import 'package:caloris/features/recommendations/presentation/controllers/recommendations_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodAssistantPage extends ConsumerStatefulWidget {
  const FoodAssistantPage({super.key});

  @override
  ConsumerState<FoodAssistantPage> createState() => _FoodAssistantPageState();
}

class _FoodAssistantPageState extends ConsumerState<FoodAssistantPage> {
  final _questionController = TextEditingController();
  final _preferredController = TextEditingController();
  final _limitedController = TextEditingController();
  final _scrollController = ScrollController();
  MealType _mealType = MealType.dinner;
  bool _practicalMode = true;

  @override
  void dispose() {
    _questionController.dispose();
    _preferredController.dispose();
    _limitedController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(foodAssistantControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
    final snapshot = ref.watch(healthInsightsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Makanan'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(foodAssistantControllerProvider.notifier).clear(),
            tooltip: 'Hapus percakapan',
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Data harian belum dapat dimuat: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(HealthInsightsSnapshot snapshot) {
    final state = ref.watch(foodAssistantControllerProvider);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _ScopeCard(remainingCalories: snapshot.daily.remainingCalories),
                const SizedBox(height: 12),
                _SettingsCard(
                  mealType: _mealType,
                  practicalMode: _practicalMode,
                  preferredController: _preferredController,
                  limitedController: _limitedController,
                  onMealTypeChanged: (value) =>
                      setState(() => _mealType = value),
                  onPracticalModeChanged: (value) =>
                      setState(() => _practicalMode = value),
                ),
                const SizedBox(height: 12),
                _NearbyPlacesSection(
                  places: state.nearbyPlaces,
                  message: state.nearbyMessage,
                  isLoading: state.isLoadingNearby,
                  onFind: () => ref
                      .read(foodAssistantControllerProvider.notifier)
                      .findNearbyFoods(),
                  onOpen: _openExternalUrl,
                  onOpenMapsSearch: () => _openExternalUrl(
                    'https://www.google.com/maps/search/?api=1&query=tempat+makan+sehat',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final prompt in const [
                      'Makanan apa yang boleh saya pilih?',
                      'Makanan apa yang perlu saya batasi?',
                      'Buatkan menu praktis sesuai sisa kalori.',
                    ])
                      ActionChip(
                        avatar: const Icon(
                          Icons.auto_awesome_outlined,
                          size: 18,
                        ),
                        label: Text(prompt),
                        onPressed: state.isLoading
                            ? null
                            : () => _send(snapshot, prompt),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (state.messages.isEmpty)
                  const _EmptyConversation()
                else
                  for (final message in state.messages) ...[
                    _MessageBubble(message: message),
                    const SizedBox(height: 10),
                  ],
                if (state.isLoading)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _ThinkingBubble(),
                  ),
                if (state.latestResult case final result?) ...[
                  if (result.foodsToChoose.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _FoodGuidanceCard(
                      title: 'Boleh dipilih',
                      icon: Icons.check_circle_outline_rounded,
                      items: result.foodsToChoose,
                    ),
                  ],
                  if (result.foodsToLimit.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _FoodGuidanceCard(
                      title: 'Batasi atau hindari',
                      icon: Icons.do_not_disturb_on_outlined,
                      items: result.foodsToLimit,
                    ),
                  ],
                  if (result.disclaimer.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      result.disclaimer,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Tanyakan menu, porsi, atau pilihan makanan…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isLoading
                        ? null
                        : () => _send(snapshot, _questionController.text),
                    tooltip: 'Kirim pertanyaan makanan',
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(HealthInsightsSnapshot snapshot, String question) async {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty) return;
    _questionController.clear();
    await ref
        .read(foodAssistantControllerProvider.notifier)
        .send(
          snapshot,
          question: cleanQuestion,
          mealType: _mealType,
          preferredFoods: _commaSeparated(_preferredController.text),
          limitedFoods: _commaSeparated(_limitedController.text),
          practicalMode: _practicalMode,
        );
  }

  List<String> _commaSeparated(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(20)
      .toList(growable: false);

  Future<void> _openExternalUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _NearbyPlacesSection extends StatelessWidget {
  const _NearbyPlacesSection({
    required this.places,
    required this.message,
    required this.isLoading,
    required this.onFind,
    required this.onOpen,
    required this.onOpenMapsSearch,
  });

  final List<NearbyFoodPlace> places;
  final String? message;
  final bool isLoading;
  final VoidCallback onFind;
  final ValueChanged<String> onOpen;
  final VoidCallback onOpenMapsSearch;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tempat makan sekitar',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Lokasi dipakai sekali untuk pencarian radius 1,5 km dan tidak disimpan.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: isLoading ? null : onFind,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.near_me_outlined),
              label: const Text('Cari dengan lokasi saya'),
            ),
          ),
          if (message != null) ...[const SizedBox(height: 10), Text(message!)],
          if (places.isEmpty && message != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onOpenMapsSearch,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Buka pencarian Google Maps'),
            ),
          ],
          for (final place in places) ...[
            const Divider(height: 24),
            Text(
              place.name,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (place.address.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(place.address),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (place.rating != null)
                  Chip(
                    avatar: const Icon(Icons.star_outline_rounded, size: 18),
                    label: Text(
                      '${place.rating!.toStringAsFixed(1)} (${place.userRatingCount})',
                    ),
                  ),
                if (place.openNow != null)
                  Chip(
                    avatar: Icon(
                      place.openNow!
                          ? Icons.schedule_rounded
                          : Icons.schedule_outlined,
                      size: 18,
                    ),
                    label: Text(place.openNow! ? 'Buka sekarang' : 'Tutup'),
                  ),
                if (place.delivery)
                  const Chip(label: Text('Delivery tersedia')),
                if (place.takeout)
                  const Chip(label: Text('Bisa dibawa pulang')),
                if (place.dineIn) const Chip(label: Text('Makan di tempat')),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onOpen(place.mapsUri),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Buka Maps'),
                ),
                if (place.websiteUri.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () => onOpen(place.websiteUri),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Situs / pesan'),
                  ),
              ],
            ),
          ],
          if (places.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Tanyakan rekomendasi setelah daftar dimuat. AI hanya memakai tempat '
              'di atas; cek kembali menu, harga, dan cara pesan terbaru.',
            ),
          ],
        ],
      ),
    ),
  );
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({required this.remainingCalories});

  final int remainingCalories;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.restaurant_menu_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khusus makanan, selalu Bahasa Indonesia',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sisa hari ini sekitar $remainingCalories kcal. Asisten ini '
                  'membantu pilihan makanan dan porsi, bukan diagnosis medis.',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.mealType,
    required this.practicalMode,
    required this.preferredController,
    required this.limitedController,
    required this.onMealTypeChanged,
    required this.onPracticalModeChanged,
  });

  final MealType mealType;
  final bool practicalMode;
  final TextEditingController preferredController;
  final TextEditingController limitedController;
  final ValueChanged<MealType> onMealTypeChanged;
  final ValueChanged<bool> onPracticalModeChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.tune_rounded),
      title: const Text('Atur preferensi makanan'),
      subtitle: const Text('Opsional, pisahkan beberapa makanan dengan koma.'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        DropdownButtonFormField<MealType>(
          initialValue: mealType,
          decoration: const InputDecoration(labelText: 'Waktu makan'),
          items: MealType.values
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(item.label)),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onMealTypeChanged(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: preferredController,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Makanan yang disukai atau boleh',
            hintText: 'Contoh: ayam, tempe, sayur',
          ),
        ),
        TextField(
          controller: limitedController,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Makanan yang dibatasi atau dihindari',
            hintText: 'Contoh: santan, kacang karena alergi',
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Utamakan pilihan praktis'),
          subtitle: const Text('Cocok untuk kos, warung, atau jadwal sibuk.'),
          value: practicalMode,
          onChanged: onPracticalModeChanged,
        ),
      ],
    ),
  );
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        Icon(
          Icons.ramen_dining_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Mulai dengan pertanyaan tentang makanan',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Misalnya pilihan makan malam, porsi, atau makanan yang perlu dibatasi.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final FoodConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == FoodConversationRole.user;
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUser ? colors.onPrimary : colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Menyusun pilihan makanan…'),
        ],
      ),
    ),
  );
}

class _FoodGuidanceCard extends StatelessWidget {
  const _FoodGuidanceCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<FoodGuidanceItem> items;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${item.name}: ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: item.reason),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
