import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  _FlightSearchScreenState createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  List<Flight> flights = [];

  void searchFlights() async {
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
  void initState() {
    super.initState();
    searchFlights();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Flights")),
      body: ListView.builder(
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
