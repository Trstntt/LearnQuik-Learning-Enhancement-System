import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learnquik/quiz_mc.dart';
import 'package:learnquik/quiz_id.dart';

class CreatedQuizzes extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final int initialTabIndex;
  final Function(int) onTabChanged;
  
  const CreatedQuizzes({
    super.key,
    this.userData,
    this.initialTabIndex = 0,
    required this.onTabChanged,
  });

  @override
  State<CreatedQuizzes> createState() => _CreatedQuizzesState();
}

class _CreatedQuizzesState extends State<CreatedQuizzes> {
  late int _currentTabIndex;
  
  List<Map<String, dynamic>> _quizzes = [];
  Map<int, Map<String, dynamic>> _quizStats = {};
  bool _isLoadingQuizzes = false;
  
  List<Map<String, dynamic>> _customQuizzes = [];
  Map<int, Map<String, dynamic>> _customQuizStats = {};
  bool _isLoadingCustomQuizzes = false;
  
  final String apiBase = "http://192.168.1.7/learnquik";

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _loadUserQuizzes();
    _loadCustomQuizzes();
  }

  @override
  void didUpdateWidget(CreatedQuizzes oldWidget) {
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
  
  Future<void> _loadUserQuizzes() async {
    if (widget.userData == null || widget.userData!['id'] == null) return;
    
    setState(() {
      _isLoadingQuizzes = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/get_user_quizzes.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userData!['id'],
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          _quizzes = List<Map<String, dynamic>>.from(data['quizzes']);
        });
        
        for (var quiz in _quizzes) {
          await _loadQuizStats(quiz['id']);
        }
      }
    } catch (e) {
      print('Error loading quizzes: $e');
    } finally {
      setState(() {
        _isLoadingQuizzes = false;
      });
    }
  }

  Future<void> _loadQuizStats(int quizId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/get_quiz_stats.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quiz_id': quizId}),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          _quizStats[quizId] = {
            'attempts': data['attempts'],
            'average_score': data['average_score'],
          };
        });
      }
    } catch (e) {
      print('Error loading quiz stats: $e');
    }
  }

  void _showQuizOptions(Map<String, dynamic> quiz, bool isCustom) {
    final stats = isCustom ? _customQuizStats[quiz['id']] : _quizStats[quiz['id']];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      quiz['quiz_name'] ?? 'Untitled Quiz',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        // decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Attempts',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats?['attempts'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 106, 14, 14),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Avg Score',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats?['average_score'] ?? 0}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 106, 14, 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Color.fromARGB(255, 106, 14, 14)),
                title: const Text('Start Quiz'),
                onTap: () {
                  Navigator.pop(context);
                  _startQuiz(quiz, isCustom);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Quiz Name'),
                onTap: () {
                  Navigator.pop(context);
                  _editQuizName(quiz, isCustom);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color.fromARGB(255, 173, 33, 23)),
                title: const Text('Delete Quiz'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteQuiz(quiz, isCustom);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startQuiz(Map<String, dynamic> quiz, bool isCustom) async {
    if (quiz['quiz_type'] == 'Multiple Choice') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultipleChoice(
            quizData: quiz,
            userData: widget.userData,
            isCustomQuiz: isCustom,
          ),
        ),
      );
      if (isCustom) {
        _loadCustomQuizzes();
      } else {
        _loadUserQuizzes();
      }
    } else if (quiz['quiz_type'] == 'Identification') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Identification(
            quizData: quiz,
            userData: widget.userData,
            isCustomQuiz: isCustom,
          ),
        ),
      );
      if (isCustom) {
        _loadCustomQuizzes();
      } else {
        _loadUserQuizzes();
      }
    }
  }

  void _editQuizName(Map<String, dynamic> quiz, bool isCustom) {
    final TextEditingController controller = TextEditingController(text: quiz['quiz_name']);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Edit Quiz Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Quiz Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _updateQuizName(quiz['id'], newName, isCustom);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 106, 14, 14),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateQuizName(int quizId, String newName, bool isCustom) async {
    try {
      final endpoint = isCustom ? 'update_custom_quiz_name.php' : 'update_quiz_name.php';
      
      final response = await http.post(
        Uri.parse('$apiBase/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quiz_id': quizId,
          'user_id': widget.userData!['id'],
          'quiz_name': newName,
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        if (isCustom) {
          await _loadCustomQuizzes();
        } else {
          await _loadUserQuizzes();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz name updated successfully'),
              backgroundColor: Colors.green,
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
          ),
        );
      }
    }
  }

  void _deleteQuiz(Map<String, dynamic> quiz, bool isCustom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Delete Quiz',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 106, 14, 14),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${quiz['quiz_name']}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 106, 14, 14),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final endpoint = isCustom ? 'delete_custom_quiz.php' : 'delete_quiz.php';
        
        final response = await http.post(
          Uri.parse('$apiBase/$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'quiz_id': quiz['id'],
            'user_id': widget.userData!['id'],
          }),
        );

        final data = json.decode(response.body);

        if (data['success'] == true) {
          if (isCustom) {
            await _loadCustomQuizzes();
          } else {
            await _loadUserQuizzes();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quiz deleted successfully'),
                backgroundColor: Colors.green,
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
            ),
          );
        }
      }
    }
  }
  
  Future<void> _loadCustomQuizzes() async {
    if (widget.userData == null || widget.userData!['id'] == null) return;
    
    setState(() {
      _isLoadingCustomQuizzes = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/get_custom_quizzes.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userData!['id'],
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          _customQuizzes = List<Map<String, dynamic>>.from(data['quizzes']);
        });
        
        for (var quiz in _customQuizzes) {
          await _loadCustomQuizStats(quiz['id']);
        }
      }
    } catch (e) {
      print('Error loading custom quizzes: $e');
    } finally {
      setState(() {
        _isLoadingCustomQuizzes = false;
      });
    }
  }

  Future<void> _loadCustomQuizStats(int quizId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/get_custom_quiz_stats.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quiz_id': quizId}),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          _customQuizStats[quizId] = {
            'attempts': data['attempts'],
            'average_score': data['average_score'],
          };
        });
      }
    } catch (e) {
      print('Error loading custom quiz stats: $e');
    }
  }

  String _getQuizTypeAbbreviation(String quizType) {
    if (quizType == 'Multiple Choice') {
      return 'M.C.';
    } else if (quizType == 'Identification') {
      return 'ID.';
    }
    return 'M.C.';
  }

  Widget _buildQuizList(List<Map<String, dynamic>> quizzes, bool isLoading, bool isCustom) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 106, 14, 14),
        ),
      );
    }
    
    if (quizzes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isCustom ? 'No custom quiz created yet' : 'No quiz created yet',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create quiz from the Quiz Creation page',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        final quizTypeAbbr = _getQuizTypeAbbreviation(quiz['quiz_type']);
        
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
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      quizTypeAbbr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quiz['quiz_name'] ?? 'Untitled Quiz',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${quiz['num_questions']} questions',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.black87,
                  size: 24,
                ),
                onPressed: () => _showQuizOptions(quiz, isCustom),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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

              const Text(
                "Quiz List",
                style: TextStyle(
                  fontSize: 23,
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
                  maxHeight: 500,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: _currentTabIndex == 0
                    ? _buildQuizList(_quizzes, _isLoadingQuizzes, false)
                    : _buildQuizList(_customQuizzes, _isLoadingCustomQuizzes, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}