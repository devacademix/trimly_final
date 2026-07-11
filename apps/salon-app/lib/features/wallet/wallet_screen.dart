import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _walletBalance = 14850.0;
  double _pendingSettlements = 4250.0;

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'txn_301',
      'type': 'Booking Payout',
      'customer': 'Sarah Connor',
      'date': 'Today, 11:30 AM',
      'amount': '+₹424.15',
      'platformCommission': '-₹74.85',
      'status': 'Completed',
    },
    {
      'id': 'txn_302',
      'type': 'Booking Payout',
      'customer': 'David Miller',
      'date': 'Today, 10:15 AM',
      'amount': '+₹254.15',
      'platformCommission': '-₹44.85',
      'status': 'Completed',
    },
    {
      'id': 'txn_303',
      'type': 'Bank Withdrawal',
      'customer': 'HDFC Bank ****4592',
      'date': 'July 8, 2026',
      'amount': '-₹10,000.00',
      'platformCommission': '₹0.00',
      'status': 'Completed',
    },
  ];

  void _requestWithdrawal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Payout Settlement'),
        content: Text('Send ₹${_walletBalance.toStringAsFixed(2)} directly to your registered bank account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _transactions.insert(0, {
                  'id': 'txn_${_transactions.length + 301}',
                  'type': 'Bank Withdrawal',
                  'customer': 'HDFC Bank ****4592',
                  'date': 'Just Now',
                  'amount': '-₹${_walletBalance.toStringAsFixed(2)}',
                  'platformCommission': '₹0.00',
                  'status': 'Processing',
                });
                _walletBalance = 0;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settlement request submitted!')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Wallet & Payouts', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Balance Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${_walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _walletBalance > 0 ? _requestWithdrawal : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Withdraw'),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending Settlement',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '₹${_pendingSettlements.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Settlement History List Header
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Settlements & Split Logs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Transaction List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final txn = _transactions[index];
                final isNegative = txn['amount'].toString().startsWith('-');

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isNegative
                              ? Colors.redAccent.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isNegative ? Icons.account_balance : Icons.wallet,
                          color: isNegative ? Colors.redAccent : Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn['type'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${txn['customer']} • ${txn['date']}',
                              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                            ),
                            if (!isNegative) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Split: Comm ${txn['platformCommission']}',
                                style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            txn['amount'],
                            style: TextStyle(
                              color: isNegative ? Colors.redAccent : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            txn['status'],
                            style: TextStyle(
                              color: txn['status'] == 'Processing' ? Colors.amber : Colors.blueGrey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
