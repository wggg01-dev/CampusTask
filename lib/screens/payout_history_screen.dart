import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PayoutHistoryScreen extends StatelessWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawals')),
      body: StreamBuilder(
        stream: Supabase.instance.client
            .from('payouts')
            .stream(primaryKey: ['id'])
            .eq('user_id', user!.id)
            .order('created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final payouts = snapshot.data!;
          return ListView.builder(
            itemCount: payouts.length,
            itemBuilder: (context, i) {
              final item = payouts[i];
              return ListTile(
                title: Text('₦${item['amount_ngn']}'),
                subtitle: Text(item['created_at'].toString().split('T')[0]),
                trailing: Chip(
                  label: Text(
                    item['status'],
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: item['status'] == 'sent'
                      ? Colors.green
                      : Colors.orange,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
