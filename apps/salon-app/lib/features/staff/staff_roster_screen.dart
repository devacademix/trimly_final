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
  Future<void> _showAddStaffDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final bioController = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Add Staff Member', style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Full name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Email address'),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bioController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Bio / specialities (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        await ref.read(salonRepositoryProvider).recruitStaff(
                              email: emailController.text.trim(),
                              fullName: nameController.text.trim(),
                              bio: bioController.text.trim().isEmpty ? null : bioController.text.trim(),
                            );
                        ref.invalidate(staffListProvider);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (context.mounted) {
                          final message = e is ApiException ? e.message : 'Failed to add staff member';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Staff Roster', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1), onPressed: _showAddStaffDialog),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (error, _) => Center(
          child: Text('Could not load staff: $error', style: const TextStyle(color: Colors.blueGrey)),
        ),
        data: (staff) {
          if (staff.isEmpty) {
            return const Center(
              child: Text('No staff members yet. Tap + to add one.', style: TextStyle(color: Colors.blueGrey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(staffListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: staff.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildStaffCard(staff[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaffCard(StaffMember staff) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6366F1),
          child: Text(staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(staff.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (staff.email != null) Text(staff.email!, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            if (staff.specialities.isNotEmpty)
              Text(staff.specialities.join(', '), style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: staff.isAvailable ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            staff.isAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(color: staff.isAvailable ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
