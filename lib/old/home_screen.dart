import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'database_helper.dart';
import 'login_screen.dart';
import 'models.dart';

class HomeScreen extends StatefulWidget {
  final String userId; // Pass userId for filtering bookings
  const HomeScreen({super.key, required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Booking> bookingHistory = [];

  @override
  void initState() {
    super.initState();
    fetchBookingHistory();
  }

  Future<void> fetchBookingHistory() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps =
    await db.query('bookings', where: 'userId = ?', whereArgs: [widget.userId]);

    setState(() {
      bookingHistory = List.generate(maps.length, (i) {
        return Booking(
          id: maps[i]['id'],
          userId: maps[i]['userId'],
          flightId: maps[i]['flightId'],
          status: maps[i]['status'],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Welcome to the Airline Booking System",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Booking History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: bookingHistory.isEmpty
                ? Center(child: Text("No previous bookings found."))
                : ListView.builder(
              itemCount: bookingHistory.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("Booking ID: ${bookingHistory[index].id}"),
                  subtitle: Text("Status: ${bookingHistory[index].status}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

