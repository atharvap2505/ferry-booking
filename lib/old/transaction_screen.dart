import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';

class TransactionScreen extends StatefulWidget {
  final String userId;
  const TransactionScreen({super.key, required this.userId});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<Transaction> transactions = [];

  void fetchTransactions() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', where: 'userId = ?', whereArgs: [widget.userId]);

    setState(() {
      transactions = List.generate(maps.length, (i) {
        return Transaction(
          id: maps[i]['id'],
          userId: maps[i]['userId'],
          amount: maps[i]['amount'],
          status: maps[i]['status'],
        );
      });
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Transactions")),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("Amount: \$${transactions[index].amount}"),
            subtitle: Text("Status: ${transactions[index].status}"),
          );
        },
      ),
    );
  }
}
