import 'package:flutter/material.dart';

class TextPost extends StatelessWidget {
  final String content;

  const TextPost({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        content,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}