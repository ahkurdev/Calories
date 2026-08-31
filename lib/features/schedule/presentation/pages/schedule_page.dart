import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:caloris/features/schedule/presentation/controllers/schedule_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(schedulesProvider);
    final reminders = ref.watch(remindersProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jadwal Saya'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Jadwal'),
              Tab(text: 'Reminder'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            schedules.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(schedulesProvider),
              ),
              data: (entries) => _ScheduleList(
                entries: entries,
                onAdd: () => _editSchedule(context, ref),
                onEdit: (entry) => _editSchedule(context, ref, entry),
                onDelete: (entry) => _deleteSchedule(context, ref, entry),
              ),
            ),
            reminders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(remindersProvider),
              ),
              data: (items) => _ReminderList(
                reminders: items,
                onAdd: () => _editReminder(context, ref),
                onToggle: (item, enabled) => _saveReminder(
                  context,
                  ref,
                  item.copyWith(enabled: enabled),
                ),
                onDelete: (item) => _deleteReminder(context, ref, item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSchedule(
    BuildContext context,
    WidgetRef ref, [
    ScheduleEntry? existing,
  ]) async {
    final result = await showDialog<ScheduleEntry>(
      context: context,
      builder: (_) => _ScheduleDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;
    await _run(
      context,
      () => ref.read(scheduleActionsProvider).saveSchedule(result),
      'Jadwal berhasil disimpan.',
    );
  }

  Future<void> _deleteSchedule(
    BuildContext context,
    WidgetRef ref,
    ScheduleEntry entry,
  ) async {
    await _run(
      context,
      () => ref.read(scheduleActionsProvider).deleteSchedule(entry.id),
      'Jadwal dihapus.',
    );
  }

  Future<void> _editReminder(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<ReminderSetting>(
      context: context,
      builder: (_) => const _ReminderDialog(),
    );
    if (result != null && context.mounted) {
      await _saveReminder(context, ref, result);
    }
  }

  Future<void> _saveReminder(
    BuildContext context,
    WidgetRef ref,
    ReminderSetting reminder,
  ) async {
    try {
      final scheduled = await ref
          .read(scheduleActionsProvider)
          .saveReminder(reminder);
      if (!context.mounted) return;
      final message = scheduled
          ? 'Reminder disimpan dan dijadwalkan di perangkat.'
          : 'Reminder disimpan. Izin notifikasi belum tersedia di perangkat.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _deleteReminder(
    BuildContext context,
    WidgetRef ref,
    ReminderSetting reminder,
  ) async {
    await _run(
      context,
      () => ref.read(scheduleActionsProvider).deleteReminder(reminder.id),
      'Reminder dihapus.',
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ScheduleEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<ScheduleEntry> onDelete;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah jadwal'),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            ScheduleGapAdvisor.recommend(
              entries,
              dayOfWeek: DateTime.now().weekday,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (entries.isEmpty)
        const _EmptyState(
          icon: Icons.calendar_month_outlined,
          message: 'Belum ada jadwal mingguan.',
        )
      else
        for (var day = 1; day <= 7; day++)
          if (entries.any((entry) => entry.dayOfWeek == day)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(
                SchedulePage._days[day - 1],
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            ...entries
                .where((entry) => entry.dayOfWeek == day)
                .map(
                  (entry) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${entry.busynessLevel}'),
                      ),
                      title: Text(entry.activityName),
                      subtitle: Text(
                        '${entry.startTime.label}–${entry.endTime.label} • '
                        '${entry.category.label}',
                      ),
                      onTap: () => onEdit(entry),
                      trailing: IconButton(
                        tooltip: 'Hapus',
                        onPressed: () => onDelete(entry),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                  ),
                ),
          ],
    ],
  );
}

class _ReminderList extends StatelessWidget {
  const _ReminderList({
    required this.reminders,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final List<ReminderSetting> reminders;
  final VoidCallback onAdd;
  final void Function(ReminderSetting, bool) onToggle;
  final ValueChanged<ReminderSetting> onDelete;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Tambah reminder'),
      ),
      const SizedBox(height: 16),
      if (reminders.isEmpty)
        const _EmptyState(
          icon: Icons.notifications_none_rounded,
          message: 'Belum ada reminder.',
        )
      else
        ...reminders.map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(item.type.label),
              subtitle: Text(
                '${item.time.label} • ${_dayLabels(item.repeatDays)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: item.enabled,
                    onChanged: (value) => onToggle(item, value),
                  ),
                  IconButton(
                    tooltip: 'Hapus',
                    onPressed: () => onDelete(item),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  static String _dayLabels(List<int> days) {
    if (days.length == 7) return 'Setiap hari';
    return days
        .map((day) => SchedulePage._days[day - 1].substring(0, 3))
        .join(', ');
  }
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({this.existing});

  final ScheduleEntry? existing;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late final TextEditingController _name;
  late int _day;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late ScheduleCategory _category;
  late int _busyness;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _name = TextEditingController(text: item?.activityName ?? '');
    _day = item?.dayOfWeek ?? DateTime.now().weekday;
    _start = TimeOfDay(
      hour: item?.startTime.hour ?? 8,
      minute: item?.startTime.minute ?? 0,
    );
    _end = TimeOfDay(
      hour: item?.endTime.hour ?? 9,
      minute: item?.endTime.minute ?? 0,
    );
    _category = item?.category ?? ScheduleCategory.work;
    _busyness = item?.busynessLevel ?? 2;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Tambah jadwal' : 'Edit jadwal'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Nama aktivitas'),
          ),
          DropdownButtonFormField<int>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Hari'),
            items: [
              for (var day = 1; day <= 7; day++)
                DropdownMenuItem(
                  value: day,
                  child: Text(SchedulePage._days[day - 1]),
                ),
            ],
            onChanged: (value) => setState(() => _day = value ?? _day),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'Mulai',
                  time: _start,
                  onPick: (value) => setState(() => _start = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeButton(
                  label: 'Selesai',
                  time: _end,
                  onPick: (value) => setState(() => _end = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ScheduleCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: ScheduleCategory.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(growable: false),
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _busyness,
            decoration: const InputDecoration(labelText: 'Tingkat kesibukan'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 — Ringan')),
              DropdownMenuItem(value: 2, child: Text('2 — Sedang')),
              DropdownMenuItem(value: 3, child: Text('3 — Padat')),
            ],
            onChanged: (value) =>
                setState(() => _busyness = value ?? _busyness),
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
    final item = ScheduleEntry(
      id: widget.existing?.id ?? '',
      userId: widget.existing?.userId ?? '',
      dayOfWeek: _day,
      activityName: _name.text,
      startTime: LocalTime(hour: _start.hour, minute: _start.minute),
      endTime: LocalTime(hour: _end.hour, minute: _end.minute),
      category: _category,
      busynessLevel: _busyness,
    );
    try {
      item.validate();
      Navigator.pop(context, item);
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message?.toString() ?? 'Jadwal tidak valid.'),
        ),
      );
    }
  }
}

class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog();

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  ReminderType _type = ReminderType.water;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7};

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tambah reminder'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ReminderType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Jenis reminder'),
            items: ReminderType.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(growable: false),
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          _TimeButton(
            label: 'Jam reminder',
            time: _time,
            onPick: (value) => setState(() => _time = value),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ulangi pada',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (var day = 1; day <= 7; day++)
                FilterChip(
                  selected: _days.contains(day),
                  label: Text(SchedulePage._days[day - 1].substring(0, 3)),
                  onSelected: (selected) => setState(
                    () => selected ? _days.add(day) : _days.remove(day),
                  ),
                ),
            ],
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
    final item = ReminderSetting(
      id: '',
      userId: '',
      type: _type,
      time: LocalTime(hour: _time.hour, minute: _time.minute),
      enabled: true,
      repeatDays: _days.toList()..sort(),
    );
    try {
      item.validate();
      Navigator.pop(context, item);
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih setidaknya satu hari.')),
      );
    }
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onPick,
  });

  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () async {
      final result = await showTimePicker(context: context, initialTime: time);
      if (result != null) onPick(result);
    },
    icon: const Icon(Icons.schedule_rounded),
    label: Text('$label: ${time.format(context)}'),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );
}
