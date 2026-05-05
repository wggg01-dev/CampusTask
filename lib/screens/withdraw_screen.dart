import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  num _balance = 0;
  String? _bankName;
  String? _accountNumber;

  static const num _minWithdrawal = 2000;
  static const num _fee = 50;

  num get _enteredAmount =>
      num.tryParse(_amountController.text.trim()) ?? 0;

  num get _youReceive => _enteredAmount > _fee ? _enteredAmount - _fee : 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final withdrawAmount = _enteredAmount;
      final payoutAmount = _youReceive;
      final newBalance = _balance - withdrawAmount;

      // 1. Queue the payout — processed every Sunday
      await Supabase.instance.client.from('payouts').insert({
        'user_id': user!.id,
        'amount_ngn': payoutAmount,
        'fee_charged': _fee,
        'status': 'pending',
      });

      // 2. Deduct only the entered amount from available balance
      await Supabase.instance.client
          .from('profiles')
          .update({'available_balance_ngn': newBalance}).eq('id', user.id);

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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Withdrawal Queued!',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '₦${payoutAmount.toStringAsFixed(0)} will be sent to $_bankName on the next payout Sunday.',
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
              child: Form(
                key: _formKey,
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

                    const SizedBox(height: 28),

                    // AMOUNT INPUT
                    if (_balance >= _minWithdrawal) ...[
                      const Text(
                        'Amount to withdraw',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          prefixText: '₦ ',
                          prefixStyle: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          hintText: 'e.g. 5000',
                          hintStyle:
                              const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFF4ADE80), width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          final amount = num.tryParse(val?.trim() ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Please enter an amount.';
                          }
                          if (amount < _minWithdrawal) {
                            return 'Minimum withdrawal is ₦${_minWithdrawal.toStringAsFixed(0)}.';
                          }
                          if (amount > _balance) {
                            return 'Amount exceeds your available balance.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // LIVE BREAKDOWN
                      if (_enteredAmount >= _minWithdrawal &&
                          _enteredAmount <= _balance) ...[
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
                                label: 'You withdraw',
                                value:
                                    '₦${_enteredAmount.toStringAsFixed(0)}',
                              ),
                              const Divider(
                                  color: Colors.white10, height: 24),
                              _BreakdownRow(
                                label: 'Processing fee',
                                value:
                                    '- ₦${_fee.toStringAsFixed(0)}',
                                valueColor: Colors.redAccent,
                              ),
                              const Divider(
                                  color: Colors.white10, height: 24),
                              _BreakdownRow(
                                label: 'You receive',
                                value:
                                    '₦${_youReceive.toStringAsFixed(0)}',
                                valueColor: const Color(0xFF10B981),
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // BANK DESTINATION
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
                                        color: Colors.white54,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      const Text(
                        'Payouts are processed every Sunday.',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 12),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting ? null : _requestWithdrawal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            disabledBackgroundColor:
                                const Color(0x6610B981),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
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

                    // BALANCE TOO LOW
                    if (_balance < _minWithdrawal) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0x14FBBF24),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0x4DFBBF24)),
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
                                    'You need ₦${(_minWithdrawal - _balance).toStringAsFixed(0)} more to make a withdrawal.',
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
                  ],
                ),
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
