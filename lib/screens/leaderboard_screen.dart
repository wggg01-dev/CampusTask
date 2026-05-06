import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Top Earners'), backgroundColor: Colors.transparent),
      body: FutureBuilder(
        // Fetching from the SQL View we built
        future: Supabase.instance.client
            .from('referral_stats')
            .select()
            .order('referral_earnings_ngn', ascending: false)
            .limit(10),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final leaders = snapshot.data as List;
          return ListView.builder(
            itemCount: leaders.length,
            itemBuilder: (context, index) {
              final user = leaders[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text('User ${user['id'].toString().substring(0, 5)}...', 
                  style: const TextStyle(color: Colors.white)),
                trailing: Text('₦${user['referral_earnings_ngn']}', 
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}
