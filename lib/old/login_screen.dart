import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home_screen.dart';
import 'guest_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  void login() async {
    String? user = await authService.signInWithEmail(emailController.text, passwordController.text);
    if (user != null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(userId: user)));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login failed")));
    }
  }

  void loginAsGuest() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GuestScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text("Login")),
            SizedBox(height: 10),
            ElevatedButton(onPressed: loginAsGuest, child: Text("Continue as Guest")),
          ],
        ),
      ),
    );
  }
}



