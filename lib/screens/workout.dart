import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/show_error.dart';
import '../widgets/exercise.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/popup.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  WorkoutPageState createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage> {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  int _currentIndex = 2;
  ValueNotifier<String> workoutNameNotifier = ValueNotifier<String>('');
  bool isWorkoutActive = false;
  bool isWorkoutShowing = false;
  String currentWorkoutName = '';
  Map<Object?, Object?>? exerciseMap;
  List<ExerciseWidget> exerciseWidgets = [];
  @override
  void initState() {
    super.initState();
    workoutNameNotifier = ValueNotifier<String>('');
    loadWorkoutState();
    exerciseMap = {};
  }

  @override
  void dispose() {
    workoutNameNotifier.dispose();
    super.dispose();
  }

  Future<void> loadWorkoutState() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    setState(() {
      isWorkoutActive = preference.getBool('isWorkoutActive') ?? false;
      currentWorkoutName = preference.getString('currentWorkoutName') ?? '';
    });
  }

  Future<Map<Object?, Object?>> getExercises() async {
    DatabaseReference workoutsRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Current Workout');

    DatabaseEvent snapshot = await workoutsRef.once();
    Map<Object?, Object?>? exercises =
        snapshot.snapshot.value as Map<Object?, Object?>?;

    Map<Object?, Object?> exercisesMap = {};

    if (exercises != null) {
      exercises.forEach((exerciseName, exerciseDetails) {
        if (exerciseDetails is Map &&
            exerciseDetails.containsKey('name') &&
            exerciseDetails.containsKey('sets')) {
          dynamic setsData = exerciseDetails['sets'];

          if (setsData is List && setsData.isNotEmpty) {
            Map<Object?, Object?>? firstSet =
                setsData[1] as Map<Object?, Object?>?;

            if (firstSet != null) {
              Map<Object?, Object?> exerciseMap = {
                'name': exerciseDetails['name'],
                'sets': firstSet,
              };

              exercisesMap[exerciseName] = exerciseMap;
            }
          }
        }
      });
    }

    return exercisesMap;
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
      currentWorkoutName = newWorkoutName;
      workoutNameNotifier.value = newWorkoutName;
      SharedPreferences preference = await SharedPreferences.getInstance();
      preference.setString('currentWorkoutName', currentWorkoutName);
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
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Current Workout')
        .remove();
    currentWorkoutName = '';
    isWorkoutShowing = false;
    isWorkoutActive = false;
    SharedPreferences preference = await SharedPreferences.getInstance();
    preference.setBool('isWorkoutActive', isWorkoutActive);
    preference.setString('currentWorkoutName', currentWorkoutName);
    setState(() {});
  }

  void cancelWorkout() async {
    Navigator.of(context).pop();
    currentWorkoutName = '';
    isWorkoutShowing = false;
    isWorkoutActive = false;
    SharedPreferences preference = await SharedPreferences.getInstance();
    preference.setBool('isWorkoutActive', isWorkoutActive);
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Current Workout')
        .remove();
  }

  void createExercise(String workoutName, String exerciseName) async {
    DatabaseReference workoutRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Current Workout');

    DatabaseEvent snapshot = await workoutRef.once();
    Map<Object?, Object?>? workouts =
        snapshot.snapshot.value as Map<Object?, Object?>?;
    if (workouts!['default'] == 'No workouts Details yet') {
      await workoutRef.child('default').remove();
    }

    Map<Object?, Object?> newExercise = {
      'name': exerciseName,
      'sets': {
        '1': {
          'number': 1,
          'reps': 1,
          'weight': 10,
        },
      },
    };

    await workoutRef.update({exerciseName: newExercise});

    setState(() {
      exerciseMap?[exerciseName] = newExercise;
    });
  }

  void finishWorkout(String workoutName) async {
    Navigator.of(context).pop();
    currentWorkoutName = '';
    isWorkoutShowing = false;
    isWorkoutActive = false;
    SharedPreferences preference = await SharedPreferences.getInstance();
    preference.setBool('isWorkoutActive', isWorkoutActive);

    DatabaseReference workoutRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Current Workout');

    DatabaseEvent snapshot = await workoutRef.once();
    Map<Object?, Object?>? workoutData =
        snapshot.snapshot.value as Map<Object?, Object?>?;

    if (workoutData != null) {
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('Workouts')
          .child(workoutName)
          .set(workoutData);
    }

    await workoutRef.remove();
  }

  void startWorkout(BuildContext context, String workoutName) async {
    if (isWorkoutActive) {
      ErrorHandler.showError(context, 'A Workout has already started');
      return;
    }
    currentWorkoutName = workoutName;
    isWorkoutShowing = true;
    isWorkoutActive = true;
    SharedPreferences preference = await SharedPreferences.getInstance();
    preference.setBool('isWorkoutActive', isWorkoutActive);
    preference.setString('currentWorkoutName', currentWorkoutName);
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Current Workout')
        .set({});
    DatabaseReference workoutRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Workouts')
        .child(workoutName);
    DatabaseEvent snapshot = await workoutRef.once();
    Map<String, Object?>? workoutData =
        Map<String, Object?>.from(snapshot.snapshot.value as Map);
    workoutData['Workout Name'] = workoutName;
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Current Workout')
        .update(workoutData);
    if (mounted) {
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
                child: buildBottomSheet(workoutName),
              );
            },
          );
        },
      ).whenComplete(() {
        setState(() {
          isWorkoutShowing = false;
          currentWorkoutName = workoutName;
        });
      });
    }
  }

  void continueWorkout(BuildContext context, String workoutName) {
    isWorkoutShowing = true;
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
              child: buildBottomSheet(workoutName),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        isWorkoutShowing = false;
        currentWorkoutName = workoutName;
      });
    });
  }

  Widget buildBottomSheet(String workoutName) {
      print('Building bottom sheet');
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.95,
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
          buildHeaderRow(workoutName),
          buildExerciseList(),
          buildActionButtons(workoutName),
        ],
      ),
    );
  }

  Widget buildHeaderRow(String workoutName) {
    return ValueListenableBuilder<String>(
        valueListenable: workoutNameNotifier,
        builder: (context, value, child) {
          return Column(
            children: [
              const SizedBox(
                width: 300,
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
                            {String? textInput,
                            String? workout,
                            String? exercise}) {
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
                        workoutName,
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
                            {String? textInput,
                            String? workout,
                            String? exercise}) {
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
            ],
          );
        });
  }

void deleteExercise(String exerciseName) async {
  DatabaseReference workoutRef = FirebaseDatabase.instance
      .ref()
      .child('users')
      .child(uid)
      .child('Current Workout')
      .child(exerciseName);

  await workoutRef.remove();

  setState(() {
    print("Before removal: $exerciseWidgets");

    // Filter out the ExerciseWidget with the matching uniqueId
    exerciseWidgets = exerciseWidgets
        .where((exerciseWidget) => exerciseWidget.uniqueId != exerciseName)
        .toList();

    print("After removal: $exerciseWidgets");
  });
  setState(() {
    
  });
}

  Widget buildExerciseList() {
    final contentController = ScrollController();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: FutureBuilder<Map<Object?, Object?>>(
        future: getExercises(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<Object?, Object?>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Text('No exercises yet');
          } else {
            exerciseWidgets = snapshot.data!.entries.map((entry) {
              return ExerciseWidget(
                key: UniqueKey(),
                exerciseEntry: entry.value as Map<Object?, Object?>,
                  uniqueId: entry.key.toString(),
                onDelete: () {
                  deleteExercise(entry.key.toString());
                },
              );
            }).toList();

            return ListView(
              controller: contentController,
              children: exerciseWidgets,
            );
          }
        },
      ),
    );
  }

  Widget buildActionButtons(String workoutName) {
    return Container(
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
                    {String? textInput, String? workout, String? exercise}) {
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
                    {String? textInput, String? workout, String? exercise}) {
                  finishWorkout(workout!);
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
                    {String? textInput, String? workout, String? exercise}) {
                  cancelWorkout();
                },
                workoutName: workoutName,
                okButtonText: 'Cancel Workout',
                cancelButtonText: 'Stay on Workout',
              ).show(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Page'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                        onOkPressed: (
                            {String? textInput,
                            String? workout,
                            String? exercise}) {
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
                            : Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      return ElevatedButton(
                                        onPressed: () {
                                          startWorkout(
                                              context, snapshot.data![index]);
                                        },
                                        child: Text(snapshot.data![index]),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16.0),
                                ],
                              );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (isWorkoutActive && !isWorkoutShowing)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin:
                    const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                width: MediaQuery.of(context).size.width - 32,
                child: GestureDetector(
                  onTap: () {
                    continueWorkout(context, currentWorkoutName);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      "Continue Workout: $currentWorkoutName",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
