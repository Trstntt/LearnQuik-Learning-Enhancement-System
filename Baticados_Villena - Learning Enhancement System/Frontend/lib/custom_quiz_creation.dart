import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomQuizCreation extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onQuizCreated;
  final bool isEmbedded;
  
  const CustomQuizCreation({
    super.key,
    this.userData,
    this.onQuizCreated,
    this.isEmbedded = false,
  });

  @override
  State<CustomQuizCreation> createState() => _CustomQuizCreationState();
}

class _CustomQuizCreationState extends State<CustomQuizCreation> {
  String _selectedQuizType = 'Multiple Choice';
  final TextEditingController _numberOfQuestionsController = TextEditingController(text: '5');
  final TextEditingController _numberOfChoicesController = TextEditingController(text: '4');
  final TextEditingController _quizNameController = TextEditingController();
  
  List<Map<String, dynamic>> _customQuestions = [];
  bool _isSaving = false;
  
  final String apiBase = "http://192.168.1.7/learnquik";

  @override
  void initState() {
    super.initState();
    _generateQuestionFields();
  }

  @override
  void dispose() {
    _numberOfQuestionsController.dispose();
    _numberOfChoicesController.dispose();
    _quizNameController.dispose();
    _disposeQuestionControllers();
    super.dispose();
  }

  void _disposeQuestionControllers() {
    for (var question in _customQuestions) {
      question['questionController']?.dispose();
      if (question['choiceControllers'] != null) {
        for (var controller in question['choiceControllers']) {
          controller?.dispose();
        }
      }
      question['answerController']?.dispose();
    }
  }

  void _generateQuestionFields() {
    _disposeQuestionControllers();
    
    int numQuestions = int.tryParse(_numberOfQuestionsController.text) ?? 5;
    int numChoices = int.tryParse(_numberOfChoicesController.text) ?? 4;
    
    _customQuestions.clear();
    
    for (int i = 0; i < numQuestions; i++) {
      if (_selectedQuizType == 'Multiple Choice') {
        List<TextEditingController> choiceControllers = [];
        for (int j = 0; j < numChoices; j++) {
          choiceControllers.add(TextEditingController());
        }
        
        _customQuestions.add({
          'questionController': TextEditingController(),
          'choiceControllers': choiceControllers,
        });
      } else {
        _customQuestions.add({
          'questionController': TextEditingController(),
          'answerController': TextEditingController(),
        });
      }
    }
    
    setState(() {});
  }

  void _incrementQuestions() {
    int current = int.tryParse(_numberOfQuestionsController.text) ?? 5;
    if (current < 50) {
      setState(() {
        _numberOfQuestionsController.text = (current + 1).toString();
      });
      _generateQuestionFields();
    }
  }

  void _decrementQuestions() {
    int current = int.tryParse(_numberOfQuestionsController.text) ?? 5;
    if (current > 1) {
      setState(() {
        _numberOfQuestionsController.text = (current - 1).toString();
      });
      _generateQuestionFields();
    }
  }

  void _incrementChoices() {
    int current = int.tryParse(_numberOfChoicesController.text) ?? 4;
    if (current < 4) {
      setState(() {
        _numberOfChoicesController.text = (current + 1).toString();
      });
      _generateQuestionFields();
    }
  }

  void _decrementChoices() {
    int current = int.tryParse(_numberOfChoicesController.text) ?? 4;
    if (current > 2) {
      setState(() {
        _numberOfChoicesController.text = (current - 1).toString();
      });
      _generateQuestionFields();
    }
  }

