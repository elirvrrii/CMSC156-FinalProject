import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ================= LOGIN =================
  Future<void> login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      showMessage("Please fill in all fields");
      return;
    }

    try {
      setState(() => _isLoading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Login failed");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ================= GOOGLE SIGN IN =================
  Future<void> signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid);

      final snapshot = await userDoc.get();

      // Create user document if first time login
      if (!snapshot.exists) {
        await userDoc.set({
          'uid': userCredential.user!.uid,
          'display_name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'recipe_count': 0,
          'twist_count': 0,
          'avg_rating': 0.0,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showMessage("Google Sign-In Failed");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ================= RESET PASSWORD =================
  Future<void> resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      showMessage("Please enter your email first");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      showMessage("Password reset email sent!");
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Failed to send reset email");
    }
  }

  // ================= SNACKBAR =================
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ================= CUSTOM INPUT =================
  InputDecoration customInput({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.orange.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.orange.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.orange,
          width: 1.5,
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              Image.asset(
                'assets/images/logo.png',
                height: 150,
              ),

              const SizedBox(height: 10),

              const Text(
                "Recipe Book",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C5346),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Share. Discover. Cook Together.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Log in to your account",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // EMAIL
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: customInput(
                        hint: "Email Address",
                        icon: Icons.email_outlined,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // PASSWORD
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: customInput(
                        hint: "Password",
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    // FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: resetPassword,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFC97C39),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: Text(
                            "or",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // GOOGLE SIGN IN
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isLoading ? null : signInWithGoogle,
                        icon: Image.network(
                          'https://cdn-icons-png.flaticon.com/512/281/281764.png',
                          height: 22,
                        ),
                        label: const Text(
                          "Continue with Google",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.orange.shade100,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // REGISTER
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Create one",
                            style: TextStyle(
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
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