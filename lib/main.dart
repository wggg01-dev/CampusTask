import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/signup_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xbutdfqkvigwxrwgoyuy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhidXRkZnFrdmlnd3hyd2dveXV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MTI1OTYsImV4cCI6MjA5MzM4ODU5Nn0.RKvb4lmxkl8TseYCXaWqTIXdhgdb0bW_TDNrKYgPpmE',
  );

  runApp(const CampusTaskApp());
}

class CampusTaskApp extends StatefulWidget {
  const CampusTaskApp({super.key});

  @override
  State<CampusTaskApp> createState() => _CampusTaskAppState();
}

class _CampusTaskAppState extends State<CampusTaskApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle link that cold-started the app
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleUri(initialUri);

    // Handle links while the app is already running
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    final ref = uri.queryParameters['ref'];
    if (ref != null && ref.isNotEmpty) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => SignupScreen(initialReferralCode: ref.toUpperCase()),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
          return const MainScreen();
        }
        return const RulesScreen();
      },
    );
  }
}
