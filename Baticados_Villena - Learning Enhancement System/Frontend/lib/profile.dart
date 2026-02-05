import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Profile extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const Profile({super.key, this.userData});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isEditing = false;
  bool _isLoading = false;
  
  final String apiBase = "http://192.168.1.7/learnquik";

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController usernameController;
  late TextEditingController passwordController;

  late String originalFirstName;
  late String originalLastName;
  late String originalUsername;

  @override
  void initState() {
    super.initState();
    originalFirstName = widget.userData?['fname'] ?? '';
    originalLastName = widget.userData?['lname'] ?? '';
    originalUsername = widget.userData?['username'] ?? '';
    
    firstNameController = TextEditingController(text: originalFirstName);
    lastNameController = TextEditingController(text: originalLastName);
    usernameController = TextEditingController(text: originalUsername);
    passwordController = TextEditingController(text: '********');
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty) {
      _showMessage('All fields are required', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestBody = {
        'user_id': widget.userData?['id'],
        'fname': firstNameController.text.trim(),
        'lname': lastNameController.text.trim(),
        'username': usernameController.text.trim(),
      };

      if (passwordController.text != '********' && 
          passwordController.text.isNotEmpty) {
        requestBody['password'] = passwordController.text;
      }

      final response = await http.post(
        Uri.parse('$apiBase/update_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          originalFirstName = data['user']['fname'];
          originalLastName = data['user']['lname'];
          originalUsername = data['user']['username'];
          isEditing = false;
        });
        
        if (widget.userData != null) {
          widget.userData!['fname'] = data['user']['fname'];
          widget.userData!['lname'] = data['user']['lname'];
          widget.userData!['username'] = data['user']['username'];
        }
        
        _showMessage(data['message'], isError: false);
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

  void toggleEdit() {
    if (isEditing) {
      saveChanges();
    } else {
      setState(() {
        isEditing = true;
      });
    }
  }

  void cancelEdit() {
    setState(() {
      firstNameController.text = originalFirstName;
      lastNameController.text = originalLastName;
      usernameController.text = originalUsername;
      passwordController.text = '********';
      isEditing = false;
    });
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, widget.userData);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 106, 14, 14),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, widget.userData);
          },
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                isEditing ? Icons.close : Icons.edit,
                color: Colors.white,
              ),
              onPressed: isEditing ? cancelEdit : toggleEdit,
            ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB83C3C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${firstNameController.text} ${lastNameController.text}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${usernameController.text}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'User ID: ${widget.userData?['id'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Container(height: 2, color: Colors.black12),
              const SizedBox(height: 20),

              _buildInfoField(
                label: 'First Name',
                controller: firstNameController,
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 16),

              _buildInfoField(
                label: 'Last Name',
                controller: lastNameController,
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 16),

              _buildInfoField(
                label: 'Username',
                controller: usernameController,
                icon: Icons.account_circle_outlined,
              ),

              const SizedBox(height: 16),

              _buildInfoField(
                label: 'Password',
                controller: passwordController,
                icon: Icons.lock_outline,
                isPassword: true,
                hintText: 'Enter new password or leave as ********',
              ),

              const SizedBox(height: 30),

              if (isEditing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 106, 14, 14),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isEditing ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isEditing
                  ? const Color.fromARGB(255, 106, 14, 14)
                  : Colors.grey[300]!,
              width: isEditing ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: isEditing,
            obscureText: isPassword && !isEditing,
            style: TextStyle(
              fontSize: 16,
              color: isEditing ? Colors.black : Colors.black87,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isEditing
                    ? const Color.fromARGB(255, 106, 14, 14)
                    : Colors.grey[600],
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}