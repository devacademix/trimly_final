import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/marketing.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);
  static const _border = Color(0xFF334155);

  Future<void> _showCreateCouponDialog() async {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    String type = 'FLAT'; // FLAT or PERCENTAGE
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(days: 30));
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Create Coupon', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _field('Coupon Code (e.g. SAVE50) *', codeCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: type,
                          dropdownColor: _card,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Discount Type',
                            labelStyle: const TextStyle(color: Colors.blueGrey),
                            filled: true, fillColor: _bg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'FLAT', child: Text('Flat (₹)')),
                            DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage (%)')),
                          ],
                          onChanged: (v) => type = v ?? type,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field('Value *', valueCtrl, keyboardType: TextInputType.number, validator: (v) => double.tryParse(v ?? '') == null ? 'Enter number' : null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field('Usage Limit (Optional)', limitCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: _border)),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: start,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setDialogState(() => start = date);
                          },
                          icon: const Icon(Icons.calendar_month, color: _accent),
                          label: Text('Starts: ${start.day}/${start.month}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: _border)),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: end,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setDialogState(() => end = date);
                          },
                          icon: const Icon(Icons.calendar_month, color: _accent),
                          label: Text('Ends: ${end.day}/${end.month}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _accent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: submitting ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => submitting = true);
                        try {
                          await ref.read(salonRepositoryProvider).createCoupon({
                            'code': codeCtrl.text.trim().toUpperCase(),
                            'discountType': type,
                            'value': double.parse(valueCtrl.text.trim()),
                            'usageLimit': limitCtrl.text.trim().isEmpty ? null : int.parse(limitCtrl.text.trim()),
                            'startDate': start.toIso8601String(),
                            'endDate': end.toIso8601String(),
                          });
                          ref.invalidate(marketingCouponsProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setDialogState(() => submitting = false);
                          if (ctx.mounted) {
                            final msg = e is ApiException ? e.message : '$e';
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
                          }
                        }
                      },
                      child: submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
        filled: true, fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(marketingCouponsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text('Coupons & Offers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: _accent),
            onPressed: _showCreateCouponDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(marketingCouponsProvider),
        color: _accent,
        backgroundColor: _card,
        child: couponsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
          error: (e, _) => Center(child: Text('Error loading coupons: $e', style: const TextStyle(color: Colors.blueGrey))),
          data: (coupons) {
            if (coupons.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_outlined, color: Colors.blueGrey.shade700, size: 72),
                    const SizedBox(height: 16),
                    const Text('No coupons yet', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Tap + to create your first discount coupon', style: TextStyle(color: Colors.blueGrey)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: coupons.length,
              itemBuilder: (context, i) {
                final coupon = coupons[i];
                final isFlat = coupon.discountType == 'FLAT';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.local_offer_rounded, color: _accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  coupon.code,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: coupon.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    coupon.isActive ? 'Active' : 'Expired',
                                    style: TextStyle(color: coupon.isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isFlat ? '₹${coupon.value.toStringAsFixed(0)} Flat Discount' : '${coupon.value.toStringAsFixed(0)}% Percentage Discount',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Valid: ${coupon.startDate.day}/${coupon.startDate.month} to ${coupon.endDate.day}/${coupon.endDate.month}',
                              style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${coupon.usedCount}${coupon.usageLimit != null ? '/${coupon.usageLimit}' : ''}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Text(
                            'Used',
                            style: TextStyle(color: Colors.blueGrey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
