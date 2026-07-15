import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/staff_member.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class StaffRosterScreen extends ConsumerStatefulWidget {
  const StaffRosterScreen({super.key});

  @override
  ConsumerState<StaffRosterScreen> createState() => _StaffRosterScreenState();
}

class _StaffRosterScreenState extends ConsumerState<StaffRosterScreen> {
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);
  static const _border = Color(0xFF334155);

  Future<void> _showAddStaffDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Form(
              key: formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Add Staff Member', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _sheetField('Full Name *', nameCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 14),
                _sheetField('Email *', emailCtrl, keyboardType: TextInputType.emailAddress, validator: (v) => !v!.contains('@') ? 'Valid email required' : null),
                const SizedBox(height: 14),
                _sheetField('Bio / Designation', bioCtrl),
                const SizedBox(height: 14),
                _sheetField('Skills (comma separated)', specCtrl, hint: 'e.g. Haircut, Coloring, Spa'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _accent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: submitting ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheet(() => submitting = true);
                      try {
                        final specs = specCtrl.text.trim().isEmpty
                            ? <String>[]
                            : specCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                        await ref.read(salonRepositoryProvider).recruitStaff(
                          email: emailCtrl.text.trim(),
                          fullName: nameCtrl.text.trim(),
                          bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                          specialities: specs.isEmpty ? null : specs,
                        );
                        ref.invalidate(staffListProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setSheet(() => submitting = false);
                        if (ctx.mounted) {
                          final msg = e is ApiException ? e.message : '$e';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
                        }
                      }
                    },
                    child: submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add Staff Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleStatus(StaffMember staff) async {
    final newActive = staff.status == 'INACTIVE';
    try {
      await ref.read(salonRepositoryProvider).updateStaffStatus(staff.id, newActive);
      ref.invalidate(staffListProvider);
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : '$e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text('Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: _accent),
            onPressed: _showAddStaffDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(staffListProvider),
        color: _accent,
        backgroundColor: _card,
        child: staffAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.people_outline_rounded, color: Colors.blueGrey, size: 64),
              const SizedBox(height: 12),
              Text('Could not load staff: $e', style: const TextStyle(color: Colors.blueGrey), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => ref.invalidate(staffListProvider), child: const Text('Retry')),
            ]),
          ),
          data: (staff) {
            if (staff.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline_rounded, color: Colors.blueGrey.shade700, size: 72),
                const SizedBox(height: 16),
                const Text('No staff members yet', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Tap + to invite your first team member', style: TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _accent),
                  onPressed: _showAddStaffDialog,
                  icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                  label: const Text('Add Staff', style: TextStyle(color: Colors.white)),
                ),
              ]));
            }

            final active = staff.where((s) => s.status == 'ACTIVE').toList();
            final inactive = staff.where((s) => s.status != 'ACTIVE').toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatsRow(staff.length, active.length),
                const SizedBox(height: 20),
                if (active.isNotEmpty) ...[
                  _sectionTitle('Active Staff (${active.length})'),
                  const SizedBox(height: 10),
                  ...active.map((s) => _buildStaffCard(s)),
                ],
                if (inactive.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Inactive (${inactive.length})'),
                  const SizedBox(height: 10),
                  ...inactive.map((s) => _buildStaffCard(s)),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        onPressed: _showAddStaffDialog,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Staff', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatsRow(int total, int active) {
    return Row(children: [
      Expanded(child: _miniStat('Total Staff', '$total', Icons.people_rounded, const Color(0xFF6366F1))),
      const SizedBox(width: 12),
      Expanded(child: _miniStat('Active Today', '$active', Icons.check_circle_rounded, const Color(0xFF10B981))),
    ]);
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold));
  }

  Widget _buildStaffCard(StaffMember staff) {
    final isActive = staff.status == 'ACTIVE';
    final initials = staff.fullName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final colors = [const Color(0xFF6366F1), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEC4899)];
    final avatarColor = colors[staff.id.hashCode % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: avatarColor.withOpacity(0.2),
            child: Text(initials, style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(staff.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isActive ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4)),
                  ),
                  child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]),
              if (staff.email != null) ...[
                const SizedBox(height: 3),
                Text(staff.email!, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
              ],
              if (staff.bio != null) ...[
                const SizedBox(height: 3),
                Text(staff.bio!, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
              ],
              if (staff.specialities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: staff.specialities.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(s, style: const TextStyle(color: _accent, fontSize: 10)),
                  )).toList(),
                ),
              ],
              if (staff.rating > 0) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(staff.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.amber, fontSize: 12)),
                ]),
              ],
            ]),
          ),
          // Toggle active
          IconButton(
            icon: Icon(
              isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              color: isActive ? Colors.green : Colors.blueGrey,
              size: 32,
            ),
            onPressed: () => _toggleStatus(staff),
          ),
        ]),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, {TextInputType? keyboardType, String? Function(String?)? validator, String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
        hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
        filled: true, fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}
