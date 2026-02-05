import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Result extends StatefulWidget {
  final Map<String, dynamic> quizData;
  final Map<String, dynamic>? userData;
  final int score;
  final int totalQuestions;
  final List<Map<String, dynamic>> questions;
  final Map<int, dynamic> userAnswers;
  final bool isCustomQuiz;
  
  const Result({
    super.key,
    required this.quizData,
    this.userData,
    required this.score,
    required this.totalQuestions,
    required this.questions,
    required this.userAnswers,
    this.isCustomQuiz = false,
  });

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  final String apiBase = "http://192.168.1.7/learnquik";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _saveQuizAttempt();
  }

  Future<void> _saveQuizAttempt() async {
    setState(() {
      _isSaving = true;
    });

    try {
      List<Map<String, dynamic>> answersData = [];
      for (int i = 0; i < widget.questions.length; i++) {
        answersData.add({
          'question': widget.questions[i]['question'],
          'correct_answer': widget.questions[i]['correct_answer'] ?? 
                          widget.questions[i]['options']?[widget.questions[i]['correct_answer']],
          'user_answer': widget.userAnswers[i] ?? 'Skipped',
        });
      }

      final endpoint = widget.isCustomQuiz 
          ? 'save_custom_quiz_attempt.php' 
          : 'save_quiz_attempt.php';

      print('=== SAVING QUIZ ATTEMPT ===');
      print('Endpoint: $endpoint');
      print('Quiz ID: ${widget.quizData['id']}');
      print('Is Custom Quiz (from widget): ${widget.isCustomQuiz}');
      print('==========================');

      final response = await http.post(
        Uri.parse('$apiBase/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quiz_id': widget.quizData['id'],
          'user_id': widget.userData!['id'],
          'score': widget.score,
          'total_questions': widget.totalQuestions,
          'answers': answersData,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);
      if (data['success'] != true) {
        print('❌ Failed to save attempt: ${data['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save: ${data['message']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('✅ Attempt saved successfully');
      }
    } catch (e) {
      print('❌ Error saving attempt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _getScoreMessage() {
    final percentage = (widget.score / widget.totalQuestions) * 100;
    if (percentage >= 90) {
      return 'Excellent!';
    } else if (percentage >= 75) {
      return 'Great Job!';
    } else if (percentage >= 60) {
      return 'Good!';
    } else if (percentage >= 50) {
      return 'Not Bad!';
    } else {
      return 'Keep Trying!';
    }
  }

  bool _isAnswerCorrect(int index) {
    final question = widget.questions[index];
    final userAnswer = widget.userAnswers[index];
    
    if (userAnswer == null) return false;
    
    if (question['correct_answer'] is int) {
      return userAnswer == question['correct_answer'];
    }
    
    return userAnswer.toString().toLowerCase().trim() == 
           question['correct_answer'].toString().toLowerCase().trim();
  }

  String _getCorrectAnswer(int index) {
    final question = widget.questions[index];
    
    if (question['options'] != null && question['correct_answer'] is int) {
      return question['options'][question['correct_answer']];
    }
    
    return question['correct_answer'].toString();
  }

  String _getUserAnswer(int index) {
    final userAnswer = widget.userAnswers[index];
    
    if (userAnswer == null) return 'Skipped';
    
    final question = widget.questions[index];
    if (question['options'] != null && userAnswer is int) {
      return question['options'][userAnswer];
    }
    
    return userAnswer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.totalQuestions) * 100;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 106, 14, 14),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: const Text(
          'Quiz Result',
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
            children: [
              const Text(
                'Your Score',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 106, 14, 14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.score} / ${widget.totalQuestions}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getScoreMessage(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final isCorrect = _isAnswerCorrect(index);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q. ${index + 1}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 165, 107, 107),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.questions[index]['question'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                children: [
                                  Icon(
                                    isCorrect ? Icons.check_circle : Icons.cancel,
                                    color: isCorrect ? Colors.green : const Color.fromARGB(255, 110, 25, 20),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isCorrect ? 'Correct' : 'Incorrect',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect ? Colors.green : const Color.fromARGB(255, 110, 25, 20),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              Text(
                                'Correct Answer: ${_getCorrectAnswer(index)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              Text(
                                'Your Answer: ${_getUserAnswer(index)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isCorrect ? Colors.green : const Color.fromARGB(255, 110, 25, 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}