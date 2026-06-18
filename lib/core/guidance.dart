import 'package:edu_prediction/features/layout.dart';
import 'package:edu_prediction/quizes/quiz1.dart';
import 'package:flutter/material.dart';
class GuidancePage extends StatelessWidget {
  final String token;

  const GuidancePage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> steps = [
      {
        'icon': Icons.play_circle_fill_rounded,
        'title': 'Start the Assessment',
        'description':
        'Press the Get Started button to begin answering the questionnaire.',
      },
      {
        'icon': Icons.quiz_rounded,
        'title': 'Answer All Questions',
        'description':
        'Read each question carefully and choose the answer that best describes your situation.',
      },
      {
        'icon': Icons.checklist_rounded,
        'title': 'Review Your Answers',
        'description':
        'Make sure all questions are answered before submitting the assessment.',
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'View the Prediction',
        'description':
        'After submission, the system will analyze your responses and display the predicted result.',
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'Use the Result as Guidance',
        'description':
        'The prediction is intended to provide guidance and should not replace academic advice from instructors.',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'User Guide',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Instructions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(step['icon']),
                  title: Text(step['title']),
                  subtitle: Text(step['description']),
                  trailing: CircleAvatar(
                    radius: 12,
                    child: Text('${index + 1}'),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Layout(token: token, title: '', previousAnswers: {},)));
                },
                child: const Padding(
                  padding: EdgeInsets.all(17),
                  child: Text('Get Started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}