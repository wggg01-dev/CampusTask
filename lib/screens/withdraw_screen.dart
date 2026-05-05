import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  num _balance = 0;
  String? _bankName;
  String? _accountNumber;

  static const num _minBalance = 2000;
  static const num _fee = 50;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    final data = await Supabase.instance.client
        .from('profiles')
        .select('available_balance_ngn, bank_name, bank_account_number')
        .eq('id', user!.id)
        .single();

    setState(() {
      _balance = data['available_balance_ngn'] ?? 0;
      _bankName = data['bank_name'];
      _accountNumber = data['bank_account_number'];
      _isLoading = false;
    });
  }

  Future<void> _requestWithdrawal() async {
    setState(() => _isSubmitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final payoutAmount = _balance - _fee;

      // 1. Log the payout request
      await Supabase.instance.client.from('payouts').insert({
        'user_id': user!.id,
        'amount_ngn': payoutAmount,
        'fee_charged': _fee,
        'status': 'pending',
      });

      // 2. Deduct only from the available balance
      await Supabase.instance.client
          .from('profiles')
          .update({'available_balance_ngn': 0}).eq('id', user.id);

      if (mounted) {
        _showSuccessDialog(payoutAmount);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(num payoutAmount) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Withdrawal Requested',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '₦${payoutAmount.toStringAsFixed(0)} will be sent to $_bankName within 7 days.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

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
          'Withdraw',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BALANCE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Balance',
                            style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 8),
                        Text(
                          '₦${_balance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CONDITION A — balance too low
                  if (_balance < _minBalance) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0x14FBBF24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x4DFBBF24)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline,
                              color: Colors.amber, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Minimum not reached',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You need ₦${(_minBalance - _balance).toStringAsFixed(0)} more to withdraw.',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // CONDITION B — balance sufficient
                  if (_balance >= _minBalance) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          _BreakdownRow(
                            label: 'Your balance',
                            value: '₦${_balance.toStringAsFixed(0)}',
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          _BreakdownRow(
                            label: 'Processing fee',
                            value: '- ₦${_fee.toStringAsFixed(0)}',
                            valueColor: Colors.redAccent,
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          _BreakdownRow(
                            label: 'You receive',
                            value: '₦${(_balance - _fee).toStringAsFixed(0)}',
                            valueColor: const Color(0xFF10B981),
                            bold: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_bankName != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_outlined,
                                color: Color(0xFF10B981), size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _bankName!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                Text(
                                  _accountNumber ?? '',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    const Text(
                      'Withdrawals are processed within 7 days.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _requestWithdrawal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          disabledBackgroundColor: const Color(0x6610B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Request Withdrawal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _BreakdownRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 16 : 13,
          ),
        ),
      ],
    );
  }
}
