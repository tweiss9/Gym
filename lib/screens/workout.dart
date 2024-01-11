import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../widgets/show_error.dart';
import '../widgets/exercise.dart';
import '../widgets/bottom_navigation.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  WorkoutPageState createState() => WorkoutPageState();
}

class Popup {
  final String title;
  final String contentController;
  final Function({String? textInput, String? workout}) onOkPressed;
  final String? workoutName;
  final String okButtonText;
  final String cancelButtonText;
  final bool isNumber;
  final bool isText;
  final TextEditingController textController = TextEditingController();

  Popup(this.isNumber, this.isText,
      {required this.title,
      required this.contentController,
      required this.onOkPressed,
      this.workoutName,
      required this.okButtonText,
      required this.cancelButtonText});

  void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: isNumber || isText
              ? (isNumber
                  ? TextField(
                      controller: textController,
                      decoration: InputDecoration(hintText: contentController),
                      keyboardType: TextInputType.number,
                    )
                  : TextField(
                      controller: textController,
                      decoration: InputDecoration(hintText: contentController),
                    ))
              : Text(contentController),
          actions: <Widget>[
            TextButton(
              child: Text(cancelButtonText),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(okButtonText),
              onPressed: () {
                String? textInput =
                    isText || isNumber ? textController.text.trim() : null;
                if (textController.text.trim() == '' && isText) {
                  ErrorHandler.showError(context, 'Input cannot be empty');
                  return;
                }
                onOkPressed(textInput: textInput, workout: workoutName);
                Navigator.of(context).pop();
                textController.clear();
              },
            ),
          ],
        );
      },
    );
  }
}

