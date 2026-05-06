import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _email;
  String? _refCode;
  int _referralCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _email = user.email;

    // Fetch ref_code from profiles
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('ref_code')
        .eq('id', user.id)
        .single();

    // Count how many users were referred by this user
    final referred = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('referred_by', user.id);

    if (mounted) {
      setState(() {
        _refCode = profile['ref_code'] as String?;
        _referralCount = (referred as List).length;
        _isLoading = false;
      });
    }
  }

  num get _totalEarned => _referralCount * 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AVATAR + EMAIL
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF1E293B),
                          child: Text(
                            (_email?.isNotEmpty == true)
                                ? _email![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // REFERRAL STATS
                  const Text(
                    'Referral Stats',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      // FRIENDS REFERRED
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.people_outline,
                                  color: Color(0xFF10B981), size: 22),
                              const SizedBox(height: 10),
                              Text(
                                '$_referralCount',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Friends Referred',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // TOTAL EARNED
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.savings_outlined,
                                  color: Color(0xFFFB923C), size: 22),
                              const SizedBox(height: 10),
                              Text(
                                '₦${_totalEarned.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFB923C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Earned from Referrals',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // PER-REFERRAL NOTE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFB923C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x4DFB923C)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFFB923C), size: 16),
                        const SizedBox(width: 10),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                height: 1.4),
                            children: [
                              TextSpan(text: 'You earn '),
                              TextSpan(
                                text: '₦500',
                                style: TextStyle(
                                  color: Color(0xFFFB923C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                  text: ' for every friend who joins using your code.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // MY REFERRAL CODE
                  const Text(
                    'My Referral Code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_refCode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x3310B981)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _refCode!,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _refCode!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Referral code copied!')),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(
                                        color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy Code'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Share.share(
                                      'Join me on CampusTask and start earning! Use my referral code $_refCode to sign up: https://campustask.app/signup?ref=$_refCode',
                                      subject: 'Earn money with CampusTask',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.share,
                                      color: Colors.white, size: 16),
                                  label: const Text(
                                    'Share',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
