import 'package:flutter/material.dart';

class ExerciseWidget extends StatelessWidget {
  final Map<Object?, Object?> exercise;
  final String workoutName;

  const ExerciseWidget({super.key, required this.exercise, required this.workoutName});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(exercise['name'] as String),
      subtitle: Text(exercise['description'] as String),
    );
  }
}