import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learnquik/quiz_mc.dart';
import 'package:learnquik/quiz_id.dart';

class CustomCreatedQuizzes extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const CustomCreatedQuizzes({super.key, this.userData});

  @override
  State<CustomCreatedQuizzes> createState() => _CustomCreatedQuizzesState();
}

class _CustomCreatedQuizzesState extends State<CustomCreatedQuizzes> {
  List<Map<String, dynamic>> _customQuizzes = [];
  Map<int, Map<String, dynamic>> _quizStats = {};
  bool _isLoadingQuizzes = false;
  
  final String apiBase = "http://192.168.1.7/learnquik";

  @override
  void initState() {
    super.initState();
    _loadCustomQuizzes();
  }

  @override
  void didUpdateWidget(CustomCreatedQuizzes oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCustomQuizzes();
  }

  Future<void> _loadCustomQuizzes() async {
    if (widget.userData == null || widget.userData!['id'] == null) return;
    
    setState(() {
      _isLoadingQuizzes = true;
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
          await _loadQuizStats(quiz['id']);
        }
      }
    } catch (e) {
      print('Error loading custom quizzes: $e');
    } finally {
      setState(() {
        _isLoadingQuizzes = false;
      });
    }
  }

  Future<void> _loadQuizStats(int quizId) async {
    try {
      print('Loading stats for quiz ID: $quizId');
      
      final response = await http.post(
        Uri.parse('$apiBase/get_custom_quiz_stats.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quiz_id': quizId}),
      );

      print('Stats response: ${response.body}');

      final data = json.decode(response.body);

      if (data['success'] == true) {
        print('Stats loaded: Attempts=${data['attempts']}, Avg=${data['average_score']}');
        setState(() {
          _quizStats[quizId] = {
            'attempts': data['attempts'],
            'average_score': data['average_score'],
          };
        });
      } else {
        print('Stats failed: ${data['message']}');
      }
    } catch (e) {
      print('Error loading quiz stats: $e');
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

  void _showQuizOptions(Map<String, dynamic> quiz) {
    final stats = _quizStats[quiz['id']];
    
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Color.fromARGB(255, 106, 14, 14)),
                title: const Text('Start Quiz'),
                onTap: () {
                  Navigator.pop(context);
                  _startQuiz(quiz);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Quiz Name'),
                onTap: () {
                  Navigator.pop(context);
                  _editQuizName(quiz);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Quiz'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteQuiz(quiz);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startQuiz(Map<String, dynamic> quiz) async {
    if (quiz['quiz_type'] == 'Multiple Choice') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultipleChoice(
            quizData: quiz,
            userData: widget.userData,
            isCustomQuiz: true,
          ),
        ),
      );
      _loadCustomQuizzes();
    } else if (quiz['quiz_type'] == 'Identification') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Identification(
            quizData: quiz,
            userData: widget.userData,
            isCustomQuiz: true,
          ),
        ),
      );
      _loadCustomQuizzes();
    }
  }

  void _editQuizName(Map<String, dynamic> quiz) {
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
                  await _updateQuizName(quiz['id'], newName);
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

  Future<void> _updateQuizName(int quizId, String newName) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/update_custom_quiz_name.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quiz_id': quizId,
          'user_id': widget.userData!['id'],
          'quiz_name': newName,
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        await _loadCustomQuizzes();
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

  void _deleteQuiz(Map<String, dynamic> quiz) async {
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
        final response = await http.post(
          Uri.parse('$apiBase/delete_custom_quiz.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'quiz_id': quiz['id'],
            'user_id': widget.userData!['id'],
          }),
        );

        final data = json.decode(response.body);

        if (data['success'] == true) {
          await _loadCustomQuizzes();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 106, 14, 14),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Custom Quizzes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                child: _isLoadingQuizzes
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 106, 14, 14),
                        ),
                      )
                    : _customQuizzes.isEmpty
                        ? Center(
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
                                    'No custom quiz created yet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create custom quiz from the Quiz Creation page',
                                    textAlign: TextAlign.center,
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
                            itemCount: _customQuizzes.length,
                            itemBuilder: (context, index) {
                              final quiz = _customQuizzes[index];
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
                                      onPressed: () => _showQuizOptions(quiz),
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
      ),
    );
  }
}