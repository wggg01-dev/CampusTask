import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bank_setup_screen.dart';
import 'payout_history_screen.dart';
import 'spin_wheel_screen.dart';
import 'withdraw_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                          color: Color(0xFF4ADE80), // Bright green — ready to cash out
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
                                  color: Color(0xFFFBBF24), // Amber — earning, almost there
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.amber.withOpacity(0.3)),
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
            const SizedBox(height: 16),

            // TASK LIST (Placeholder)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF334155),
                      child: Icon(Icons.bolt, color: Colors.amber),
                    ),
                    title: const Text('Complete Survey #1'),
                    subtitle: const Text('Earn approx. ₦850'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open Offerwall
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
