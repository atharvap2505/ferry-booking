import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';

class TransactionStatusScreen extends StatefulWidget {
  final int transactionId;
  const TransactionStatusScreen({super.key, required this.transactionId});

  @override
  _TransactionStatusScreenState createState() => _TransactionStatusScreenState();
}

class _TransactionStatusScreenState extends State<TransactionStatusScreen> {
  Transaction? transaction;

  void fetchTransactionStatus() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [widget.transactionId],
    );

    if (result.isNotEmpty) {
      setState(() {
        transaction = Transaction(
          id: result[0]['id'],
          userId: result[0]['userId'],
          amount: result[0]['amount'],
          status: result[0]['status'],
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTransactionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Transaction Status")),
      body: transaction == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Transaction ID: ${transaction!.id}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Amount: \$${transaction!.amount}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Status: ${transaction!.status}", style: TextStyle(fontSize: 16, color: transaction!.status == "Completed" ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }
}
