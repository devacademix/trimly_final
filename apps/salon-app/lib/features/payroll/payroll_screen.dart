import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/payroll.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  Future<void> _markAsPaid(String staffId) async {
    try {
      await ref.read(payrollRepositoryProvider).markAsPaid(staffId, selectedMonth, selectedYear);
      ref.invalidate(monthlyPayrollProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as PAID!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateCommission(StaffPayrollResult staff) async {
    final formKey = GlobalKey<FormState>();
    final baseController = TextEditingController(text: staff.baseSalary.toString());
    final commController = TextEditingController(text: staff.commissionRate.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Edit Commission for ${staff.name}', style: const TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: baseController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Base Salary (₹)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: commController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Commission Rate (%)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final base = double.tryParse(baseController.text) ?? 0.0;
                final comm = double.tryParse(commController.text) ?? 0.0;
                await ref.read(payrollRepositoryProvider).updateCommission(staff.staffId, base, comm);
                ref.invalidate(monthlyPayrollProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payrollAsync = ref.watch(monthlyPayrollProvider({'month': selectedMonth, 'year': selectedYear}));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Payroll & Commission', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Period:', style: TextStyle(color: Colors.white, fontSize: 16)),
                DropdownButton<int>(
                  dropdownColor: const Color(0xFF1E293B),
                  value: selectedMonth,
                  style: const TextStyle(color: Colors.white),
                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Month ${i + 1}'))),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedMonth = val);
                  },
                ),
                DropdownButton<int>(
                  dropdownColor: const Color(0xFF1E293B),
                  value: selectedYear,
                  style: const TextStyle(color: Colors.white),
                  items: [selectedYear - 1, selectedYear, selectedYear + 1]
                      .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedYear = val);
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: payrollAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (staffList) {
                if (staffList.isEmpty) {
                  return const Center(child: Text('No staff found.', style: TextStyle(color: Colors.white)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    final isPaid = staff.status == 'PAID';
                    
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(staff.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                  onPressed: () => _updateCommission(staff),
                                )
                              ],
                            ),
                            const Divider(color: Colors.blueGrey),
                            const SizedBox(height: 8),
                            _buildRow('Base Salary:', '₹${staff.baseSalary.toStringAsFixed(2)}'),
                            _buildRow('Commission (${staff.commissionRate}%):', '₹${staff.commissionAmount.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            _buildRow('Total Payout:', '₹${staff.totalAmount.toStringAsFixed(2)}', isBold: true),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    staff.status,
                                    style: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (!isPaid)
                                  ElevatedButton(
                                    onPressed: () => _markAsPaid(staff.staffId),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                                    child: const Text('Mark as Paid', style: TextStyle(color: Colors.white)),
                                  )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
