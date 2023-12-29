import 'package:flutter/material.dart';

class ExerciseWidget extends StatefulWidget {
  final Map<Object?, Object?> exercise;
  final String workoutName;

  const ExerciseWidget(
      {super.key, required this.exercise, required this.workoutName});

  @override
  ExerciseWidgetState createState() => ExerciseWidgetState();
}

class ExerciseWidgetState extends State<ExerciseWidget> {
  int weight = 0;
  int reps = 0;
  bool isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 131, 131, 131),
      elevation: 4.0,
      margin: const EdgeInsets.all(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.exercise.values.first}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 10.0),
                        const Text(
                          'Set',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 10.0),
                        FloatingActionButton(
                          onPressed: () {
                            setSetNumber(context);
                          },
                          backgroundColor: Colors.grey[300],
                          elevation: 0,
                          mini: true,
                          child: const Text(
                            '1',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 10.0),
                        const Text(
                          'Reps',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 10.0),
                        FloatingActionButton(
                          onPressed: () {
                            setReps(context);
                          },
                          backgroundColor: Colors.grey[300],
                          elevation: 0,
                          mini: true,
                          child: const Text(
                            '1',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 10.0),
                        const Text(
                          'lbs',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 10.0),
                        FloatingActionButton(
                          onPressed: () {
                            setWeight(context);
                          },
                          backgroundColor: Colors.grey[300],
                          elevation: 0,
                          mini: true,
                          child: const Text(
                            '1',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 10.0),
                        const Text(
                          '✓',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 10.0),
                        FloatingActionButton(
                          onPressed: () {
                            setState(() {
                              isHighlighted = !isHighlighted;
                            });
                          },
                          backgroundColor: Colors.grey[300],
                          elevation: 0,
                          mini: true,
                          child: const Text(
                            '✓',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(height: 70.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            addSet(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add Set',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void setSetNumber(BuildContext context) {}

  void setWeight(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Weight'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                weight = int.tryParse(value) ?? 0;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void setReps(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Reps'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                reps = int.tryParse(value) ?? 0;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void addSet(BuildContext context) {}
}