class WorkoutPageState extends State<WorkoutPage> {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  int _currentIndex = 2;
  ValueNotifier<String> workoutNameNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    workoutNameNotifier = ValueNotifier<String>('');
  }

  @override
  void dispose() {
    workoutNameNotifier.dispose();
    super.dispose();
  }

  Future<Map<Object?, Object?>> getExercises(String workoutName) async {
    DatabaseReference workoutsRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Workouts')
        .child(workoutName);
    DatabaseEvent snapshot = await workoutsRef.once();
    Map<Object?, Object?>? workouts =
        snapshot.snapshot.value as Map<Object?, Object?>?;
    if (workouts == null || workouts['default'] == 'No workouts Details yet') {
      return {};
    }
    return workouts;
  }

  Future<List<String>?> getWorkoutNames() async {
    DatabaseReference workoutsRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Workouts');
    DatabaseEvent snapshot = await workoutsRef.once();
    Map<Object?, Object?>? workouts =
        snapshot.snapshot.value as Map<Object?, Object?>?;
    List<String>? workoutNames =
        workouts?.keys.map((key) => key as String).toList() ?? [];
    return workoutNames;
  }

  void createWorkout(String workoutName) async {
    List<String>? workouts = await getWorkoutNames();
    if (workouts!.contains(workoutName)) {
      if (mounted) {
        ErrorHandler.showError(context, 'Workout already exists');
      }
      return;
    } else {
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('Workouts')
          .update({
        workoutName: {'default': 'No workouts Details yet'}
      });
      setState(() {});
      return;
    }
  }

  void editWorkoutName(
    String newWorkoutName,
    String oldWorkoutName,
  ) async {
    List<String>? workouts = await getWorkoutNames();
    if (workouts!.contains(newWorkoutName)) {
      if (mounted) {
        ErrorHandler.showError(context, 'Workout already exists');
      }
      return;
    } else {
      final ref = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('Workouts');
      final event = await ref.child(oldWorkoutName).once();
      final value = event.snapshot.value;
      await ref.child(newWorkoutName).set(value);
      await ref.child(oldWorkoutName).remove();
      oldWorkoutName = newWorkoutName;
      workoutNameNotifier.value = newWorkoutName;
      setState(() {});
    }
    return;
  }

  void deleteWorkout(String workoutName) async {
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Workouts')
        .child(workoutName)
        .remove();
    if (mounted) {
      Navigator.of(context).pop();
    }
    setState(() {});
  }

  void cancelWorkout() {
    Navigator.of(context).pop();
  }

  void createExercise(String workoutName, String exerciseName) async {
    DatabaseReference workoutRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Workouts')
        .child(workoutName);

    DatabaseEvent snapshot = await workoutRef.once();
    Map<Object?, Object?>? workouts =
        snapshot.snapshot.value as Map<Object?, Object?>?;
    if (workouts!['default'] == 'No workouts Details yet') {
      await workoutRef.child('default').remove();
    }
    await workoutRef.update({
      exerciseName: {
        'name': exerciseName,
        'sets': {
          'number': 1,
          'reps': 1,
          'weight': 10,
        },
      }
    });
    setState(() {});
  }

  void finishWorkout() {
    Navigator.of(context).pop();
  }

  void showActiveWorkout(BuildContext context, String workoutName) {
    workoutNameNotifier.value = workoutName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.95,
          builder:
              (BuildContext innerContext, ScrollController scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 325,
                      child: Divider(
                        color: Colors.grey,
                        thickness: 4.0,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Color.fromARGB(255, 245, 98, 88),
                          ),
                          onPressed: () {
                            Popup(
                              false,
                              false,
                              title: 'Delete Workout',
                              contentController:
                                  'Are you sure you want to delete this workout?',
                              onOkPressed: (
                                  {String? textInput, String? workout}) {
                                deleteWorkout(workout!);
                              },
                              workoutName: workoutName,
                              okButtonText: 'Delete',
                              cancelButtonText: 'Cancel',
                            ).show(context);
                          },
                        ),
                        const Spacer(),
                        ValueListenableBuilder<String>(
                          valueListenable: workoutNameNotifier,
                          builder: (context, value, child) {
                            return Text(
                              value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Popup(
                              false,
                              true,
                              title: 'Edit Workout Name',
                              contentController: 'Enter new workout name',
                              onOkPressed: (
                                  {String? textInput, String? workout}) {
                                editWorkoutName(
                                  textInput!,
                                  workout!,
                                );
                              },
                              workoutName: workoutName,
                              okButtonText: 'Edit',
                              cancelButtonText: 'Cancel',
                            ).show(context);
                          },
                        ),
                      ],
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: workoutNameNotifier,
                      builder: (context, workoutName, child) {
                        return SingleChildScrollView(
                          controller: scrollController,
                          child: FutureBuilder<Map<Object?, Object?>>(
                            future: getExercises(workoutName),
                            builder: (BuildContext context,
                                AsyncSnapshot<Map<Object?, Object?>> snapshot) {
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (snapshot.data == null ||
                                  snapshot.data!.isEmpty) {
                                return const Text('No exercises yet');
                              } else {
                                List<ExerciseWidget> exerciseWidgets = [];
                                Map<Object?, Object?> exerciseMap =
                                    snapshot.data!;
                                for (var exerciseData in exerciseMap.entries) {
                                  exerciseWidgets.add(ExerciseWidget(
                                    exerciseEntry: exerciseData.value
                                        as Map<Object?, Object?>,
                                  ));
                                }
                                return Column(
                                  children: exerciseWidgets,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.white,
                      child: Row(
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              Popup(
                                false,
                                true,
                                title: 'Create an Exercise',
                                contentController: 'Enter exercise name',
                                onOkPressed: (
                                    {String? textInput, String? workout}) {
                                  createExercise(workout!, textInput!);
                                },
                                workoutName: workoutName,
                                okButtonText: 'Create',
                                cancelButtonText: 'Cancel',
                              ).show(context);
                            },
                            child: const Text('Create Exercise',
                                style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              Popup(
                                false,
                                false,
                                title: 'Finish Workout',
                                contentController:
                                    'Are you sure you want to finish this workout?',
                                onOkPressed: (
                                    {String? textInput, String? workout}) {
                                  finishWorkout();
                                },
                                workoutName: workoutName,
                                okButtonText: 'Finish Workout',
                                cancelButtonText: 'Stay on Workout',
                              ).show(context);
                            },
                            child: const Text('Finish Workout',
                                style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Popup(
                                false,
                                false,
                                title: 'Cancel Workout',
                                contentController:
                                    'Are you sure you want to cancel this workout?',
                                onOkPressed: (
                                    {String? textInput, String? workout}) {
                                  cancelWorkout();
                                },
                                workoutName: workoutName,
                                okButtonText: 'Cancel Workout',
                                cancelButtonText: 'Stay on Workout',
                              ).show(context);
                            },
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Page'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Popup(
                    false,
                    true,
                    title: 'Create a Workout',
                    contentController: 'Enter workout name',
                    onOkPressed: ({String? textInput, String? workout}) {
                      createWorkout(textInput!);
                    },
                    okButtonText: 'Add',
                    cancelButtonText: 'Cancel',
                  ).show(context);
                },
                child: const Text('Create a Workout'),
              ),
              const SizedBox(height: 20.0),
              FutureBuilder<List<String>?>(
                future: getWorkoutNames(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<String>?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else {
                    return snapshot.data != null && snapshot.data!.isEmpty
                        ? const Text('No Saved Workouts, Create A Workout')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return ElevatedButton(
                                onPressed: () {
                                  showActiveWorkout(
                                      context, snapshot.data![index]);
                                },
                                child: Text(snapshot.data![index]),
                              );
                            },
                          );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
