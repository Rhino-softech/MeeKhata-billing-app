import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateInstitutePage extends StatefulWidget {
  const CreateInstitutePage({super.key});

  @override
  State<CreateInstitutePage> createState() => _CreateInstitutePageState();
}

class _CreateInstitutePageState extends State<CreateInstitutePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _feeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loading = false;
  String? _error;

  Future<void> _createInstitute() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = "Passwords do not match";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user!.uid;

      // Save to 'institutes' collection
      await _firestore.collection('institutes').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'form_fee_amount': int.tryParse(_feeController.text.trim()) ?? 1000,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Save reference in 'user_details' collection
      await _firestore.collection('user_details').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'institute',
        'reference_id': uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Institute created successfully')),
      );
      Navigator.pop(context);
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle, size: 60, color: Colors.blue),
                const SizedBox(height: 10),
                const Text(
                  'Create New Institute',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),

                _buildTextField('Institute Name', _nameController),
                _buildTextField(
                  'Email',
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  'Phone Number',
                  _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField('Address', _addressController),
                _buildTextField(
                  'Form Fee Amount (₹)',
                  _feeController,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField('Password', _passwordController, obscure: true),
                _buildTextField(
                  'Re-type Password',
                  _confirmPasswordController,
                  obscure: true,
                ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _createInstitute,
                    icon: const Icon(Icons.group_add),
                    label:
                        _loading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text("Sign Up"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Already have an account? Log in',
                    style: TextStyle(color: Colors.green),
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
