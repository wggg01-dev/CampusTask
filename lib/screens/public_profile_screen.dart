import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

int calculateTrust(Map<String, dynamic> profile) {
  final liked = (profile['total_tasks_liked'] as num?)?.toInt() ?? 0;
  final approved = (profile['total_tasks_approved'] as num?)?.toInt() ?? 0;
  if (approved == 0) return 0;
  return ((liked / approved) * 100).round().clamp(0, 100);
}

class PublicProfileScreen extends StatefulWidget {
  final String targetUserId;

  const PublicProfileScreen({super.key, required this.targetUserId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _reviewsFuture = Supabase.instance.client
        .from('public_reviews')
        .select('reviewer_name, rating, comment, created_at')
        .eq('reviewed_user_id', widget.targetUserId)
        .order('created_at', ascending: false)
        .limit(20);
  }

  Future<void> _loadProfile() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('nickname, profile_picture_url, total_reviews, total_tasks_liked, total_tasks_approved')
          .eq('id', widget.targetUserId)
          .single();
      if (mounted) setState(() { _profile = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _profile?['nickname'] as String? ?? 'Student Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF10B981), strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Text('Could not load profile',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 14)))
              : _buildBody(_profile!),
    );
  }

  Widget _buildBody(Map<String, dynamic> profile) {
    final nickname = profile['nickname'] as String? ?? 'Student';
    final avatarUrl = profile['profile_picture_url'] as String?;
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    final trust = calculateTrust(profile);
    final totalReviews = (profile['total_reviews'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── AVATAR ───────────────────────────────────────────────────
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
                    border:
                        Border.all(color: const Color(0xFF10B981), width: 2),
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
                fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          ),

          // ── REPUTATION CARD ───────────────────────────────────────────
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Excellence detail — the headline stat
                _buildExcellenceBlock(profile),
                const SizedBox(height: 18),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 18),
                // Supporting stats row below
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem(
                        'Trust Score', '$trust%', Icons.verified_rounded),
                    _divider(),
                    _statItem('Reviews', '$totalReviews',
                        Icons.rate_review_rounded),
                  ],
                ),
              ],
            ),
          ),

          // ── REVIEWS ───────────────────────────────────────────────────
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
                          style:
                              TextStyle(color: Colors.white38, fontSize: 13)),
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
                  final comment = review['comment'] as String? ?? '';
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
    );
  }

  Widget _buildExcellenceBlock(Map<String, dynamic> profile) {
    final liked = (profile['total_tasks_liked'] as num?)?.toInt() ?? 0;
    final approved = (profile['total_tasks_approved'] as num?)?.toInt() ?? 0;
    final ratio = approved > 0 ? liked / approved : 0.0;
    final isHealthy = liked >= (approved / 2);
    final scoreColor =
        isHealthy ? const Color(0xFF10B981) : Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$liked out of $approved',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: scoreColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$liked out of $approved tasks were liked by Taskers',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio.toDouble(),
            backgroundColor: const Color(0xFF334155),
            valueColor:
                AlwaysStoppedAnimation<Color>(scoreColor),
          ),
        ),
      ],
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
            style: const TextStyle(fontSize: 12, color: Colors.white38)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: Colors.white10);
}
