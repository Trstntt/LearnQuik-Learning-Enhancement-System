import 'package:flutter/material.dart';
import 'package:learnquik/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  String apiBase = "http://192.168.1.7/learnquik";

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Please fill in all fields', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/signup.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fname': _firstNameController.text.trim(),
          'lname': _lastNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        _showMessage(data['message'], isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        }
      } else {
        _showMessage(data['message'], isError: true);
      }
    } catch (e) {
      _showMessage('Connection error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 106, 14, 14),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          },
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 5),
                const CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage("lib/assets/images/logo.png"),
                ),
                const SizedBox(height: 5),
                const Text(
                  'LearnQuik',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 139, 18, 18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          const Text(
                            'Input Credentials',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 33,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 165, 107, 107),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0),
                              child: TextField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'First Name',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  icon: Icon(Icons.person_outline, color: Colors.white),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 165, 107, 107),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0),
                              child: TextField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Last Name',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  icon: Icon(Icons.person_outline, color: Colors.white),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 165, 107, 107),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0),
                              child: TextField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'username',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  icon: Icon(Icons.account_circle_outlined, color: Colors.white),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 165, 107, 107),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'password',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  icon: Icon(Icons.lock_outline, color: Colors.white),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          Container(
                            width: 125,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 92, 21, 21),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: TextButton(
                              onPressed: _isLoading ? null : _signUp,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
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
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}