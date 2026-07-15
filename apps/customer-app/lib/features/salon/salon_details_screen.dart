import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/salon.dart';
import '../../core/models/booking_draft.dart';
import '../../core/models/marketing.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class SalonDetailsScreen extends ConsumerStatefulWidget {
  final String salonId;

  const SalonDetailsScreen({super.key, required this.salonId});

  @override
  ConsumerState<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends ConsumerState<SalonDetailsScreen> {
  SalonStaff? _selectedStaff;
  SalonService? _selectedService;
  bool _isStartingChat = false;

  Future<void> _showReviewDialog(String tenantId) async {
    final ctrl = TextEditingController();
    int rating = 5;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Write a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: submitting ? null : () async {
                    setDialogState(() => submitting = true);
                    try {
                      await ref.read(marketingRepositoryProvider).createReview(
                            tenantId: tenantId,
                            rating: rating,
                            comment: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
                          );
                      ref.invalidate(salonReviewsProvider(widget.salonId));
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      setDialogState(() => submitting = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e')));
                      }
                    }
                  },
                  child: submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Review'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _messageSalon(SalonDetail detail) async {
    if (detail.ownerId == null || _isStartingChat) return;
    setState(() => _isStartingChat = true);
    try {
      final room = await ref.read(chatRepositoryProvider).startRoom(detail.ownerId!);
      if (!mounted) return;
      context.push('/chat/${room.id}', extra: detail.summary.name);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Failed to start conversation';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(salonDetailProvider(widget.salonId));

    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Failed to load salon: $error', textAlign: TextAlign.center),
          ),
        ),
        data: (detail) => _buildContent(context, theme, detail),
      ),
      floatingActionButton: _selectedService != null
          ? null
          : detailAsync.maybeWhen(
              data: (detail) => detail.ownerId == null
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: _isStartingChat ? null : () => _messageSalon(detail),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(_isStartingChat ? 'Opening…' : 'Message'),
                    ),
              orElse: () => null,
            ),
      bottomSheet: _selectedService == null
          ? null
          : _buildCheckoutBar(theme, _selectedService!),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, SalonDetail detail) {
    final salon = detail.summary;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  ref.watch(favoritesProvider).any((s) => s.id == salon.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.redAccent,
                  size: 26,
                ),
                onPressed: () => ref.read(favoritesProvider.notifier).toggle(salon),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              salon.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (salon.coverImageUrl != null)
                  Image.network(salon.coverImageUrl!, fit: BoxFit.cover)
                else
                  Container(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        salon.primaryCity ?? 'Salon',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (salon.rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${salon.rating!.toStringAsFixed(1)} (${salon.reviewCount})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (detail.branches.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(detail.branches.first.address, style: const TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  const Divider(height: 32),

                  if (detail.staff.isNotEmpty) ...[
                    const Text('Select Specialist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: detail.staff.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final staff = detail.staff[index];
                          final isSelected = _selectedStaff?.id == staff.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedStaff = staff),
                            child: Container(
                              width: 100,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: staff.profileImageUrl != null ? NetworkImage(staff.profileImageUrl!) : null,
                                    child: staff.profileImageUrl == null ? const Icon(Icons.person) : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    staff.fullName.split(' ').first,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 32),
                  ],

                  const Text('Our Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (detail.services.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('This salon hasn\'t listed any services yet.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: detail.services.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final srv = detail.services[index];
                        final isSelected = _selectedService?.id == srv.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedService = srv),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.04) : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(srv.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    ),
                                    Text(
                                      '₹${srv.price.toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('${srv.duration} min', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                                if (srv.description != null) ...[
                                  const SizedBox(height: 8),
                                  Text(srv.description!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const Divider(height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => _showReviewDialog(detail.summary.id),
                        child: const Text('Write a Review'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ref.watch(salonReviewsProvider(widget.salonId)).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Failed to load reviews: $e')),
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            separatorBuilder: (context, index) => const Divider(height: 32),
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            starIdx < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (review.comment != null && review.comment!.isNotEmpty)
                                    Text(review.comment!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                  if (review.replies.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Reply from Salon', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(review.replies.first.replyText, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(ThemeData theme, SalonService service) {
    return Consumer(
      builder: (context, ref, _) {
        final detail = ref.watch(salonDetailProvider(widget.salonId)).value;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text('₹${service.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (detail != null && detail.ownerId != null) ...[
                      IconButton.outlined(
                        onPressed: _isStartingChat ? null : () => _messageSalon(detail),
                        icon: _isStartingChat
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.chat_bubble_outline),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton(
                      onPressed: detail == null || detail.branches.isEmpty
                          ? null
                          : () {
                              context.push(
                                '/booking',
                                extra: BookingDraft(
                                  tenantId: detail.summary.id,
                                  branchId: detail.branches.first.id,
                                  salonName: detail.summary.name,
                                  service: service,
                                  staff: _selectedStaff,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Book Slot', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
