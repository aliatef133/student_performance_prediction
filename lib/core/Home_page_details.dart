import 'package:flutter/material.dart';
import 'HomePage_item.dart';
import 'package:edu_prediction/quizes/quiz1.dart';

class HomePageDetails extends StatefulWidget {
  final String token;

  const HomePageDetails({super.key, required this.token});

  @override
  State<HomePageDetails> createState() => _HomePageDetailsState();
}

class _HomePageDetailsState extends State<HomePageDetails> {
  double quiz1Progress = 0.0;

  void _openQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Quiz1(
          title: "Student Quiz",
          token: widget.token,
        ),
      ),
    ).then((returnedProgress) {
      if (returnedProgress != null) {
        setState(() {
          quiz1Progress = returnedProgress as double;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              HomePageItem(
                title: "Quiz 1",
                subtitle: '30 Questions',
                imagePath: "images/assets/student_quiz.webp",
                progress: quiz1Progress,
                onTap: () => _openQuiz(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Percentage for each subject',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        HomePageItem(
          title: "Quiz 1",
          subtitle: '30 Questions',
          imagePath: "images/assets/student_quiz.webp",
          progress: quiz1Progress,
          isHorizontal: true,
          onTap: () => _openQuiz(context),
        ),
      ],
    );
  }
}