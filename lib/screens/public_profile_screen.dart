import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

int calculateTrust(Map<String, dynamic> profile) {
  final likes = (profile['likes_count'] as num?)?.toInt() ?? 0;
  final completed = (profile['completed_tasks'] as num?)?.toInt() ?? 0;
  return (likes * 3 + completed * 5).clamp(0, 100);
}

class PublicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const PublicProfileScreen({super.key, required this.profileData});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    final userId = widget.profileData['id']?.toString();
    _reviewsFuture = userId != null
        ? Supabase.instance.client
            .from('public_reviews')
            .select('reviewer_name, rating, comment, created_at')
            .eq('reviewed_user_id', userId)
            .order('created_at', ascending: false)
            .limit(20)
        : Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profileData;
    final nickname = profile['nickname'] as String? ?? 'Student';
    final avatarUrl = profile['profile_picture_url'] as String?;
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    final trust = calculateTrust(profile);
    final likes = (profile['likes_count'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          nickname,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── AVATAR ─────────────────────────────────────────────────
            avatarUrl != null
                ? CircleAvatar(
                    radius: 52,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: const Color(0xFF1E293B),
                  )
                : Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF10B981), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981)),
                      ),
                    ),
                  ),

            const SizedBox(height: 12),
            Text(
              '@$nickname',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              profile['location'] as String? ?? '',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),

            // ── STATS ROW ───────────────────────────────────────────────
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem('Likes', '$likes',
                      Icons.thumb_up_alt_rounded),
                  _divider(),
                  _statItem('Trust Score', '$trust%',
                      Icons.verified_rounded),
                ],
              ),
            ),

            // ── REVIEWS ─────────────────────────────────────────────────
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reviews from Taskers',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: CircularProgressIndicator(
                        color: Color(0xFF10B981), strokeWidth: 2),
                  );
                }

                final reviews = snapshot.data ?? [];

                if (reviews.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: const [
                        Icon(Icons.rate_review_outlined,
                            color: Colors.white24, size: 36),
                        SizedBox(height: 10),
                        Text('No reviews yet',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final rating =
                        (review['rating'] as num?)?.toInt() ?? 0;
                    final comment =
                        review['comment'] as String? ?? '';
                    final reviewer =
                        review['reviewer_name'] as String? ?? 'Tasker';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_rounded,
                                  color: Colors.white38, size: 14),
                              const SizedBox(width: 6),
                              Text(reviewer,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: i < rating
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white24,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(comment,
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    height: 1.4)),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981))),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Colors.white38)),
      ],
    );
  }

  Widget _divider() {
    return Container(
        width: 1, height: 40, color: Colors.white10);
  }
}
