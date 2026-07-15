import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/booking.dart';
import '../../core/models/dashboard_stats.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

// Currency formatter
final _rupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class SalonDashboardScreen extends ConsumerStatefulWidget {
  const SalonDashboardScreen({super.key});

  @override
  ConsumerState<SalonDashboardScreen> createState() => _SalonDashboardScreenState();
}

class _SalonDashboardScreenState extends ConsumerState<SalonDashboardScreen> {
  bool _shopOpen = true;
  bool _togglingShop = false;

  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);
  static const _border = Color(0xFF334155);

  Future<void> _toggleShop(bool val) async {
    setState(() => _togglingShop = true);
    try {
      await ref.read(salonRepositoryProvider).updateShopStatus(val);
      setState(() => _shopOpen = val);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Failed to update shop status';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _togglingShop = false);
    }
  }

  Future<void> _updateBookingStatus(Booking booking, BookingStatus status) async {
    try {
      await ref.read(bookingRepositoryProvider).updateStatus(booking.id, status);
      ref.invalidate(bookingsListProvider);
      ref.invalidate(dashboardStatsProvider);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Failed to update booking';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final bookingsAsync = ref.watch(bookingsListProvider);
    final profileAsync = ref.watch(salonProfileProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(profileAsync),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(bookingsListProvider);
          ref.invalidate(salonProfileProvider);
        },
        color: _accent,
        backgroundColor: _card,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats Grid ────────────────────────────────────────────────
              statsAsync.when(
                loading: () => _buildStatsShimmer(),
                error: (_, __) => _buildStatsError(),
                data: (stats) => _buildStatsGrid(stats),
              ),
              const SizedBox(height: 24),

              // ── Quick Actions ─────────────────────────────────────────────
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // ── Upcoming Appointments ─────────────────────────────────────
              _buildSectionHeader('Upcoming Appointments', onTap: () => context.push('/bookings-list')),
              const SizedBox(height: 12),
              bookingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
                error: (e, _) => _buildErrorText('Could not load appointments'),
                data: (bookings) => _buildBookingsList(bookings),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(AsyncValue profileAsync) {
    return AppBar(
      backgroundColor: _card,
      elevation: 0,
      titleSpacing: 16,
      title: profileAsync.when(
        loading: () => const Text('Trimly Business', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        error: (_, __) => const Text('Trimly Business', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        data: (profile) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            Text(profile.city ?? 'Trimly Business', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          ],
        ),
      ),
      actions: [
        _buildShopToggle(),
        const SizedBox(width: 8),
        // Notification icon
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildShopToggle() {
    return GestureDetector(
      onTap: _togglingShop ? null : () => _toggleShop(!_shopOpen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _shopOpen ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _shopOpen ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4)),
        ),
        child: _togglingShop
            ? const SizedBox(width: 40, height: 16, child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _shopOpen ? Colors.green : Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(_shopOpen ? 'Open' : 'Closed', style: TextStyle(color: _shopOpen ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard("Today's Bookings", '${stats.todayBookingsCount}', Icons.calendar_today_rounded, const Color(0xFF6366F1))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Monthly Revenue", _rupee.format(stats.salonRevenue), Icons.currency_rupee_rounded, const Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard("Monthly Bookings", '${stats.monthlyBookingsCount}', Icons.event_note_rounded, const Color(0xFFF59E0B))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Avg Order Value", _rupee.format(stats.averageOrderValue), Icons.trending_up_rounded, const Color(0xFFEC4899))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              Icon(Icons.trending_up_rounded, color: Colors.green.shade400, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatsShimmer() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildShimmerCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildShimmerCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildShimmerCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildShimmerCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Center(child: Container(width: 40, height: 40, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(8)))),
    );
  }

  Widget _buildStatsError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(child: Text('Pull to refresh analytics', style: const TextStyle(color: Colors.blueGrey))),
          TextButton(onPressed: () => ref.invalidate(dashboardStatsProvider), child: const Text('Retry', style: TextStyle(color: _accent))),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('New Booking', Icons.add_circle_rounded, const Color(0xFF6366F1), () => context.push('/bookings-list')),
      _QuickAction('Services', Icons.content_cut_rounded, const Color(0xFF10B981), () => context.push('/services')),
      _QuickAction('Staff', Icons.people_rounded, const Color(0xFFF59E0B), () => context.push('/staff')),
      _QuickAction('Profile', Icons.store_rounded, const Color(0xFFEC4899), () => context.push('/salon-profile')),
      _QuickAction('Analytics', Icons.bar_chart_rounded, const Color(0xFF14B8A6), () => context.push('/analytics')),
      _QuickAction('Customers', Icons.group_rounded, const Color(0xFF8B5CF6), () => context.push('/customers')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Access', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.0, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: actions.length,
          itemBuilder: (context, i) {
            final a = actions[i];
            return GestureDetector(
              onTap: a.onTap,
              child: Container(
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: a.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(a.icon, color: a.color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(a.label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Text('View All', style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    final upcoming = bookings
        .where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final visible = upcoming.take(5).toList();

    if (visible.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_available_rounded, color: Colors.blueGrey.shade600, size: 48),
              const SizedBox(height: 12),
              const Text('No upcoming appointments', style: TextStyle(color: Colors.blueGrey)),
              const Text('Your schedule is clear today!', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildBookingCard(visible[i]),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isPending = booking.status == BookingStatus.pending;
    final timeStr = DateFormat('hh:mm a').format(booking.startTime);
    final dateStr = DateFormat('MMM d').format(booking.startTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPending ? Colors.amber.withOpacity(0.3) : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: _accent.withOpacity(0.15),
                child: Text(
                  (booking.customerName ?? 'C').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: _accent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(booking.serviceName, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.amber.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isPending ? Colors.amber.withOpacity(0.4) : Colors.green.withOpacity(0.4)),
                ),
                child: Text(booking.status.label, style: TextStyle(color: isPending ? Colors.amber : Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time + Staff + Price row
          Row(
            children: [
              _infoChip(Icons.access_time_rounded, '$timeStr · $dateStr'),
              const SizedBox(width: 8),
              if (booking.staffName != null) _infoChip(Icons.person_rounded, booking.staffName!),
              const Spacer(),
              Text('₹${booking.totalPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          // Accept/Decline for pending
          if (isPending) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateBookingStatus(booking, BookingStatus.cancelled),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateBookingStatus(booking, BookingStatus.confirmed),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
      ],
    );
  }

  Widget _buildErrorText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.blueGrey))),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}
