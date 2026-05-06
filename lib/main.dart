import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'screens/bio_data_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/otp_screen.dart';
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
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleUri(initialUri);
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

// ── Auth gate ─────────────────────────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) return const _OnboardingGate();
        return const LoginScreen();
      },
    );
  }
}

// ── Onboarding gate (reactive via StreamBuilder on profiles) ──────────────────
//
// Chain:  bio missing  →  BioDataScreen
//         unverified   →  OtpScreen
//         rules pending →  RulesScreen
//         all done     →  MainScreen

class _OnboardingGate extends StatelessWidget {
  const _OnboardingGate();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser!;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id']).eq('id', user.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data!.first;
        final fullName = profile['full_name'] as String?;
        final phoneVerified = profile['phone_verified'] == true;
        final hasAcceptedRules = profile['has_accepted_rules'] == true;
        final phone = profile['phone'] as String?;

        // 1. Bio-data missing
        if (fullName == null || fullName.trim().isEmpty) {
          return const BioDataScreen();
        }

        // 2. Phone not verified
        if (!phoneVerified) {
          return OtpScreen(phone: phone ?? '');
        }

        // 3. Rules not yet accepted
        if (!hasAcceptedRules) {
          return const RulesScreen();
        }

        // 4. All good
        return const MainScreen();
      },
    );
  }
}