  Future<void> _saveCustomQuiz() async {
    if (_quizNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quiz name'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    for (int i = 0; i < _customQuestions.length; i++) {
      var question = _customQuestions[i];
      
      if (question['questionController'].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter question ${i + 1}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      if (_selectedQuizType == 'Multiple Choice') {
        for (int j = 0; j < question['choiceControllers'].length; j++) {
          if (question['choiceControllers'][j].text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please enter choice ${j + 1} for question ${i + 1}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
        }
      } else {
        if (question['answerController'].text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter answer for question ${i + 1}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      List<Map<String, dynamic>> questionsData = [];
      
      for (var question in _customQuestions) {
        if (_selectedQuizType == 'Multiple Choice') {
          List<String> choices = [];
          for (var controller in question['choiceControllers']) {
            choices.add(controller.text.trim());
          }
          
          questionsData.add({
            'question': question['questionController'].text.trim(),
            'options': choices,
            'correct_answer': 0,
          });
        } else {
          questionsData.add({
            'question': question['questionController'].text.trim(),
            'correct_answer': question['answerController'].text.trim(),
          });
        }
      }

      final response = await http.post(
        Uri.parse('$apiBase/save_custom_quiz.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userData!['id'],
          'quiz_name': _quizNameController.text.trim(),
          'quiz_type': _selectedQuizType,
          'num_questions': _customQuestions.length,
          'num_choices': _selectedQuizType == 'Multiple Choice' 
              ? int.tryParse(_numberOfChoicesController.text) ?? 4 
              : 1,
          'questions': questionsData,
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Custom quiz saved successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted) {
            if (widget.isEmbedded) {
              if (widget.onQuizCreated != null) {
                widget.onQuizCreated!();
              }
            } else {
              Navigator.pop(context);
              if (widget.onQuizCreated != null) {
                widget.onQuizCreated!();
              }
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to save quiz'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print('Exception during quiz save: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showCancelConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Cancel Quiz Creation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 106, 14, 14),
            ),
          ),
          content: const Text(
            'Are you sure you want to cancel? All entered data will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 106, 14, 14),
              ),
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      if (!widget.isEmbedded) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildContent() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Quiz Name",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _quizNameController,
                decoration: InputDecoration(
                  hintText: 'Enter quiz name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 106, 14, 14),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              
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
                              fontSize: 12,
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
                            _generateQuestionFields();
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text(
                            'Identification',
                            style: TextStyle(
                              fontSize: 12,
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
                            _generateQuestionFields();
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
                                    _generateQuestionFields();
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

                  const SizedBox(width: 8),

                  if (_selectedQuizType == 'Multiple Choice')
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
                                onPressed: _incrementChoices,
                              ),
                              Container(
                                width: 50,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TextField(
                                  controller: _numberOfChoicesController,
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
                                      if (num > 4) {
                                        _numberOfChoicesController.text = '4';
                                      } else if (num < 2 && value.isNotEmpty) {
                                        _numberOfChoicesController.text = '2';
                                      }
                                      _generateQuestionFields();
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                onPressed: _decrementChoices,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No. of Choices',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 15),

              Container(
                constraints: const BoxConstraints(
                  minHeight: 400,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < _customQuestions.length; i++) ...[
                        Text(
                          'Question ${i + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _customQuestions[i]['questionController'],
                          decoration: InputDecoration(
                            hintText: 'Enter question',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        if (_selectedQuizType == 'Multiple Choice') ...[
                          const Text(
                            'Choices (First choice is the correct answer):',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (int j = 0; j < _customQuestions[i]['choiceControllers'].length; j++) ...[
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: j == 0 
                                        ? Colors.green.withOpacity(0.2)
                                        : const Color.fromARGB(255, 165, 107, 107),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: j == 0 ? Colors.green : Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + j),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: j == 0 ? Colors.green.shade800 : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _customQuestions[i]['choiceControllers'][j],
                                    decoration: InputDecoration(
                                      hintText: j == 0 
                                          ? 'Correct answer' 
                                          : 'Choice ${String.fromCharCode(65 + j)}',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ] else ...[
                          const Text(
                            'Answer:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customQuestions[i]['answerController'],
                            decoration: InputDecoration(
                              hintText: 'Enter correct answer',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        if (i < _customQuestions.length - 1)
                          const Divider(thickness: 1, color: Colors.black26),
                      ],

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _showCancelConfirmation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[400],
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveCustomQuiz,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 106, 14, 14),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _isSaving ? 'Saving...' : 'Save',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_isSaving)
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
                        'Saving custom quiz...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return _buildContent();
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 106, 14, 14),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Custom Quiz Creation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildContent(),
      ),
    );
  }
}