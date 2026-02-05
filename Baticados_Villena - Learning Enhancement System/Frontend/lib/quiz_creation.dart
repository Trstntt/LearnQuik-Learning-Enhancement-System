import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:learnquik/custom_quiz_creation.dart';

class QuizCreation extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onQuizCreated;
  final int initialTabIndex;
  final Function(int) onTabChanged;
  
  const QuizCreation({
    super.key,
    this.userData,
    this.onQuizCreated,
    this.initialTabIndex = 0,
    required this.onTabChanged,
  });

  @override
  State<QuizCreation> createState() => _QuizCreationState();
}

class _QuizCreationState extends State<QuizCreation> {
  late int _currentTabIndex;
  
  String _selectedQuizType = 'Multiple Choice';
  final TextEditingController _numberOfQuestionsController = TextEditingController(text: '10');
  final TextEditingController _quizNameController = TextEditingController();
  List<Map<String, dynamic>> _uploadedFiles = [];
  Set<int> _selectedFileIds = {};
  bool _isLoadingFiles = false;
  bool _isGenerating = false;
  
  final String apiBase = "http://192.168.1.7/learnquik";

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _loadUserFiles();
  }
  
  @override
  void didUpdateWidget(QuizCreation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      setState(() {
        _currentTabIndex = widget.initialTabIndex;
      });
    }
  }
  
  void _switchTab(int index) {
    if (_currentTabIndex == index) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are already on the ${index == 0 ? "Automated" : "Custom"} page'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.grey[700],
        ),
      );
      return;
    }
    
    setState(() {
      _currentTabIndex = index;
    });
    widget.onTabChanged(index);
  }

  @override
  void dispose() {
    _numberOfQuestionsController.dispose();
    _quizNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserFiles() async {
    if (widget.userData == null || widget.userData!['id'] == null) return;
    
    setState(() {
      _isLoadingFiles = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/get_user_files.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userData!['id'],
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

  void _incrementQuestions() {
    int current = int.tryParse(_numberOfQuestionsController.text) ?? 10;
    if (current < 50) {
      setState(() {
        _numberOfQuestionsController.text = (current + 1).toString();
      });
    }
  }

  void _decrementQuestions() {
    int current = int.tryParse(_numberOfQuestionsController.text) ?? 10;
    if (current > 1) {
      setState(() {
        _numberOfQuestionsController.text = (current - 1).toString();
      });
    }
  }

  void _toggleFileSelection(int fileId) {
    setState(() {
      if (_selectedFileIds.contains(fileId)) {
        _selectedFileIds.remove(fileId);
      } else {
        _selectedFileIds.add(fileId);
      }
    });
  }

  Future<String> _getFileContents() async {
    try {
      print('Fetching contents for file IDs: ${_selectedFileIds.toList()}');
      
      final response = await http.post(
        Uri.parse('$apiBase/get_file_contents.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'file_ids': _selectedFileIds.toList(),
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (data['success'] == true) {
        String content = data['content'] ?? '';
        print('Content length: ${content.length}');
        print('Content preview: ${content.substring(0, content.length > 200 ? 200 : content.length)}');
        
        if (content.trim().isEmpty) {
          throw Exception('File contents are empty. Please ensure your files contain text.');
        }
        
        return content;
      } else {
        String errorMsg = data['message'] ?? 'Error loading file contents';
        print('Error from server: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Error fetching file contents: $e');
      throw Exception('Failed to load file contents: $e');
    }
  }

  void _generateQuizWithAI() async {
    if (_selectedFileIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final quizName = await _showQuizNameDialog();
    if (quizName == null || quizName.trim().isEmpty) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    int numberOfQuestions = int.tryParse(_numberOfQuestionsController.text) ?? 10;
    
    try {
      String fileContents = await _getFileContents();
      
      print('Sending request to generate quiz...');
      print('Quiz name: $quizName');
      print('Quiz type: $_selectedQuizType');
      print('Number of questions: $numberOfQuestions');
      print('File IDs: ${_selectedFileIds.toList()}');
      print('Content length being sent: ${fileContents.length}');

      final response = await http.post(
        Uri.parse('$apiBase/generate_quiz_with_ai.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userData!['id'],
          'quiz_name': quizName,
          'quiz_type': _selectedQuizType,
          'num_questions': numberOfQuestions,
          'file_ids': _selectedFileIds.toList(),
          'file_contents': fileContents,
        }),
      ).timeout(
        const Duration(seconds: 90), 
        onTimeout: () {
          throw Exception('Request timeout - AI is taking too long to respond');
        },
      );

      print('Quiz generation response status: ${response.statusCode}');
      print('Quiz generation response: ${response.body}');

      dynamic data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        print('JSON Parse Error: $e');
        print('Response body: ${response.body}');
        throw Exception('Invalid response format from server');
      }

      if (data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'AI Quiz generated successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted && widget.onQuizCreated != null) {
            widget.onQuizCreated!();
          }
        }
      } else {
        if (mounted) {
          String errorMessage = data['message'] ?? 'Failed to generate quiz';
          
          if (data['debug_info'] != null) {
            print('=== DEBUG INFO ===');
            print('Full debug info: ${data['debug_info']}');
            if (data['debug_info']['parsed_data'] != null) {
              print('Parsed data: ${data['debug_info']['parsed_data']}');
            }
            if (data['debug_info']['generated_content'] != null) {
              print('Generated content: ${data['debug_info']['generated_content']}');
            }
            if (data['debug_info']['file_contents_length'] != null) {
              print('File contents length: ${data['debug_info']['file_contents_length']}');
            }
            if (data['debug_info']['file_contents_preview'] != null) {
              print('File contents preview: ${data['debug_info']['file_contents_preview']}');
            }
            print('==================');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print('Exception during quiz generation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<String?> _showQuizNameDialog() async {
    _quizNameController.clear();
    
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Quiz Name'),
          content: TextField(
            controller: _quizNameController,
            decoration: const InputDecoration(
              labelText: 'Enter quiz name',
              border: OutlineInputBorder(),
              hintText: 'e.g., History Quiz',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_quizNameController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 106, 14, 14),
              ),
              child: const Text('Generate', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAutomatedQuizContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Files",
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Container(height: 2, color: Colors.black12),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<String>(
                    title: const Text(
                      'Multiple Choice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: 'Multiple Choice',
                    groupValue: _selectedQuizType,
                    activeColor: const Color.fromARGB(255, 106, 14, 14),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _selectedQuizType = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Identification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: 'Identification',
                    groupValue: _selectedQuizType,
                    activeColor: const Color.fromARGB(255, 106, 14, 14),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _selectedQuizType = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 139, 18, 18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_drop_up, color: Colors.white),
                        onPressed: _incrementQuestions,
                      ),
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          controller: _numberOfQuestionsController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            int? num = int.tryParse(value);
                            if (num != null) {
                              if (num > 50) {
                                _numberOfQuestionsController.text = '50';
                              } else if (num < 1 && value.isNotEmpty) {
                                _numberOfQuestionsController.text = '1';
                              }
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        onPressed: _decrementQuestions,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No. of Questions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),
        
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateQuizWithAI,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(
              _isGenerating ? 'Generating...' : 'Generate with AI',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 139, 18, 18),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: _isLoadingFiles
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 106, 14, 14),
                  ),
                )
              : _uploadedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No files uploaded yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload files from the Home page',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _uploadedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _uploadedFiles[index];
                        final fileId = file['id'];
                        final isSelected = _selectedFileIds.contains(fileId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _toggleFileSelection(fileId),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 165, 107, 107),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                        color: isSelected 
                                            ? Colors.white 
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.black,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        file['file_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _switchTab(0),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentTabIndex == 0
                                ? const Color.fromARGB(255, 139, 18, 18)
                                : Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Automated',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _switchTab(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentTabIndex == 1
                                ? const Color.fromARGB(255, 139, 18, 18)
                                : Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Custom',
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

                  const SizedBox(height: 10),

                  if (_currentTabIndex == 0)
                    _buildAutomatedQuizContent()
                  else
                    CustomQuizCreation(
                      userData: widget.userData,
                      onQuizCreated: widget.onQuizCreated,
                      isEmbedded: true,
                    ),
                ],
              ),
            ),
          ),
          
          if (_isGenerating)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(
                          color: Color.fromARGB(255, 106, 14, 14),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Generating quiz with AI...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This may take a moment',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
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