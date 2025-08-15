import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';
import 'dashboard.dart'; // Admin dashboard
import 'package:billing_app/tutor/tutor_dashboard.dart'; // Tutor dashboard
import 'create_institute.dart'; // New import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 🔹 Get logged in UID
      final String loggedInUid = credential.user!.uid;

      final userDoc =
          await _firestore.collection('user_details').doc(loggedInUid).get();

      if (userDoc.exists) {
        final Map<String, dynamic>? userData = userDoc.data();
        final role = userData?['role']?.toString().toLowerCase();

        if (role == 'institute') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => DashboardPage(
                    loggedInUid: loggedInUid, // ✅ Passing UID only
                  ),
            ),
          );
        } else if (role == 'tutor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AttendancePage(
                    loggedInUid: loggedInUid, // ✅ Passing UID
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown role, access denied')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User details not found in Firestore')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                width: 400,
                child: Column(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFDDEBFF),
                      radius: 30,
                      child: Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF4970FF),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Student Billing System',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Sign in to manage student payments',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.login),
                        label:
                            _loading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text("Sign In"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupPage()),
                        );
                      },
                      child: const Text("Don't have an account? Sign up"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateInstitutePage(),
                          ),
                        );
                      },
                      child: const Text("Create Institute Account"),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                width: 400,
                child: Column(
                  children: [
                    const Text(
                      'Demo Mode',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _emailController.text = 'admin@school.com';
                          _passwordController.text = 'password123';
                        },
                        child: const Text('Create Demo Accounts'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Admin: admin@school.com\nEmployee: employee1@school.com\nPassword: password123',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
