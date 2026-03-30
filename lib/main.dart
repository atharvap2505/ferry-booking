import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

late Database db;
Map<String, dynamic>? currentUser;
List<Map<String, dynamic>> users = [];

const String roleDba = 'DBA';
const String roleAdmin = 'ADMIN';
const String roleViewOnly = 'VIEW_ONLY';
const String roleViewUpdateNoCreate = 'VIEW_UPDATE_NO_CREATE_USER';
const String roleCustomer = 'CUSTOMER';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initDatabase();
  await fetchUsers();
  runApp(FerryBookingApp());
}

Future<void> initDatabase() async {
  final databasesPath = await getDatabasesPath();
  final path = p.join(databasesPath, 'database.db');

  Future<bool> hasFerrySchema(String dbPath) async {
    if (!await File(dbPath).exists()) {
      return false;
    }
    final tempDb = await openDatabase(dbPath, readOnly: true);
    try {
      final tables = await tempDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='ROUTES'",
      );
      return tables.isNotEmpty;
    } finally {
      await tempDb.close();
    }
  }

  Future<bool> hasExpectedRouteSeed(String dbPath) async {
    if (!await File(dbPath).exists()) {
      return false;
    }
    final tempDb = await openDatabase(dbPath, readOnly: true);
    try {
      final result = await tempDb.rawQuery('SELECT COUNT(*) AS total_routes FROM ROUTES');
      final total = (result.first['total_routes'] as int?) ?? 0;
      return total >= 85;
    } catch (_) {
      return false;
    } finally {
      await tempDb.close();
    }
  }

  final shouldCopyFresh = !await hasFerrySchema(path) || !await hasExpectedRouteSeed(path);
  if (shouldCopyFresh && await File(path).exists()) {
    await File(path).delete();
  }

  if (!await File(path).exists()) {
    final data = await rootBundle.load('assets/database.db');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).parent.create(recursive: true);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  db = await openDatabase(path);
}

Future<void> fetchUsers() async {
  users = await db.query('USERS');
}

bool isPrivilegedRole(String role) {
  return role == roleDba || role == roleAdmin;
}

void showPopup(BuildContext context, String title, String content) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK'),
        ),
      ],
    ),
  );
}

class FerryBookingApp extends StatelessWidget {
  const FerryBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ferry Booking System',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0E7490)),
        scaffoldBackgroundColor: Color(0xFFF5F8FA),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Color(0xFF0E7490), width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      routes: {
        '/': (_) => LoginPage(),
        '/signup': (_) => SignUpPage(),
        '/route_search': (_) => RouteSearchPage(),
        '/admin_dashboard': (_) => AdminDashboardPage(),
        '/route_results': (_) => RouteResultsPage(),
        '/route_details': (_) => RouteDetailsPage(),
        '/payment': (_) => PaymentPage(),
        '/booking_history': (_) => BookingHistoryPage(),
        '/all_bookings': (_) => AllBookingsPage(),
        '/profile': (_) => ProfilePage(),
      },
      initialRoute: '/',
    );
  }
}

class FerryTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogout;
  final bool showBack;
  final VoidCallback? onBack;

  const FerryTopNavBar({
    super.key,
    required this.title,
    this.showLogout = false,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFF0F766E),
      foregroundColor: Colors.white,
      title: Text(title),
      centerTitle: true,
      leading: showBack
          ? IconButton(
              tooltip: 'Back',
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: Icon(Icons.arrow_back_rounded),
            )
          : null,
      actions: [
        if (showLogout)
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              currentUser = null;
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            icon: Icon(Icons.logout_rounded),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void authenticateUser() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final user = users.where((u) => u['email'] == email && u['password'] == password).toList();

    if (user.isEmpty) {
      showPopup(context, 'Login Failed', 'Invalid email or password.');
      return;
    }

    currentUser = user.first;
    final role = currentUser?['role']?.toString() ?? roleCustomer;

    if (isPrivilegedRole(role)) {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/route_search');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E7490), Color(0xFF0891B2), Color(0xFF67E8F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_boat_filled_rounded, size: 44, color: Color(0xFF0F766E)),
                    SizedBox(height: 10),
                    Text('Ferry Booking System', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text('Sign in to search and book routes', style: TextStyle(color: Colors.grey[700])),
                    SizedBox(height: 18),
                    TextField(
                      controller: emailController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => authenticateUser(),
                      decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: authenticateUser,
                        icon: Icon(Icons.login_rounded),
                        label: Text('Login'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> createUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final phone = phoneController.text.trim();

    if ([name, email, password, phone].any((e) => e.isEmpty)) {
      showPopup(context, 'Error', 'Please fill all fields.');
      return;
    }

    final emailExists = users.any((u) => u['email'] == email);
    if (emailExists) {
      showPopup(context, 'Error', 'Email already exists.');
      return;
    }

    final newUser = {
      'userID': 'USR${DateTime.now().millisecondsSinceEpoch}',
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'isAdmin': 0,
      'role': roleCustomer,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await db.insert('USERS', newUser);
    await fetchUsers();
    currentUser = newUser;
    if (!mounted) {
      return;
    }
    showPopup(context, 'Success', 'Account created. You are now logged in.');
    Navigator.pushNamedAndRemoveUntil(context, '/route_search', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FerryTopNavBar(title: 'Create Account'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
                    SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => createUser(),
                      decoration: InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: createUser, child: Text('Sign up')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Widget _adminActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFFE6FFFA),
          child: Icon(icon, color: Color(0xFF0F766E)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUser?['role']?.toString() ?? roleCustomer;
    if (!isPrivilegedRole(role)) {
      return Scaffold(
        appBar: FerryTopNavBar(title: 'Access Denied'),
        body: Center(child: Text('You are not authorized to access admin dashboard.')),
      );
    }

    return Scaffold(
      appBar: FerryTopNavBar(title: 'Admin Dashboard', showLogout: true),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFE6FFFA),
                      child: Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0F766E)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, ${currentUser?['name']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                          SizedBox(height: 2),
                          Text('Role: ${currentUser?['role']}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            _adminActionCard(
              context: context,
              title: 'Route Management',
              subtitle: 'Create, edit, and delete ferry routes',
              icon: Icons.alt_route_rounded,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RouteManagementPage()));
              },
            ),
            _adminActionCard(
              context: context,
              title: 'User Management',
              subtitle: 'Create user accounts and update roles',
              icon: Icons.group_outlined,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementPage()));
              },
            ),
            _adminActionCard(
              context: context,
              title: 'Booking Insights',
              subtitle: 'View booking status distribution',
              icon: Icons.insights_outlined,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BookingInsightsPage()));
              },
            ),
            _adminActionCard(
              context: context,
              title: 'All Booking History',
              subtitle: 'See every booking and who placed it',
              icon: Icons.list_alt_rounded,
              onTap: () {
                Navigator.pushNamed(context, '/all_bookings');
              },
            ),
            _adminActionCard(
              context: context,
              title: 'Go To Route Search',
              subtitle: 'Switch to user search experience',
              icon: Icons.travel_explore_outlined,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/route_search');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RouteManagementPage extends StatefulWidget {
  const RouteManagementPage({super.key});

  @override
  State<RouteManagementPage> createState() => _RouteManagementPageState();
}

class _RouteManagementPageState extends State<RouteManagementPage> {
  List<Map<String, dynamic>> routes = [];
  List<Map<String, dynamic>> ports = [];
  List<Map<String, dynamic>> operators = [];

