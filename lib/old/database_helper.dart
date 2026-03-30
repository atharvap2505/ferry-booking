import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'airline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE flights(id INTEGER PRIMARY KEY, name TEXT, origin TEXT, destination TEXT, price REAL)");
        await db.execute("CREATE TABLE bookings(id INTEGER PRIMARY KEY, userId TEXT, flightId INTEGER, status TEXT)");
        await db.execute("CREATE TABLE transactions(id INTEGER PRIMARY KEY, userId TEXT, amount REAL, status TEXT)");
      },
    );
  }
}
