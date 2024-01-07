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

class WorkoutPageState extends State<WorkoutPage> {
  late TextEditingController workoutNameController;
  late TextEditingController editWorkoutNameController;
  late TextEditingController exerciseController;
  String uid = FirebaseAuth.instance.currentUser!.uid;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    workoutNameController = TextEditingController();
    editWorkoutNameController = TextEditingController();
    exerciseController = TextEditingController();
  }

  @override
  void dispose() {
    workoutNameController.dispose();
    editWorkoutNameController.dispose();
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

  void createWorkoutPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create a Workout'),
          content: TextField(
            controller: workoutNameController,
            decoration: const InputDecoration(hintText: "Enter workout name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                workoutNameController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                createWorkout();
              },
            )
          ],
        );
      },
    );
  }

  void createWorkout() async {
    String? workoutName = workoutNameController.text.trim();
    List<String>? workouts = await getWorkoutNames();
    if (workoutName == '') {
      if (mounted) {
        ErrorHandler.showError(context, 'Workout name cannot be empty');
      }
    } else {
      if (workouts!.contains(workoutName)) {
        if (mounted) {
          ErrorHandler.showError(context, 'Workout already exists');
        }
      } else {
        await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(uid)
            .child('Workouts')
            .update({
          workoutName: {'default': 'No workouts Details yet'}
        });

        if (mounted) {
          Navigator.of(context).pop();
        }
        setState(() {});
        workoutNameController.clear();
      }
    }
  }

  void editWorkoutNamePopup(BuildContext context, String workoutName,
      ValueNotifier<String> workoutNameNotifier) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Workout Name'),
          content: TextField(
            controller: editWorkoutNameController,
            decoration: const InputDecoration(
              hintText: 'Enter new workout name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                editWorkoutNameController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                editWorkoutName(editWorkoutNameController.text, workoutName,
                    context, workoutNameNotifier);
              },
            ),
          ],
        );
      },
    );
  }

  void editWorkoutName(String newWorkoutName, String oldWorkoutName,
      BuildContext dialogContext, workoutNameNotifier) async {
    String? newWorkoutName = editWorkoutNameController.text.trim();
    if (newWorkoutName == '') {
      if (mounted) {
        ErrorHandler.showError(dialogContext, 'Workout name cannot be empty');
        return;
      }
    }
    List<String>? workouts = await getWorkoutNames();
    if (workouts!.contains(newWorkoutName)) {
      if (mounted) {
        ErrorHandler.showError(dialogContext, 'Workout already exists');
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
      if (mounted) {
        Navigator.of(dialogContext).pop();
      }
      setState(() {});
    }
    editWorkoutNameController.clear();
    return;
  }

  void deleteWorkoutPopup(String workoutName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Workout'),
          content: const Text('Are you sure you want to delete this workout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                deleteWorkout(workoutName);
              },
            ),
          ],
        );
      },
    );
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

  void cancelWorkoutPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Workout'),
          content: const Text('Are you sure you want to cancel this workout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Stay on Workout'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel Workout'),
              onPressed: () async {
                cancelWorkout();
              },
            ),
          ],
        );
      },
    );
  }

  void cancelWorkout() {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void createExercisePopup(String workoutName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create an Exercise'),
          content: TextField(
            controller: exerciseController,
            decoration: const InputDecoration(hintText: "Enter exercise name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                exerciseController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                createExercise(workoutName, exerciseController.text);
              },
            )
          ],
        );
      },
    );
  }

  void createExercise(String workoutName, String exerciseName) async {
    if (exerciseName == '') {
      if (mounted) {
        ErrorHandler.showError(context, 'Exercise name cannot be empty');
      }
      return;
    }
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
    if (mounted) {
      Navigator.of(context).pop();
    }
    exerciseController.clear();
  }

  void finishWorkoutPopup(String workoutName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Finish Workout'),
          content: const Text('Are you sure you want to finish this workout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Stay on Workout'),
              onPressed: () async {
                finishWorkout();
              },
            ),
            TextButton(
              child: const Text('Finish Workout'),
              onPressed: () async {
                finishWorkout();
              },
            ),
          ],
        );
      },
    );
  }

  void finishWorkout() {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void showActiveWorkout(BuildContext context, String workoutName) {
    final ValueNotifier<String> workoutNameNotifier =
        ValueNotifier<String>(workoutName);
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
                            deleteWorkoutPopup(workoutName);
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
                            editWorkoutNamePopup(
                                innerContext, workoutName, workoutNameNotifier);
                          },
                        ),
                      ],
                    ),
                    SingleChildScrollView(
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
                            Map<Object?, Object?> exerciseMap = snapshot.data!;
                            for (var exerciseData in exerciseMap.entries) {
                              exerciseWidgets.add(ExerciseWidget(
                                exerciseEntry:
                                    exerciseData.value as Map<Object?, Object?>,
                              ));
                            }
                            return Column(
                              children: exerciseWidgets,
                            );
                          }
                        },
                      ),
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
                              createExercisePopup(workoutName);
                            },
                            child: const Text('Create Exercise',
                                style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              finishWorkoutPopup(workoutName);
                            },
                            child: const Text('Finish Workout',
                                style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              cancelWorkoutPopup();
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
                onPressed: createWorkoutPopup,
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
