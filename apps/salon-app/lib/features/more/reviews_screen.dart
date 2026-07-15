import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/marketing.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);
  static const _border = Color(0xFF334155);

  Future<void> _showReplyDialog(SalonReview review) async {
    final ctrl = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _card,
          title: const Text('Reply to Review', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type your business reply here...',
              hintStyle: const TextStyle(color: Colors.blueGrey),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              onPressed: submitting ? null : () async {
                final reply = ctrl.text.trim();
                if (reply.isEmpty) return;
                setDialogState(() => submitting = true);
                try {
                  await ref.read(salonRepositoryProvider).replyToReview(review.id, reply);
                  ref.invalidate(salonReviewsProvider);
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
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Reply', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(salonProfileProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text('Customer Reviews', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
        error: (e, _) => Center(child: Text('Error loading profile: $e', style: const TextStyle(color: Colors.blueGrey))),
        data: (profile) {
          final reviewsAsync = ref.watch(salonReviewsProvider(profile.id));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(salonReviewsProvider(profile.id)),
            color: _accent,
            backgroundColor: _card,
            child: reviewsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
              error: (e, _) => Center(child: Text('Error loading reviews: $e', style: const TextStyle(color: Colors.blueGrey))),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_outline_rounded, color: Colors.blueGrey.shade700, size: 72),
                        const SizedBox(height: 16),
                        const Text('No reviews yet', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('Reviews from customers will appear here.', style: TextStyle(color: Colors.blueGrey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, i) {
                    final review = reviews[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                              Text(
                                review.customerName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Row(
                                children: List.generate(5, (starIdx) {
                                  return Icon(
                                    starIdx < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (review.comment != null && review.comment!.isNotEmpty)
                            Text(
                              review.comment!,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          const SizedBox(height: 12),
                          if (review.replies.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Reply:',
                                    style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    review.replies.first.replyText,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ] else
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: _accent),
                                onPressed: () => _showReplyDialog(review),
                                icon: const Icon(Icons.reply, size: 16),
                                label: const Text('Reply'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
