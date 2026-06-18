import 'package:flutter/material.dart';

class HomePageItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final double progress;
  final bool isHorizontal;
  final VoidCallback? onTap;

  const HomePageItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.progress,
    this.isHorizontal = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: isHorizontal ? double.infinity : 170,
        margin: const EdgeInsets.only(right: 15, bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.grey.withOpacity(.2),
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: isHorizontal ? horizontalLayout() : verticalLayout(),
      ),
    );
  }

  Widget verticalLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(subtitle),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
      ],
    );
  }

  Widget horizontalLayout() {
    return Row(
      children: [
        Image.asset(imagePath, width: 60, height: 60),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
            ],
          ),
        )
      ],
    );
  }
}