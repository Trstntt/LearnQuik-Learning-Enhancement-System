import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learnquik/quiz_result.dart';

class Identification extends StatefulWidget {
  final Map<String, dynamic> quizData;
  final Map<String, dynamic>? userData;
  final bool isCustomQuiz;
  
  const Identification({
    super.key,
    required this.quizData,
    this.userData,
    this.isCustomQuiz = false,
  });

  @override
  State<Identification> createState() => _IdentificationState();
}

class _IdentificationState extends State<Identification> {
  int _currentQuestionIndex = 0;
  Map<int, String> _userAnswers = {};
  final TextEditingController _answerController = TextEditingController();
  
  late List<Map<String, dynamic>> _questions;
  bool _isLoadingQuestions = true;
  
  final String apiBase = "http://192.168.1.7/learnquik";

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/get_custom_quiz_questions.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quiz_id': widget.quizData['id'],
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true && data['questions'] != null) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(data['questions']);
          _isLoadingQuestions = false;
        });
        
        if (_userAnswers.containsKey(_currentQuestionIndex)) {
          _answerController.text = _userAnswers[_currentQuestionIndex]!;
        }
      } else {
        _generateSampleQuestions();
      }
    } catch (e) {
      print('Error loading questions: $e');
      _generateSampleQuestions();
    }
  }

  void _generateSampleQuestions() {
    int numQuestions = widget.quizData['num_questions'] ?? 10;
    _questions = List.generate(numQuestions, (index) {
      return {
        'question': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin vel enim porta, rutrum nisl id, rhoncus lacus.',
        'correct_answer': 'Answer ${index + 1}',
      };
    });
    setState(() {
      _isLoadingQuestions = false;
    });
    
    if (_userAnswers.containsKey(_currentQuestionIndex)) {
      _answerController.text = _userAnswers[_currentQuestionIndex]!;
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Exit Quiz',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 106, 14, 14),
            ),
          ),
          content: const Text(
            'Are you sure you want to exit? Your progress will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 106, 14, 14),
              ),
              child: const Text('Exit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _saveCurrentAnswer() {
    if (_answerController.text.trim().isNotEmpty) {
      _userAnswers[_currentQuestionIndex] = _answerController.text.trim();
    } else {
      _userAnswers.remove(_currentQuestionIndex);
    }
  }

  void _skipQuestion() {
    _saveCurrentAnswer();
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerController.text = _userAnswers[_currentQuestionIndex] ?? '';
      });
    } else {
      _finishQuiz();
    }
  }

  void _nextQuestion() {
    if (_answerController.text.trim().isEmpty) {
      return;
    }
    
    _saveCurrentAnswer();
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerController.text = _userAnswers[_currentQuestionIndex] ?? '';
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    int score = 0;
    
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers.containsKey(i)) {
        final userAnswer = _userAnswers[i]!.toLowerCase().trim();
        final correctAnswer = _questions[i]['correct_answer'].toString().toLowerCase().trim();
        
        if (userAnswer == correctAnswer || 
            userAnswer.contains(correctAnswer) || 
            correctAnswer.contains(userAnswer)) {
          score++;
        }
      }
    }

    print('====== FINISHING QUIZ ======');
    print('Quiz ID: ${widget.quizData['id']}');
    print('Is Custom Quiz: ${widget.isCustomQuiz}');
    print('Score: $score / ${_questions.length}');
    print('===========================');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Result(
          quizData: widget.quizData,
          userData: widget.userData,
          score: score,
          totalQuestions: _questions.length,
          questions: _questions,
          userAnswers: _userAnswers,
          isCustomQuiz: widget.isCustomQuiz,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 106, 14, 14),
          title: Text(
            widget.quizData['quiz_name'] ?? 'Quiz',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 106, 14, 14),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final hasAnswer = _answerController.text.trim().isNotEmpty;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 106, 14, 14),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.quizData['quiz_name'] ?? 'Quiz',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 165, 107, 107),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  currentQuestion['question'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'A:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 165, 107, 107),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _answerController,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type your answer here...',
                      hintStyle: TextStyle(color: Colors.black54),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasAnswer)
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 106, 14, 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        _currentQuestionIndex == _questions.length - 1
                            ? 'FINISH'
                            : 'NEXT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skipQuestion,
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}