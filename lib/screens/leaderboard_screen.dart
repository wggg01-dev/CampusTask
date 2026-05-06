import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: StreamBuilder(
        stream: Supabase.instance.client
            .from('profiles')
            .stream(primaryKey: ['id']).eq('id', user!.id),
        builder: (context, profileSnap) {
          final profile = profileSnap.data?.first;
          final refCode = profile?['ref_code'] as String?;
          final referralCount = profile?['referral_count'] as int? ?? 0;
          final referralEarnings =
              profile?['referral_earnings_ngn'] as num? ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── YOUR REFERRAL STATS ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x3310B981)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.card_giftcard_outlined,
                              color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Your Referral',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // STATS ROW
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Friends Invited',
                              value: '$referralCount',
                              icon: Icons.group_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              label: 'Referral Earned',
                              value: '₦${referralEarnings.toStringAsFixed(0)}',
                              icon: Icons.savings_outlined,
                              valueColor: const Color(0xFF4ADE80),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 14),

                      // EARN DESCRIPTION
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.6),
                          children: [
                            TextSpan(text: 'Invite a friend and earn '),
                            TextSpan(
                              text: '₦500',
                              style: TextStyle(
                                color: Color(0xFFFB923C),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                                text:
                                    ' once they complete more than 2 high-priority tasks.'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // REFERRAL CODE BOX
                      if (refCode != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  refCode,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Copy code',
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: refCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Referral code copied!')),
                                );
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF334155),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.copy,
                                  color: Colors.white70, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Share.share(
                                'Join me on CampusTask and start earning! Use my referral code $refCode to sign up:\nhttps://campustask.app/signup?ref=$refCode',
                                subject: 'Earn money with CampusTask',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.share,
                                color: Colors.white, size: 18),
                            label: const Text(
                              'Share Invite Link',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── TOP EARNERS ───────────────────────────────────────────
                const Text(
                  'Top Earners',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Refer more friends to climb the ranks.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 14),

                FutureBuilder(
                  future: Supabase.instance.client
                      .from('referral_stats')
                      .select()
                      .order('referral_earnings_ngn', ascending: false)
                      .limit(10),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    final leaders = snapshot.data as List;

                    if (leaders.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No entries yet. Be the first top earner!',
                          style: TextStyle(color: Colors.white38),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return Column(
                      children: List.generate(leaders.length, (index) {
                        final entry = leaders[index];
                        final earnings =
                            entry['referral_earnings_ngn'] as num? ?? 0;
                        final referrals =
                            entry['referral_count'] as int? ?? 0;
                        final isCurrentUser =
                            entry['id'] == user.id;
                        final rank = index + 1;

                        Color rankColor = Colors.white38;
                        IconData rankIcon = Icons.emoji_events_outlined;
                        if (rank == 1) {
                          rankColor = const Color(0xFFFFD700);
                          rankIcon = Icons.emoji_events;
                        } else if (rank == 2) {
                          rankColor = const Color(0xFFB0BEC5);
                          rankIcon = Icons.emoji_events;
                        } else if (rank == 3) {
                          rankColor = const Color(0xFFCD7F32);
                          rankIcon = Icons.emoji_events;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? const Color(0xFF0D3D2F)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrentUser
                                  ? const Color(0x5510B981)
                                  : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: rank <= 3
                                    ? Icon(rankIcon,
                                        color: rankColor, size: 22)
                                    : Text(
                                        '#$rank',
                                        style: TextStyle(
                                          color: rankColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCurrentUser ? 'You' : 'User #$rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isCurrentUser
                                            ? const Color(0xFF10B981)
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$referrals friend${referrals == 1 ? '' : 's'} invited',
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₦${earnings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
