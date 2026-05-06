import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'spin_wheel_screen.dart';
import 'withdraw_screen.dart';
import 'payout_history_screen.dart';

class HomeTab extends StatelessWidget {
  final void Function(int) onNavigate;
  const HomeTab({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CampusTask',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.casino_outlined, color: Color(0xFF10B981)),
            tooltip: 'Daily Spin',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SpinWheelScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: Supabase.instance.client
            .from('profiles')
            .stream(primaryKey: ['id']).eq('id', user!.id),
        builder: (context, snapshot) {
          final data = snapshot.data?.first;
          final available = (data?['available_balance_ngn'] ?? 0) as num;
          final pending = (data?['pending_balance_ngn'] ?? 0) as num;
          const withdrawMin = 2000;
          final progress = (available / withdrawMin).clamp(0.0, 1.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── BALANCE CARD ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₦${available.toStringAsFixed(0)}.00',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ₦2,000 WITHDRAWAL PROGRESS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress to withdrawal',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                          Text(
                            '₦${available.toStringAsFixed(0)} / ₦2,000',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF334155),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0
                                ? const Color(0xFF10B981)
                                : const Color(0xFF4ADE80),
                          ),
                        ),
                      ),
                      if (progress >= 1.0) ...[
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF10B981), size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Ready to withdraw!',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),

                      // PENDING BALANCE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pending Balance',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₦${pending.toStringAsFixed(0)}.00',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFBBF24),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFBBF24),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0x4DFBBF24)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.schedule,
                                    color: Colors.amber, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  '7-day hold',
                                  style: TextStyle(
                                      color: Colors.amber, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── ACTION BUTTONS ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const WithdrawScreen()),
                        ),
                        icon: const Icon(Icons.arrow_circle_up_outlined,
                            color: Colors.white, size: 18),
                        label: const Text(
                          'Withdraw',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PayoutHistoryScreen()),
                        ),
                        icon: const Icon(Icons.history,
                            color: Colors.white54, size: 18),
                        label: const Text(
                          'History',
                          style: TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── INVITE BANNER ─────────────────────────────────────────
                GestureDetector(
                  onTap: () => onNavigate(2),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D3D2F), Color(0xFF134E3F)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x4410B981)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.card_giftcard_outlined,
                            color: Color(0xFF10B981), size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invite Friends — Earn ₦500 Each',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tap to see your code & leaderboard',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: Color(0xFF10B981), size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── QUICK TASKS PREVIEW ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quick Tasks',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => onNavigate(1),
                      child: const Text(
                        'See All →',
                        style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: Supabase.instance.client
                      .from('tasks')
                      .select(
                          'app_name, title, user_payout_ngn, task_type, slots_left, priority_level')
                      .eq('is_active', true)
                      .order('priority_level', ascending: false)
                      .order('created_at', ascending: false)
                      .limit(3),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final tasks = snapshot.data ?? [];
                    if (tasks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'No tasks right now. Check back soon!',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      );
                    }
                    return Column(
                      children: tasks.map((task) {
                        final title = task['title'] as String? ?? 'Task';
                        final appName = task['app_name'] as String? ?? '';
                        final payout = task['user_payout_ngn'];
                        final taskType = task['task_type'] as String? ?? '';
                        final slotsLeft = task['slots_left'] as int?;
                        final priority = task['priority_level'] as int? ?? 0;
                        final isHot = priority >= 8;
                        final noSlots = slotsLeft != null && slotsLeft <= 0;

                        return Opacity(
                          opacity: noSlots ? 0.45 : 1.0,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isHot
                                    ? const Color(0x66FBBF24)
                                    : Colors.white10,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF334155),
                                  child: Icon(Icons.bolt,
                                      size: 18,
                                      color: isHot
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFF4ADE80)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        if (appName.isNotEmpty)
                                          Text(appName,
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11)),
                                        if (isHot) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0x33FBBF24),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text('HOT',
                                                style: TextStyle(
                                                    color: Color(0xFFFBBF24),
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                      ]),
                                      const SizedBox(height: 2),
                                      Text(title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        if (payout != null)
                                          Text('₦${payout.toString()}',
                                              style: const TextStyle(
                                                  color: Color(0xFF4ADE80),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                        if (taskType.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF334155),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(taskType,
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 10)),
                                          ),
                                        ],
                                      ]),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.white24, size: 20),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => onNavigate(1),
                    child: const Text(
                      'View All Tasks →',
                      style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
