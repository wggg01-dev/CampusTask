import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/rules_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xbutdfqkvigwxrwgoyuy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhidXRkZnFrdmlnd3hyd2dveXV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MTI1OTYsImV4cCI6MjA5MzM4ODU5Nn0.RKvb4lmxkl8TseYCXaWqTIXdhgdb0bW_TDNrKYgPpmE',
  );

  runApp(const CampusTaskApp());
}

class CampusTaskApp extends StatelessWidget {
  const CampusTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusTask',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) {
          return const _RulesGate();
        }
        return const LoginScreen();
      },
    );
  }
}

// Checks whether the logged-in user has accepted the rules.
// Shows RulesScreen once on first login, then goes straight to Dashboard.
class _RulesGate extends StatelessWidget {
  const _RulesGate();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return FutureBuilder(
      future: Supabase.instance.client
          .from('profiles')
          .select('has_accepted_rules')
          .eq('id', user!.id)
          .single(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final hasAccepted = snapshot.data?['has_accepted_rules'] == true;
        if (hasAccepted) {
          return const DashboardScreen();
        }
        return const RulesScreen();
      },
    );
  }
}
