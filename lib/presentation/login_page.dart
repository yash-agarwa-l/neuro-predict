import 'package:flutter/material.dart';
import 'package:mlapp/presentation/homepage/homepage.dart';
import 'package:mlapp/services/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthApiService.login(
        _emailController.text,
        _passwordController.text,
      );


      final message = response['message'] ?? 'Success!';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on AuthApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login / Sign Up"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Allows content to scroll if keyboard is open
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    hintText: "user@example.com",
                    prefixIcon: Icon(Icons.email), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress, 
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your email";
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return "Please enter a valid email";
                    }
                    return null; 
                  },
                ),
                const SizedBox(height: 20),
                // --- Password Field ---
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  obscureText: true, 
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    }
                    return null; // Valid
                  },
                ),
                const SizedBox(height: 30),
                // --- Error Message Display ---
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // --- Login Button ---
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    // Disable button while loading
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            "Login / Sign Up",
                            style: TextStyle(fontSize: 18),
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
}