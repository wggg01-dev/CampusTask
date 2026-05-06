import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_screen.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isAccepting = false;

  static const List<_Rule> _rules = [
    _Rule(
      number: '1',
      title: 'One Person = One Account',
      body: 'Use your own information. Creating multiple accounts is a permanent ban.',
      icon: Icons.person_outline,
    ),
    _Rule(
      number: '2',
      title: 'Same Phone = Ban',
      body: "Don't help your friend sign up on your phone. Each device is linked to one account.",
      icon: Icons.phone_android,
    ),
    _Rule(
      number: '3',
      title: 'Withdrawal: 7 Days After Task',
      body: 'Banks take time to confirm. Withdrawals are processed 7 days after task completion.',
      icon: Icons.schedule,
    ),
    _Rule(
      number: '4',
      title: 'Fake Proof = Permanent Ban',
      body: 'We check with the platforms directly. Submitting false proof results in an immediate and permanent ban.',
      icon: Icons.gpp_bad_outlined,
    ),
    _Rule(
      number: '5',
      title: 'Referral Bonus: ₦500',
      body: 'You earn ₦500 when your referred friend completes more than 2 high-priority tasks.',
      icon: Icons.group_add_outlined,
    ),
  ];

  static const List<_HowToStep> _steps = [
    _HowToStep(
      number: '1',
      title: 'Complete Task',
      body: 'Go to the Tasks tab, pick any active task, and complete it exactly as described. HOT tasks pay more.',
    ),
    _HowToStep(
      number: '2',
      title: 'Wait for Review',
      body: 'Your earnings land in Pending Balance while we verify your submission directly with the platform. This takes up to 7 days.',
    ),
    _HowToStep(
      number: '3',
      title: 'Get Paid Instantly',
      body: 'Once verified, your money moves straight to your Available Balance — no delays, no extra steps.',
    ),
    _HowToStep(
      number: '4',
      title: 'Withdraw to Your Bank',
      body: 'Hit ₦2,000 and tap Withdraw on the Home screen. Make sure your bank details are saved in your Profile first.',
    ),
    _HowToStep(
      number: '5',
      title: 'Invite Friends to Earn More',
      body: 'Share your referral code from the Leaderboard tab. Every friend who completes 2+ high-priority tasks earns you ₦500 automatically.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 40) {
      if (!_hasScrolledToBottom) {
        setState(() => _hasScrolledToBottom = true);
      }
    }
  }

  Future<void> _acceptRules() async {
    setState(() => _isAccepting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('profiles').update({
        'has_accepted_rules': true,
        'rules_accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', user!.id);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0x1F10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: Color(0xFF10B981),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CampusTask Rules',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Read carefully before you start earning.\nNo payment without agreement.',
                    style: TextStyle(color: Colors.white54, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // SCROLL HINT
            if (!_hasScrolledToBottom)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Scroll to read everything',
                      style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // SCROLLABLE CONTENT
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  // ── RULES ──────────────────────────────────────────────
                  ...List.generate(_rules.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RuleTile(rule: _rules[i]),
                    );
                  }),

                  const _WarningBanner(),

                  const SizedBox(height: 28),

                  // ── HOW IT WORKS ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x2210B981)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: Color(0xFFFBBF24), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'How It Works',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Six steps from sign-up to your first withdrawal.',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        ...List.generate(_steps.length, (i) {
                          final step = _steps[i];
                          final isLast = i == _steps.length - 1;
                          return _HowToStepTile(step: step, isLast: isLast);
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ACCEPT BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_hasScrolledToBottom && !_isAccepting)
                      ? _acceptRules
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor: const Color(0x4010B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _hasScrolledToBottom
                              ? 'I Understand — Let Me Earn'
                              : 'Read Everything to Continue',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rule tile ────────────────────────────────────────────────────────────────

class _Rule {
  final String number;
  final String title;
  final String body;
  final IconData icon;
  const _Rule(
      {required this.number,
      required this.title,
      required this.body,
      required this.icon});
}

class _RuleTile extends StatelessWidget {
  final _Rule rule;
  const _RuleTile({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x1F10B981),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(rule.icon, color: const Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rule ${rule.number}: ${rule.title}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rule.body,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x14FF5252),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DFF5252)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Break any rule = No payment. We don\'t negotiate on fraud.',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── How-To step ──────────────────────────────────────────────────────────────

class _HowToStep {
  final String number;
  final String title;
  final String body;
  const _HowToStep(
      {required this.number, required this.title, required this.body});
}

class _HowToStepTile extends StatelessWidget {
  final _HowToStep step;
  final bool isLast;
  const _HowToStepTile({required this.step, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STEP NUMBER + CONNECTOR LINE
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0x2210B981),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  step.number,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white10,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // CONTENT
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.body,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
