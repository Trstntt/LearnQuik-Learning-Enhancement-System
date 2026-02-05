import 'package:flutter/material.dart';
import 'home.dart';
import 'sign_up.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  
  final String apiBase = "http://192.168.1.7/learnquik";

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please enter username and password', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        _showMessage(data['message'], isError: false);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Home(
                userData: data['user'],
              ),
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
      backgroundColor: Colors.white,
      
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 106, 14, 14),
        automaticallyImplyLeading: false,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 75,
                  backgroundImage: AssetImage("lib/assets/images/logo.png"),
                ),
                const SizedBox(height: 15),
                const Text(
                  'LearnQuik',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 139, 18, 18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        children: [
                          const Text(
                            'Welcome!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Input Your Login Info',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 25),
                          
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
                                  icon: Icon(Icons.person, color: Colors.white),
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
                                  icon: Icon(Icons.lock, color: Colors.white),
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
                              onPressed: _isLoading ? null : _login,
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
                                        'Sign In',
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
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Signup(),
                          ),
                        );
                      },
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(
                          color: Color.fromARGB(255, 139, 18, 18),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Text(
                  'DEVELOPERS:',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'Tristan Gabriel B. Baticados & Gracee Hart A. Villena',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'From BSCS Department',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),   
                const SizedBox(height: 10),

              ],
            ),
          ),
        ),
      ),
    );
  }
}