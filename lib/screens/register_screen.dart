import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  bool _isPasswordVisible = false;

  void signup() async {
    // Basic validation
    if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required.")),
      );
      return;
    }

    // Password length validation
    if (passCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters long.")),
      );
      return;
    }


    setState(() => loading = true);

    UserCredential? userCredential;

    try {
      // 1. Create user with email and password (Firebase Auth)
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final user = userCredential.user;
      final fullName = nameCtrl.text.trim();
      final lowerCaseUsername = fullName.toLowerCase();


      await user?.updateDisplayName(fullName);


      if (user != null) {
        final userData = {
          'username': lowerCaseUsername,
          'fullName': fullName,
          'email': user.email,
          'imageUrl': 'https://via.placeholder.com/150',
          'userId': user.uid,
          'createdAt': Timestamp.now(),
        };


        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);
      }


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );

    } catch (e) {

      String errorMessage = "Registration failed. Please check your details.";
      if (e is FirebaseAuthException) {

        errorMessage = e.message ?? "Authentication failed.";
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );


      if (userCredential != null) {
        await FirebaseAuth.instance.signOut();
      }

    }
    setState(() => loading = false);
  }


  void navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.lightBlueAccent;
    const Color darkSurface = Color(0xFF1E2733);
    const Color darkBackground = Color(0xFF141A23);

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: navigateToLogin,
        ),
        title: const Text('Create New Account', style: TextStyle(color: Colors.white)),
        backgroundColor: darkSurface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: darkSurface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_alt_1,
                    size: 60, color: primaryColor),
                const SizedBox(height: 10),
                const Text(
                  'Join Connectify',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const Text(
                  'Enter your details to create an account',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                _buildInputField(
                  context,
                  controller: nameCtrl,
                  hintText: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  context,
                  controller: emailCtrl,
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  context,
                  controller: passCtrl,
                  hintText: 'Password (min 6 chars)',
                  icon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  isPasswordField: true,
                  onVisibilityToggle: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 30),
                loading
                    ? const CircularProgressIndicator(color: primaryColor)
                    : _buildSignupButton(context, signup),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: navigateToLogin,
                  child: const Text(
                    "Already have an account? Sign In",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER FUNCTION: Input Field (সংশোধিত) ---
  Widget _buildInputField(
      BuildContext context, {
        required TextEditingController controller,
        required String hintText,
        required IconData icon,
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        bool isPasswordField = false,
        VoidCallback? onVisibilityToggle,
      }) {
    const Color primaryColor = Colors.lightBlueAccent;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),


        suffixIcon: isPasswordField
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade500,
          ),
          onPressed: onVisibilityToggle,
        )
            : null,

        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }


  Widget _buildSignupButton(BuildContext context, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0072FF).withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: const Center(
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}