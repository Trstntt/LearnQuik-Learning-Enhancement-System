import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learnquik/created_quizzes.dart';
import 'package:learnquik/main.dart';
import 'package:learnquik/profile.dart';
import 'package:learnquik/quiz_creation.dart';
import 'package:learnquik/help.dart';

class Home extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const Home({super.key, this.userData});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  
  int createdQuizzesTabIndex = 0;

  int quizCreationTabIndex = 0;
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _uploadedFiles = [];
  bool _isLoadingFiles = false;
  
  final String apiBase = "http://192.168.1.7/learnquik";

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
    _loadUserFiles();
  }

  Future<void> _loadUserFiles() async {
    if (_userData == null || _userData!['id'] == null) return;
    
    setState(() {
      _isLoadingFiles = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/get_user_files.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _userData!['id'],
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          _uploadedFiles = List<Map<String, dynamic>>.from(data['files']);
        });
      }
    } catch (e) {
      print('Error loading files: $e');
    } finally {
      setState(() {
        _isLoadingFiles = false;
      });
    }
  }

  void _NavBotBar(int index) {
    setState(() {
      selectedIndex = index;
    });
  }
  
  void _updateUserData(Map<String, dynamic> newUserData) {
    setState(() {
      _userData = newUserData;
    });
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    
    if (result != null) {
      final fileName = result.files.single.name;
      final bytes = result.files.single.bytes;
      
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read file content'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      final base64Content = base64Encode(bytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading and processing file...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      try {
        final response = await http.post(
          Uri.parse('$apiBase/upload_file_with_content.php'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'user_id': _userData!['id'],
            'file_name': fileName,
            'file_content': base64Content,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Server returned ${response.statusCode}');
        }

        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          print('=== JSON PARSE ERROR ===');
          print('Status Code: ${response.statusCode}');
          print('Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          print('Full response body: ${response.body}');
          print('========================');
          throw Exception('Invalid JSON response from server');
        }

        if (data['success'] == true) {
          await _loadUserFiles();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File uploaded! Extracted ${data['content_length'] ?? 0} characters.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Upload failed'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('Upload error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(int fileId, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Delete File',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 106, 14, 14),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$fileName"?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 106, 14, 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _removeFile(fileId);
    }
  }

  Future<void> _removeFile(int fileId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/delete_file.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'file_id': fileId,
          'user_id': _userData!['id'],
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        await _loadUserFiles();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File removed successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Delete failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _switchToCreatedQuizzes() {
    setState(() {
      selectedIndex = 1;
    });
  }
  
  void _onCreatedQuizzesTabChanged(int tabIndex) {
    setState(() {
      createdQuizzesTabIndex = tabIndex;
    });
  }
  
  void _onQuizCreationTabChanged(int tabIndex) {
    setState(() {
      quizCreationTabIndex = tabIndex;
    });
  }

  List<Widget> get _pages => [
    HomePage(
      userData: _userData,
      uploadedFiles: _uploadedFiles,
      onRemoveFile: _showDeleteConfirmation,
      isLoading: _isLoadingFiles,
    ),
    CreatedQuizzes(
      userData: _userData,
      initialTabIndex: createdQuizzesTabIndex,
      onTabChanged: _onCreatedQuizzesTabChanged,
    ),
    QuizCreation(
      userData: _userData,
      onQuizCreated: _switchToCreatedQuizzes,
      initialTabIndex: quizCreationTabIndex,
      onTabChanged: _onQuizCreationTabChanged,
    ),
  ];

  final List<String> _pageTitles = [
    'Home',
    'Created Quizzes',
    'Create Quiz',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 106, 14, 14),
        automaticallyImplyLeading: false,
        leading: selectedIndex == 0 
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            )
          : null,
        title: Text(
          _pageTitles[selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color.fromARGB(255, 106, 14, 14),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color.fromARGB(255, 106, 14, 14),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '${_userData?['fname'] ?? ''} ${_userData?['lname'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '@${_userData?['username'] ?? 'User'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            ListTile(
              leading: const Icon(Icons.person, color: Color.fromARGB(255, 106, 14, 14), size: 35),
              title: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                final updatedData = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profile(userData: _userData),
                  ),
                );
                
                if (updatedData != null) {
                  _updateUserData(updatedData);
                }
              },
            ),

            const SizedBox(height: 15),

            ListTile(
              leading: const Icon(Icons.info, color: Color.fromARGB(255, 106, 14, 14), size: 35),
              title: Text(
                'Help',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Help(),
                  ),
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 106, 14, 14),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
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

      body: _pages[selectedIndex],

      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _uploadFile,
              backgroundColor: const Color.fromARGB(255, 106, 14, 14),
              shape: const CircleBorder(),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            )
          : null,

      bottomNavigationBar: Container(
        color: const Color.fromARGB(255, 106, 14, 14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: GNav(
            backgroundColor: const Color.fromARGB(255, 106, 14, 14),
            haptic: true,
            tabBorderRadius: 8, 
            tabActiveBorder: Border.all(color: Colors.black, width: 1),
            curve: Curves.easeOutExpo,
            duration: const Duration(milliseconds: 200),
            gap: 8,
            color: Colors.grey[800],
            activeColor: Colors.white,
            iconSize: 30,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            selectedIndex: selectedIndex,
            onTabChange: _NavBotBar,
            tabs: const [
              GButton(
                icon: Icons.home,
                iconColor: Colors.white,
                text: ' Home',
              ),
              GButton(
                icon: Icons.folder,
                iconColor: Colors.white,
                text: ' Created Quizzes',
              ),
              GButton(
                icon: Icons.phone_android_rounded,
                iconColor: Colors.white,
                text: ' Create Quiz',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final List<Map<String, dynamic>> uploadedFiles;
  final Function(int, String) onRemoveFile;
  final bool isLoading;
  
  const HomePage({
    super.key,
    this.userData,
    required this.uploadedFiles,
    required this.onRemoveFile,
    required this.isLoading,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${widget.userData?['fname'] ?? 'User'}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A digital platform designed to improve how students learn and retain knowledge.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB83C3C),
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        backgroundImage:
                            AssetImage("lib/assets/images/school_logo.png"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Uploaded Files",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Container(height: 2, color: Colors.black12),
            const SizedBox(height: 20),

            Container(
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 400,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: widget.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 106, 14, 14),
                      ),
                    )
                  : widget.uploadedFiles.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'upload a file...',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button below',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: widget.uploadedFiles.length,
                          itemBuilder: (context, index) {
                            final file = widget.uploadedFiles[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 165, 107, 107),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.grey[400],
                                    size: 28,
                                  ),
                                  title: Text(
                                    file['file_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color.fromARGB(255, 173, 33, 23),
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      widget.onRemoveFile(
                                        file['id'],
                                        file['file_name'] ?? 'this file',
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}