  Future<void> fetchRoutes() async {
    routes = await db.rawQuery('''
      SELECT
        r.route_id,
        r.route_number,
        r.operator_id,
        r.departure_port_id,
        r.arrival_port_id,
        r.departure_time,
        r.arrival_time,
        r.capacity,
        fo.name AS operator_name,
        dp.city AS departure_city,
        ap.city AS arrival_city,
        r.status,
        r.fare
      FROM ROUTES r
      INNER JOIN FERRY_OPERATORS fo ON fo.operator_id = r.operator_id
      INNER JOIN PORTS dp ON dp.port_id = r.departure_port_id
      INNER JOIN PORTS ap ON ap.port_id = r.arrival_port_id
      ORDER BY r.route_id
    ''');
    ports = await db.query('PORTS');
    operators = await db.query('FERRY_OPERATORS');
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showRouteDialog({Map<String, dynamic>? existing}) async {
    final routeNumberController = TextEditingController(text: existing?['route_number']?.toString() ?? '');
    final departureController = TextEditingController(text: existing?['departure_time']?.toString() ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));
    final arrivalController = TextEditingController(text: existing?['arrival_time']?.toString() ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().add(Duration(hours: 2))));
    final capacityController = TextEditingController(text: existing?['capacity']?.toString() ?? '200');
    final fareController = TextEditingController(text: existing?['fare']?.toString() ?? '1499');
    String status = existing?['status']?.toString() ?? 'On Time';
    int? operatorId = existing?['operator_id'] as int? ?? (operators.isNotEmpty ? operators.first['operator_id'] as int : null);
    int? departurePortId = existing?['departure_port_id'] as int? ?? (ports.isNotEmpty ? ports.first['port_id'] as int : null);
    int? arrivalPortId = existing?['arrival_port_id'] as int? ?? (ports.length > 1 ? ports[1]['port_id'] as int : departurePortId);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocalState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Route' : 'Edit Route'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(controller: routeNumberController, decoration: InputDecoration(labelText: 'Route number (e.g. FW-201)')),
                      SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: operatorId,
                        decoration: InputDecoration(labelText: 'Operator'),
                        items: operators
                            .map((o) => DropdownMenuItem<int>(
                                  value: o['operator_id'] as int,
                                  child: Text(o['name'].toString()),
                                ))
                            .toList(),
                        onChanged: (v) => setLocalState(() => operatorId = v),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: departurePortId,
                        decoration: InputDecoration(labelText: 'Departure port'),
                        items: ports
                            .map((p) => DropdownMenuItem<int>(
                                  value: p['port_id'] as int,
                                  child: Text('${p['city']} (${p['port_code']})'),
                                ))
                            .toList(),
                        onChanged: (v) => setLocalState(() => departurePortId = v),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: arrivalPortId,
                        decoration: InputDecoration(labelText: 'Arrival port'),
                        items: ports
                            .map((p) => DropdownMenuItem<int>(
                                  value: p['port_id'] as int,
                                  child: Text('${p['city']} (${p['port_code']})'),
                                ))
                            .toList(),
                        onChanged: (v) => setLocalState(() => arrivalPortId = v),
                      ),
                      SizedBox(height: 10),
                      TextField(controller: departureController, decoration: InputDecoration(labelText: 'Departure time (YYYY-MM-DD HH:MM:SS)')),
                      SizedBox(height: 10),
                      TextField(controller: arrivalController, decoration: InputDecoration(labelText: 'Arrival time (YYYY-MM-DD HH:MM:SS)')),
                      SizedBox(height: 10),
                      TextField(controller: capacityController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Capacity')),
                      SizedBox(height: 10),
                      TextField(controller: fareController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Fare')),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: InputDecoration(labelText: 'Status'),
                        items: ['On Time', 'Delayed', 'Cancelled', 'Boarding']
                            .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setLocalState(() => status = v ?? 'On Time'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (routeNumberController.text.trim().isEmpty ||
                        operatorId == null ||
                        departurePortId == null ||
                        arrivalPortId == null ||
                        departurePortId == arrivalPortId) {
                      showPopup(context, 'Invalid route', 'Fill all required fields and ensure ports are different.');
                      return;
                    }

                    final payload = {
                      'route_number': routeNumberController.text.trim(),
                      'operator_id': operatorId,
                      'departure_port_id': departurePortId,
                      'arrival_port_id': arrivalPortId,
                      'departure_time': departureController.text.trim(),
                      'arrival_time': arrivalController.text.trim(),
                      'capacity': int.tryParse(capacityController.text.trim()) ?? 200,
                      'fare': double.tryParse(fareController.text.trim()) ?? 0,
                      'status': status,
                      'updated_at': DateTime.now().toIso8601String(),
                    };

                    if (existing == null) {
                      final nextIdRows = await db.rawQuery('SELECT IFNULL(MAX(route_id), 100) + 1 AS next_id FROM ROUTES');
                      final nextId = nextIdRows.first['next_id'] as int;
                      await db.insert('ROUTES', {
                        ...payload,
                        'route_id': nextId,
                        'created_at': DateTime.now().toIso8601String(),
                      });
                    } else {
                      await db.update('ROUTES', payload, where: 'route_id = ?', whereArgs: [existing['route_id']]);
                    }

                    if (!mounted) {
                      return;
                    }
                    Navigator.pop(dialogContext);
                    await fetchRoutes();
                  },
                  child: Text(existing == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRoute(int routeId) async {
    await db.delete('BOOKINGS', where: 'routeID = ?', whereArgs: [routeId]);
    await db.delete('ROUTES', where: 'route_id = ?', whereArgs: [routeId]);
    await fetchRoutes();
  }

  @override
  void initState() {
    super.initState();
    fetchRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FerryTopNavBar(title: 'Route Management'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRouteDialog(),
        icon: Icon(Icons.add_rounded),
        label: Text('Add Route'),
      ),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (_, index) {
          final r = routes[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${r['route_number']} - ${r['operator_name']}', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${r['departure_city']} -> ${r['arrival_city']}\n'
                'Dep: ${r['departure_time']} | Arr: ${r['arrival_time']}\n'
                '${r['status']} | INR ${r['fare']}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.blueGrey),
                    onPressed: () => _showRouteDialog(existing: r),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteRoute(r['route_id'] as int),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  Future<void> _showUserDialog({Map<String, dynamic>? existing}) async {
    final nameController = TextEditingController(text: existing?['name']?.toString() ?? '');
    final emailController = TextEditingController(text: existing?['email']?.toString() ?? '');
    final passwordController = TextEditingController(text: existing?['password']?.toString() ?? 'password123');
    final phoneController = TextEditingController(text: existing?['phone']?.toString() ?? '');
    String role = existing?['role']?.toString() ?? roleCustomer;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocalState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add User' : 'Edit User'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
                      SizedBox(height: 10),
                      TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
                      SizedBox(height: 10),
                      TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password')),
                      SizedBox(height: 10),
                      TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone')),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: InputDecoration(labelText: 'Role'),
                        items: [roleDba, roleAdmin, roleViewOnly, roleViewUpdateNoCreate, roleCustomer]
                            .map((r) => DropdownMenuItem<String>(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setLocalState(() => role = v ?? roleCustomer),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                      showPopup(context, 'Invalid user', 'Name and email are required.');
                      return;
                    }

                    final payload = {
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'password': passwordController.text.trim().isEmpty ? 'password123' : passwordController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'role': role,
                      'isAdmin': (role == roleDba || role == roleAdmin) ? 1 : 0,
                      'updated_at': DateTime.now().toIso8601String(),
                    };

                    if (existing == null) {
                      await db.insert('USERS', {
                        ...payload,
                        'userID': 'USR${DateTime.now().millisecondsSinceEpoch}',
                        'created_at': DateTime.now().toIso8601String(),
                      });
                    } else {
                      await db.update('USERS', payload, where: 'userID = ?', whereArgs: [existing['userID']]);
                    }

                    await fetchUsers();
                    if (!mounted) {
                      return;
                    }
                    setState(() {});
                    Navigator.pop(dialogContext);
                  },
                  child: Text(existing == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    if (currentUser?['userID'] == userId) {
      showPopup(context, 'Not allowed', 'You cannot delete the currently logged-in user.');
      return;
    }
    await db.delete('BOOKINGS', where: 'userID = ?', whereArgs: [userId]);
    await db.delete('USERS', where: 'userID = ?', whereArgs: [userId]);
    await fetchUsers();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FerryTopNavBar(title: 'User Management'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: Icon(Icons.person_add_alt_1_rounded),
        label: Text('Add User'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, index) {
          final u = users[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${u['name']} (${u['role']})', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${u['email']}\n${u['phone'] ?? ''}'),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.blueGrey),
                    onPressed: () => _showUserDialog(existing: u),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteUser(u['userID'].toString()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BookingInsightsPage extends StatefulWidget {
  const BookingInsightsPage({super.key});

  @override
  State<BookingInsightsPage> createState() => _BookingInsightsPageState();
}

class _BookingInsightsPageState extends State<BookingInsightsPage> {
  List<Map<String, dynamic>> bookingStats = [];
  List<Map<String, dynamic>> bookedTickets = [];

  Future<void> loadStats() async {
    bookingStats = await db.rawQuery('''
      SELECT b.status, COUNT(*) AS total
      FROM BOOKINGS b
      GROUP BY b.status
      ORDER BY total DESC
    ''');

    bookedTickets = await db.rawQuery('''
      SELECT
        b.bookingID,
        u.name AS booked_by,
        r.route_number,
        dp.city AS departure_city,
        ap.city AS arrival_city,
        b.bookingDate,
        b.status
      FROM BOOKINGS b
      INNER JOIN USERS u ON u.userID = b.userID
      INNER JOIN ROUTES r ON r.route_id = b.routeID
      INNER JOIN PORTS dp ON dp.port_id = r.departure_port_id
      INNER JOIN PORTS ap ON ap.port_id = r.arrival_port_id
      ORDER BY b.bookingDate DESC, b.bookingID DESC
    ''');

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FerryTopNavBar(title: 'Booking Insights'),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Status Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ...bookingStats.map((row) => ListTile(
                title: Text('Status: ${row['status']}'),
                trailing: Text('${row['total']}'),
              )),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Booked Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          if (bookedTickets.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('No bookings found.'),
            ),
          ...bookedTickets.map(
            (ticket) => Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text('Booking ${ticket['bookingID']} • ${ticket['booked_by']}'),
                subtitle: Text(
                  'Route: ${ticket['route_number']} (${ticket['departure_city']} -> ${ticket['arrival_city']})\n'
                  'Date: ${ticket['bookingDate']} | Status: ${ticket['status']}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RouteSearchPage extends StatefulWidget {
  const RouteSearchPage({super.key});

  @override
  State<RouteSearchPage> createState() => _RouteSearchPageState();
}

class _RouteSearchPageState extends State<RouteSearchPage> {
  List<Map<String, dynamic>> ports = [];
  String? selectedDepartureCity;
  String? selectedArrivalCity;
  final dateController = TextEditingController();

  Future<void> loadPorts() async {
    ports = await db.query('PORTS', orderBy: 'city ASC');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadPorts();
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUser?['role']?.toString() ?? roleCustomer;
    final isGuest = currentUser == null;

    return Scaffold(
      appBar: FerryTopNavBar(
        title: 'Route Search',
        showLogout: true,
        showBack: true,
        onBack: () {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
            return;
          }
          if (isPrivilegedRole(role)) {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/');
          }
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.travel_explore_rounded, color: Color(0xFF0F766E)),
                        SizedBox(width: 8),
                        Text('Find Your Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedDepartureCity,
                      decoration: InputDecoration(labelText: 'Departure city', prefixIcon: Icon(Icons.location_on_outlined)),
                      items: ports
                          .map((p) => p['city'].toString())
                          .toSet()
                          .map((city) => DropdownMenuItem<String>(value: city, child: Text(city)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedDepartureCity = value),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedArrivalCity,
                      decoration: InputDecoration(labelText: 'Arrival city', prefixIcon: Icon(Icons.flag_outlined)),
                      items: ports
                          .map((p) => p['city'].toString())
                          .toSet()
                          .map((city) => DropdownMenuItem<String>(value: city, child: Text(city)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedArrivalCity = value),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Journey date (optional)',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        suffixIcon: IconButton(
                          tooltip: 'Clear date filter',
                          onPressed: () {
                            dateController.clear();
                            setState(() {});
                          },
                          icon: Icon(Icons.clear_rounded),
                        ),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2032),
                          initialDate: DateTime.now(),
                        );
                        if (date != null) {
                          dateController.text = DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (selectedDepartureCity == null || selectedArrivalCity == null) {
                            showPopup(context, 'Error', 'Please fill departure and arrival cities.');
                            return;
                          }
                          if (selectedDepartureCity == selectedArrivalCity) {
                            showPopup(context, 'Error', 'Departure and arrival must be different.');
                            return;
                          }
                          Navigator.pushNamed(
                            context,
                            '/route_results',
                            arguments: {
                              'departureCity': selectedDepartureCity,
                              'arrivalCity': selectedArrivalCity,
                              'date': dateController.text.trim(),
                            },
                          );
                        },
                        icon: Icon(Icons.search_rounded),
                        label: Text('Search Routes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (!isGuest) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/booking_history'),
                      icon: Icon(Icons.receipt_long_outlined),
                      label: Text('Booking History'),
                    ),
                  ),
                ],
              ),
              if (role != roleViewOnly)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/profile'),
                        icon: Icon(Icons.person_outline_rounded),
                        label: Text('Profile'),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class RouteResultsPage extends StatefulWidget {
  const RouteResultsPage({super.key});

  @override
  State<RouteResultsPage> createState() => _RouteResultsPageState();
}

class _RouteResultsPageState extends State<RouteResultsPage> {
  List<Map<String, dynamic>> routes = [];

  Future<void> fetchRoutes() async {
    routes = await db.rawQuery('''
      SELECT
        r.route_id AS id,
        r.route_number AS routeNumber,
        fo.name AS operator,
        dp.city AS origin,
        ap.city AS destination,
        r.departure_time AS departure,
        r.arrival_time AS arrival,
        DATE(r.departure_time) AS date,
        r.status AS status,
        r.fare AS fare,
        r.capacity AS capacity
      FROM ROUTES r
      INNER JOIN FERRY_OPERATORS fo ON fo.operator_id = r.operator_id
      INNER JOIN PORTS dp ON dp.port_id = r.departure_port_id
      INNER JOIN PORTS ap ON ap.port_id = r.arrival_port_id
      ORDER BY r.departure_time
    ''');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final departureCity = (args?['departureCity'] ?? '').toString().trim().toLowerCase();
    final arrivalCity = (args?['arrivalCity'] ?? '').toString().trim().toLowerCase();
    final date = (args?['date'] ?? '').toString().trim();
    final hasDateFilter = date.isNotEmpty;

    final filtered = routes.where((route) {
      final sameFrom = route['origin'].toString().trim().toLowerCase() == departureCity;
      final sameTo = route['destination'].toString().trim().toLowerCase() == arrivalCity;
      final sameDate = route['date'].toString().trim() == date;
      return sameFrom && sameTo && (!hasDateFilter || sameDate);
    }).toList();

    return Scaffold(
      appBar: FerryTopNavBar(title: 'Route Results'),
      body: routes.isEmpty
          ? Center(child: SpinKitCircle(color: Colors.teal))
          : filtered.isEmpty
              ? Center(child: Text('No routes available for selected criteria.'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final route = filtered[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('${route['origin']} -> ${route['destination']}', style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Operator: ${route['operator']}\n'
                              'Date: ${route['date']} | Fare: INR ${route['fare']}\n'
                              'Status: ${route['status']}',
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18),
                          onTap: () {
                            Navigator.pushNamed(context, '/route_details', arguments: route);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class RouteDetailsPage extends StatelessWidget {
  const RouteDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final role = currentUser?['role']?.toString() ?? roleCustomer;
    final canCreateBooking = role != roleViewOnly && role != roleViewUpdateNoCreate;

    return Scaffold(
      appBar: FerryTopNavBar(title: 'Route Details'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route ID: ${route['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Route Number: ${route['routeNumber']}'),
                SizedBox(height: 8),
                Text('Operator: ${route['operator']}'),
                SizedBox(height: 8),
                Text('From: ${route['origin']}'),
                SizedBox(height: 8),
                Text('To: ${route['destination']}'),
                SizedBox(height: 8),
                Text('Departure: ${route['departure']}'),
                SizedBox(height: 8),
                Text('Arrival: ${route['arrival']}'),
                SizedBox(height: 8),
                Text('Status: ${route['status']}'),
                SizedBox(height: 8),
                Text('Fare: INR ${route['fare']}'),
                SizedBox(height: 16),
                if (!canCreateBooking)
                  Text('Your role can view routes, but cannot create new bookings.'),
                if (canCreateBooking)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/payment',
                          arguments: {
                            'routeID': route['id'],
                            'fare': route['fare'],
                            'bookingDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          },
                        );
                      },
                      child: Text('Book Route'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedPaymentMethod;
  String paymentStatus = 'Pending';

  Future<void> confirmPayment(Map<String, dynamic> details) async {
    final bookingId = 'BK${DateTime.now().millisecondsSinceEpoch}';

    await db.insert('BOOKINGS', {
      'bookingID': bookingId,
      'userID': currentUser?['userID'],
      'routeID': details['routeID'],
      'bookingDate': details['bookingDate'],
      'status': 'Confirmed',
      'total_fare': details['fare'],
      'payment_method': selectedPaymentMethod,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    if (!mounted) {
      return;
    }

    setState(() {
      paymentStatus = 'Confirmed';
    });

    showPopup(context, 'Success', 'Booking confirmed with ID: $bookingId');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final details = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (details == null) {
      return Scaffold(
        appBar: FerryTopNavBar(title: 'Payment'),
        body: Center(child: Text('No payment details available.')),
      );
    }

    return Scaffold(
      appBar: FerryTopNavBar(title: 'Payment'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route ID: ${details['routeID']}'),
            SizedBox(height: 8),
            Text('Amount: INR ${details['fare']}'),
            SizedBox(height: 16),
            DropdownButton<String>(
              isExpanded: true,
              hint: Text('Select payment method'),
              value: selectedPaymentMethod,
              items: [
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'Card', child: Text('Card')),
                DropdownMenuItem(value: 'Net Banking', child: Text('Net Banking')),
              ],
              onChanged: (v) => setState(() => selectedPaymentMethod = v),
            ),
            SizedBox(height: 12),
            Text('Payment Status: $paymentStatus'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (selectedPaymentMethod == null) {
                  showPopup(context, 'Error', 'Select payment method first.');
                  return;
                }
                confirmPayment(details);
              },
              child: Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  List<Map<String, dynamic>> bookings = [];

  Future<void> loadBookings() async {
    bookings = await db.rawQuery('''
      SELECT
        b.bookingID,
        b.status,
        b.bookingDate,
        b.total_fare,
        b.routeID,
        r.route_number,
        dp.city AS departure_city,
        ap.city AS arrival_city
      FROM BOOKINGS b
      INNER JOIN ROUTES r ON r.route_id = b.routeID
      INNER JOIN PORTS dp ON dp.port_id = r.departure_port_id
      INNER JOIN PORTS ap ON ap.port_id = r.arrival_port_id
      WHERE b.userID = ?
      ORDER BY b.bookingDate DESC
    ''', [currentUser?['userID']]);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await db.update(
      'BOOKINGS',
      {
        'status': 'Cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'bookingID = ?',
      whereArgs: [bookingId],
    );
    await loadBookings();
  }

  Future<void> markConfirmed(String bookingId) async {
    await db.update(
      'BOOKINGS',
      {
        'status': 'Confirmed',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'bookingID = ?',
      whereArgs: [bookingId],
    );
    await loadBookings();
  }

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUser?['role']?.toString() ?? roleCustomer;
    final canUpdateBooking = role == roleViewUpdateNoCreate || role == roleCustomer || isPrivilegedRole(role);
    final canCancelBooking = role == roleCustomer || isPrivilegedRole(role);

    return Scaffold(
      appBar: FerryTopNavBar(title: 'Booking History'),
      body: bookings.isEmpty
          ? Center(child: Text('No bookings found.'))
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (_, index) {
                final booking = bookings[index];
                return Card(
                  child: ListTile(
                    title: Text('Booking ID: ${booking['bookingID']}'),
                    subtitle: Text(
                      'Route: ${booking['route_number']} (${booking['departure_city']} -> ${booking['arrival_city']})\n'
                      'Date: ${booking['bookingDate']}\n'
                      'Status: ${booking['status']}\n'
                      'Fare: INR ${booking['total_fare']}',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        if (canUpdateBooking && booking['status'] != 'Confirmed')
                          IconButton(
                            icon: Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => markConfirmed(booking['bookingID'].toString()),
                          ),
                        if (canCancelBooking && booking['status'] != 'Cancelled')
                          IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => cancelBooking(booking['bookingID'].toString()),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;

  Future<void> loadUser() async {
    final rows = await db.query('USERS', where: 'userID = ?', whereArgs: [currentUser?['userID']]);
    if (rows.isNotEmpty) {
      user = rows.first;
      currentUser = rows.first;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: FerryTopNavBar(title: 'Profile'),
        body: Center(child: SpinKitCircle(color: Colors.teal)),
      );
    }

    final role = user?['role']?.toString() ?? roleCustomer;
    final canEdit = role != roleViewOnly;

    return Scaffold(
      appBar: FerryTopNavBar(title: 'Profile'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${user?['userID']}'),
            SizedBox(height: 8),
            Text('Name: ${user?['name']}'),
            SizedBox(height: 8),
            Text('Email: ${user?['email']}'),
            SizedBox(height: 8),
            Text('Phone: ${user?['phone']}'),
            SizedBox(height: 8),
            Text('Role: ${user?['role']}'),
            SizedBox(height: 16),
            if (canEdit)
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileEditPage(user: user!)),
                  );
                  await loadUser();
                },
                child: Text('Edit Profile'),
              ),
            SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/booking_history'),
              icon: Icon(Icons.receipt_long_outlined),
              label: Text('My Booking History'),
            ),
          ],
        ),
      ),
    );
  }
}

class AllBookingsPage extends StatefulWidget {
  const AllBookingsPage({super.key});

  @override
  State<AllBookingsPage> createState() => _AllBookingsPageState();
}

class _AllBookingsPageState extends State<AllBookingsPage> {
  List<Map<String, dynamic>> allBookings = [];

  Future<void> loadAllBookings() async {
    allBookings = await db.rawQuery('''
      SELECT
        b.bookingID,
        b.bookingDate,
        b.status,
        b.total_fare,
        u.name AS booked_by,
        u.userID AS booked_by_id,
        r.route_number,
        dp.city AS departure_city,
        ap.city AS arrival_city
      FROM BOOKINGS b
      INNER JOIN USERS u ON u.userID = b.userID
      INNER JOIN ROUTES r ON r.route_id = b.routeID
      INNER JOIN PORTS dp ON dp.port_id = r.departure_port_id
      INNER JOIN PORTS ap ON ap.port_id = r.arrival_port_id
      ORDER BY b.bookingDate DESC, b.bookingID DESC
    ''');

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadAllBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FerryTopNavBar(title: 'All Booking History'),
      body: allBookings.isEmpty
          ? Center(child: Text('No bookings found.'))
          : ListView.builder(
              itemCount: allBookings.length,
              itemBuilder: (_, index) {
                final booking = allBookings[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text('Booking ${booking['bookingID']} • ${booking['booked_by']} (${booking['booked_by_id']})'),
                    subtitle: Text(
                      'Route: ${booking['route_number']} (${booking['departure_city']} -> ${booking['arrival_city']})\n'
                      'Date: ${booking['bookingDate']} | Status: ${booking['status']}\n'
                      'Fare: INR ${booking['total_fare']}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileEditPage({super.key, required this.user});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user['name'].toString());
    emailController = TextEditingController(text: widget.user['email'].toString());
    phoneController = TextEditingController(text: widget.user['phone'].toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    await db.update(
      'USERS',
      {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'userID = ?',
      whereArgs: [widget.user['userID']],
    );

    await fetchUsers();
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FerryTopNavBar(title: 'Edit Profile'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
            SizedBox(height: 10),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 10),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: saveProfile, child: Text('Save Changes')),
          ],
        ),
      ),
    );
  }
}
