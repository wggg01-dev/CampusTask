import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bank_setup_screen.dart';
import 'payout_history_screen.dart';

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
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: Supabase.instance.client
                        .from('profiles')
                        .stream(primaryKey: ['id'])
                        .eq('id', user!.id),
                    builder: (context, snapshot) {
                      final balance =
                          snapshot.data?.first['total_earned_ngn'] ?? 0;
                      return Text(
                        '₦$balance.00',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
