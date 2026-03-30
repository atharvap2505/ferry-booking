import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  _GuestScreenState createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  List<Flight> flights = [];

  @override
  void initState() {
    super.initState();
    fetchFlights();
  }

  Future<void> fetchFlights() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('flights');

    setState(() {
      flights = List.generate(maps.length, (i) {
        return Flight(
          id: maps[i]['id'],
          name: maps[i]['name'],
          origin: maps[i]['origin'],
          destination: maps[i]['destination'],
          price: maps[i]['price'],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Guest View")),
      body: flights.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: flights.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(flights[index].name),
            subtitle: Text("${flights[index].origin} ➝ ${flights[index].destination}"),
            trailing: Text("\$${flights[index].price.toStringAsFixed(2)}"),
          );
        },
      ),
    );
  }
}
