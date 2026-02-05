import 'package:flutter/material.dart';

class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpState extends State<Help> {
  int _currentTabIndex = 0;

  void _switchTab(int index) {
    if (_currentTabIndex == index) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are already on the ${index == 0 ? "Automated" : "Custom"} instructions'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.grey[700],
        ),
      );
      return;
    }
    
    setState(() {
      _currentTabIndex = index;
    });
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String imagePath,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $stepNumber',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 106, 14, 14),
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image placeholder',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomatedInstructions() {
    return Column(
      children: [
        _buildStepCard(
          stepNumber: 1,
          imagePath: 'lib/assets/images/automated_step1.png',
          description: '   Upload your study materials by clicking the "+" button on the home page. You can upload PDF, DOC, DOCX, or TXT files containing your notes, textbooks, or study guides.',
        ),
        
        _buildStepCard(
          stepNumber: 2,
          imagePath: 'lib/assets/images/automated_step2.png',
          description: '   Navigate to the "Create Quiz" page using the bottom navigation bar. Select the "Automated" tab to use AI-powered quiz generation.',
        ),
        
        _buildStepCard(
          stepNumber: 3,
          imagePath: 'lib/assets/images/automated_step3.png',
          description: '   Select the "Automated" tab to use AI-powered quiz generation then choose your quiz type (Multiple Choice or Identification) and set the number of questions you want (1-50 questions).',
        ),
        
        _buildStepCard(
          stepNumber: 4,
          imagePath: 'lib/assets/images/automated_step4.png',
          description: '   Select the files you want to generate questions from. You can select multiple files by tapping on them. Selected files will show a checkmark.',
        ),
        
        _buildStepCard(
          stepNumber: 5,
          imagePath: 'lib/assets/images/automated_step5.png',
          description: '   Click "Generate with AI" and enter a name for your quiz. The AI will analyze your files and create relevant questions. This may take a moment.',
        ),
        
        _buildStepCard(
          stepNumber: 6,
          imagePath: 'lib/assets/images/automated_step6.png',
          description: '   Once generated, find your quiz in the "Created Quizzes" page.',
        ),
        
        _buildStepCard(
          stepNumber: 7,
          imagePath: 'lib/assets/images/automated_step7.png',
          description: '   Click on the three dots to view quiz options.',
        ),

        _buildStepCard(
          stepNumber: 8,
          imagePath: 'lib/assets/images/automated_step8.png',
          description: '   Displayed on the quiz options are the statistics, start the quiz, edit the name, or delete it.',
        ),

        _buildStepCard(
          stepNumber: 9,
          imagePath: 'lib/assets/images/automated_step9.png',
          description: '   Start the quiz and answer all questions. You can skip questions if needed. After finishing, you\'ll see your score and detailed results showing correct and incorrect answers.',
        ),
      ],
    );
  }

  Widget _buildCustomInstructions() {
    return Column(
      children: [
        _buildStepCard(
          stepNumber: 1,
          imagePath: 'lib/assets/images/custom_step1.png',
          description: '   Navigate to the "Create Quiz" page.',
        ),

        _buildStepCard(
          stepNumber: 2,
          imagePath: 'lib/assets/images/custom_step2.png',
          description: '   Select the "Custom" tab to manually create your own quiz questions.',
        ),
        
        _buildStepCard(
          stepNumber: 3,
          imagePath: 'lib/assets/images/custom_step3.png',
          description: '   Enter a name for your quiz in the "Quiz Name" field. Choose between Multiple Choice or Identification quiz type.',
        ),
        
        _buildStepCard(
          stepNumber: 4,
          imagePath: 'lib/assets/images/custom_step4.png',
          description: '   Set the number of questions (1-50) using the counter. For Multiple Choice quizzes, also set the number of choices per question (2-4).',
        ),
        
        _buildStepCard(
          stepNumber: 5,
          imagePath: 'lib/assets/images/custom_step5.png',
          description: '   Fill in each question and its answers. For Multiple Choice: the FIRST choice is automatically the correct answer (it will be randomized during the quiz). For Identification: enter the correct answer in the answer field.',
        ),
        
        _buildStepCard(
          stepNumber: 6,
          imagePath: 'lib/assets/images/custom_step7.png',
          description: '   After filling in all questions, click "Save" to create your quiz. You can click "Cancel" if you want to discard your work.',
        ),
        
        _buildStepCard(
          stepNumber: 7,
          imagePath: 'lib/assets/images/custom_step7.png',
          description: '   Access your custom quizzes from the "Created Quizzes" page.',
        ),

        _buildStepCard(
          stepNumber: 8,
          imagePath: 'lib/assets/images/custom_step8.png',
          description: '   Select the "Custom" tab. Your quizzes will be listed with their type and number of questions.',
        ),
        
        _buildStepCard(
          stepNumber: 9,
          imagePath: 'lib/assets/images/custom_step9.png',
          description: '   Click on the three dots to view quiz options.',
        ),

        _buildStepCard(
          stepNumber: 10,
          imagePath: 'lib/assets/images/custom_step10.png',
          description: '   Displayed on the quiz options are the statistics, start the quiz, edit the name, or delete it',
        ),

        _buildStepCard(
          stepNumber: 11,
          imagePath: 'lib/assets/images/custom_step11.png',
          description: '   Take your custom quiz by clicking "Start Quiz" from the options menu. View your attempts and average scores in the statistics section.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 106, 14, 14),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Help',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  "System Instructions",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Container(height: 2, color: Colors.black12),
                const SizedBox(height: 20),

                _currentTabIndex == 0 
                    ? _buildAutomatedInstructions()
                    : _buildCustomInstructions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}