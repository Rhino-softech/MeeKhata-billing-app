import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4CAF50), // Same green color
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 80),
          Center(
            child: Text(
              'MeeKhata',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 30),
          Expanded(
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'Login to your account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 30),

                      // Phone Number Field
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),

                      // OTP Field
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Enter OTP',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 30),

                      // Login Button
                      ElevatedButton(
                        onPressed: () {
                          // Handle login logic here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text('Login', style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 20),

                      // Terms
                      Text.rich(
                        TextSpan(
                          text: 'By logging in, you agree to our ',
                          style: TextStyle(fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'T&C',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy.',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 30);
    path.quadraticBezierTo(size.width / 4, 0, size.width / 2, 30);
    path.quadraticBezierTo(3 / 4 * size.width, 60, size.width, 30);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
