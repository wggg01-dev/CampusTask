import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bank_setup_screen.dart';
import 'payout_history_screen.dart';
import 'spin_wheel_screen.dart';
import 'withdraw_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CampusTask',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.casino_outlined),
            tooltip: 'Daily Spin',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SpinWheelScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_circle_up_outlined),
            tooltip: 'Withdraw',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WithdrawScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Withdrawal History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PayoutHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_outlined),
            tooltip: 'Bank Setup',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BankSetupScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BALANCE CARD
            StreamBuilder(
              stream: Supabase.instance.client
                  .from('profiles')
                  .stream(primaryKey: ['id'])
                  .eq('id', user!.id),
              builder: (context, snapshot) {
                final data = snapshot.data?.first;
                final available = data?['available_balance_ngn'] ?? 0;
                final pending = data?['pending_balance_ngn'] ?? 0;

                return Container(
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
                      // AVAILABLE BALANCE
                      const Text(
                        'Available Balance',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₦${available.toString()}.00',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),

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
                                    color: Colors.white54, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₦${pending.toString()}.00',
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
                );
              },
            ),

            const SizedBox(height: 32),
            const Text(
              'Available Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // SEARCH BAR
            TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search tasks or apps...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.close, color: Colors.white38, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // TASK LIST
            FutureBuilder<List<Map<String, dynamic>>>(
              future: Supabase.instance.client
                  .from('tasks')
                  .select(
                      'app_name, title, user_payout_ngn, task_type, slots_left, is_active, created_at, priority_level')
                  .eq('is_active', true)
                  .order('priority_level', ascending: false)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Could not load tasks.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                final allTasks = snapshot.data ?? [];

                final tasks = _searchQuery.isEmpty
                    ? allTasks
                    : allTasks.where((t) {
                        final title =
                            (t['title'] as String? ?? '').toLowerCase();
                        final appName =
                            (t['app_name'] as String? ?? '').toLowerCase();
                        return title.contains(_searchQuery) ||
                            appName.contains(_searchQuery);
                      }).toList();

                if (tasks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No tasks available right now. Check back soon!'
                          : 'No tasks match "$_searchQuery".',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final title = task['title'] as String? ?? 'Task';
                    final appName = task['app_name'] as String? ?? '';
                    final payout = task['user_payout_ngn'];
                    final taskType = task['task_type'] as String? ?? '';
                    final slotsLeft = task['slots_left'] as int?;
                    final priority = task['priority_level'] as int? ?? 0;
                    final isHighPriority = priority >= 8;
                    final noSlots = slotsLeft != null && slotsLeft <= 0;

                    return Opacity(
                      opacity: noSlots ? 0.45 : 1.0,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isHighPriority
                              ? const BorderSide(
                                  color: Color(0xFFFBBF24), width: 1)
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF334155),
                                child: Icon(
                                  Icons.bolt,
                                  color: isHighPriority
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFF4ADE80),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (appName.isNotEmpty)
                                          Text(
                                            appName,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        if (isHighPriority) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0x33FBBF24),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'HOT',
                                              style: TextStyle(
                                                color: Color(0xFFFBBF24),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (payout != null)
                                          Text(
                                            '₦${payout.toString()}',
                                            style: const TextStyle(
                                              color: Color(0xFF4ADE80),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
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
                                            child: Text(
                                              taskType,
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (slotsLeft != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            noSlots
                                                ? 'Full'
                                                : '$slotsLeft slots left',
                                            style: TextStyle(
                                              color: noSlots
                                                  ? Colors.redAccent
                                                  : Colors.white38,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white38),
                            ],
                          ),
                        ),
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
}
