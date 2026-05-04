import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BankSetupScreen extends StatefulWidget {
  const BankSetupScreen({super.key});

  @override
  State<BankSetupScreen> createState() => _BankSetupScreenState();
}

class _BankSetupScreenState extends State<BankSetupScreen> {
  final _accController = TextEditingController();
  String? _selectedBankCode;

  // Manual list for speed, or fetch from Flutterwave API
  final List<Map<String, String>> _banks = [
    {'name': 'First Bank', 'code': '011'},
    {'name': 'GTBank', 'code': '058'},
    {'name': 'Zenith Bank', 'code': '057'},
    {'name': 'Access Bank', 'code': '044'},
  ];

  Future<void> _saveBank() async {
    final user = Supabase.instance.client.auth.currentUser;
    await Supabase.instance.client.from('profiles').update({
      'bank_account_number': _accController.text,
      'bank_code': _selectedBankCode,
      'bank_name': _banks.firstWhere((b) => b['code'] == _selectedBankCode)['name'],
    }).eq('id', user!.id);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payout Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedBankCode,
              items: _banks
                  .map((b) => DropdownMenuItem(
                        value: b['code'],
                        child: Text(b['name']!),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBankCode = val),
              decoration: const InputDecoration(labelText: 'Select Bank'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Account Number'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBank,
                child: const Text('Save Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
