import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/salon_profile.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class BusinessHoursScreen extends ConsumerStatefulWidget {
  const BusinessHoursScreen({super.key});

  @override
  ConsumerState<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends ConsumerState<BusinessHoursScreen> {
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);
  static const _border = Color(0xFF334155);

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  late List<Map<String, dynamic>> _schedules;
  bool _initialized = false;
  bool _saving = false;

  void _initSchedules(List<WorkingHour> current) {
    if (_initialized) return;

    _schedules = List.generate(7, (i) {
      // dayOfWeek on backend: 0 = Sunday, 6 = Saturday.
      // But in our _days list: index 0 = Monday, ..., 6 = Sunday.
      // Let's map appropriately:
      final prismaDay = (i == 6) ? 0 : (i + 1);
      final existing = current.firstWhere(
        (w) => w.dayOfWeek == prismaDay,
        orElse: () => WorkingHour(
          id: '',
          dayOfWeek: prismaDay,
          openTime: '09:00',
          closeTime: '20:00',
          isOpen: true,
        ),
      );

      return {
        'dayOfWeek': prismaDay,
        'openTime': existing.openTime,
        'closeTime': existing.closeTime,
        'isOpen': existing.isOpen,
      };
    });

    _initialized = true;
  }

  String _formatTime12h(String time24) {
    if (time24.isEmpty) return '';
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    int h = int.tryParse(parts[0]) ?? 0;
    int m = int.tryParse(parts[1]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickTime(int index, bool isOpenTime) async {
    final currentStr = _schedules[index][isOpenTime ? 'openTime' : 'closeTime'] as String;
    final parts = currentStr.split(':');
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);
    if (parts.length == 2) {
      initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _schedules[index][isOpenTime ? 'openTime' : 'closeTime'] = '$h:$m';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(salonRepositoryProvider).saveSchedules(_schedules);
      ref.invalidate(salonProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Working hours updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : '$e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(salonProfileProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text('Business Hours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (profile) {
          _initSchedules(profile.workingHours);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 7,
            itemBuilder: (context, i) {
              final schedule = _schedules[i];
              final isOpen = schedule['isOpen'] as bool;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 85,
                        child: Text(
                          _days[i],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      const Spacer(),
                      if (isOpen) ...[
                        GestureDetector(
                          onTap: () => _pickTime(i, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                            child: Text(
                              _formatTime12h(schedule['openTime']),
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('-', style: TextStyle(color: Colors.blueGrey)),
                        ),
                        GestureDetector(
                          onTap: () => _pickTime(i, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                            child: Text(
                              _formatTime12h(schedule['closeTime']),
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ] else
                        const Text('Closed Today', style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontStyle: FontStyle.italic)),
                      const SizedBox(width: 8),
                      Switch(
                        value: isOpen,
                        activeColor: _accent,
                        onChanged: (val) => setState(() => _schedules[i]['isOpen'] = val),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
