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
  late String uid;
  int _currentIndex = 1;
  ValueNotifier<List<ExerciseWidget>> exerciseWidgetsNotifier =
      ValueNotifier<List<ExerciseWidget>>([]);
  ValueNotifier<String> workoutNameNotifier = ValueNotifier<String>('');
  ValueNotifier<List<String>> workoutListNotifier =
      ValueNotifier<List<String>>([]);
  bool isWorkoutActive = false;
  bool isWorkoutShowing = false;
  String currentWorkoutName = '';
  Map<Object?, Object?>? exerciseMap = {};
  List<ExerciseWidget> exerciseWidgets = [];

  @override
  void initState() {
    super.initState();
    loadWorkoutState();
  }

  @override
  void dispose() {
    workoutNameNotifier.dispose();
    exerciseWidgetsNotifier.dispose();
    super.dispose();
  }

  Future<void> loadWorkoutState() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    setState(() {
      isWorkoutActive = preference.getBool('isWorkoutActive') ?? false;
      currentWorkoutName = preference.getString('currentWorkoutName') ?? '';
      uid = preference.getString('uid') ?? '';
    });
    if (currentWorkoutName.isNotEmpty) {
      workoutNameNotifier = ValueNotifier<String>(currentWorkoutName);
    }
    List<String>? workoutList = await getWorkoutNames();
    workoutListNotifier.value = workoutList ?? [];
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

  Future<void> updateExerciseWidgets() async {
    Map<Object?, Object?> exercises = await getExercises();
    List<ExerciseWidget> updatedWidgets = [];

    exercises.forEach((exerciseName, exerciseDetails) {
      updatedWidgets.add(
        ExerciseWidget(
          key: ValueKey<String>(exerciseName as String),
          uniqueId: exerciseName,
          exerciseEntry: exerciseDetails as Map<Object?, Object?>,
          onDelete: () => deleteExercise(exerciseName),
        ),
      );
    });

    exerciseWidgetsNotifier.value = updatedWidgets;
    exerciseWidgets = updatedWidgets;
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
      workoutListNotifier.value = [...workouts, workoutName];
      setState(() {});
      return;
    }
  }

  void editWorkoutName(String newName) async {
    List<String>? workouts = await getWorkoutNames();
    if (workouts!.contains(newName)) {
      if (mounted) {
        ErrorHandler.showError(context, 'Workout already exists');
      }
      return;
    } else {
      String oldName = currentWorkoutName;
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('Current Workout')
          .update({'Workout Name': newName});

      setState(() {
        currentWorkoutName = newName;
        workoutNameNotifier.value = newName;
      });

      final ref = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('Workouts');
      final event = await ref.child(oldName).once();
      final value = event.snapshot.value;
      await ref.child(newName).set(value);
      await ref.child(oldName).remove();
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('Workouts')
          .child(newName)
          .update({'Workout Name': newName});
      SharedPreferences preference = await SharedPreferences.getInstance();
      preference.setString('currentWorkoutName', newName);
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
    workoutListNotifier.value =
        workoutListNotifier.value.where((w) => w != workoutName).toList();

    currentWorkoutName = '';
    workoutNameNotifier = ValueNotifier<String>('');
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
    workoutNameNotifier = ValueNotifier<String>('');
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
          'isCompleted': false,
        },
      },
    };

    await workoutRef.update({exerciseName: newExercise});

    ExerciseWidget newExerciseWidget = ExerciseWidget(
      key: UniqueKey(),
      exerciseEntry: newExercise,
      uniqueId: exerciseName,
      onDelete: () {
        deleteExercise(exerciseName);
      },
    );

    exerciseWidgets.add(newExerciseWidget);

    exerciseWidgetsNotifier.value = List.from(exerciseWidgets);
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
      exerciseWidgets =
          exerciseWidgets.where((w) => w.uniqueId != exerciseName).toList();
    });

    exerciseWidgetsNotifier.value = List.from(exerciseWidgets);
    if (exerciseWidgets.isEmpty) {
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('Current Workout')
          .update({'default': 'No workouts Details yet'});
    }
  }

  void startWorkout(BuildContext context, String workoutName) async {
    if (isWorkoutActive) {
      ErrorHandler.showError(context, 'A Workout has already started');
      return;
    }
    currentWorkoutName = workoutName;
    workoutNameNotifier.value = workoutName;
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
    workoutData.forEach((key, value) {
      if (value is Map<Object?, Object?> && key != 'Workout Name') {
        if (value.containsKey('sets') && value['sets'] is List) {
          List<dynamic>? sets = value['sets'] as List<dynamic>?;

          if (sets != null) {
            for (int i = 0; i < sets.length; i++) {
              if (sets[i] is Map<Object?, Object?>) {
                (sets[i] as Map<Object?, Object?>)['isCompleted'] = false;
              }
            }
          }
        }
      }
    });
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Current Workout')
        .update(workoutData);
  
    
    await updateExerciseWidgets();
    buildWorkout();
  }

  void continueWorkout(BuildContext context) async {
    isWorkoutShowing = true;
    await updateExerciseWidgets();
    buildWorkout();
  }

  void finishWorkout(String workoutName) async {
    Navigator.of(context).pop();
    currentWorkoutName = '';
    workoutNameNotifier = ValueNotifier<String>('');
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

    workoutData!.forEach((key, value) {
      if (value is Map<Object?, Object?> && key != 'Workout Name') {
        if (value.containsKey('sets') && value['sets'] is List) {
          List<dynamic>? sets = value['sets'] as List<dynamic>?;
          if (sets != null) {
            for (int i = 0; i < sets.length; i++) {
              if (sets[i] is Map<Object?, Object?> &&
                  sets[i].containsKey('isCompleted')) {
                (sets[i] as Map<Object?, Object?>).remove('isCompleted');
              }
            }
          }
        }
      }
    });

    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Workouts')
        .child(workoutName)
        .set(workoutData);

    Map<Object?, Object?>? historyData = removeUnwantedFields(workoutData);

    DateTime now = DateTime.now();
    String date = '${now.month}-${now.day}-${now.year}';
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('History')
        .push()
        .set({'Date': date, 'Name': workoutName, 'Workout Data': historyData});
    await workoutRef.remove();
  }

  dynamic removeUnwantedFields(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is Map<Object?, Object?>) {
      Map<Object?, Object?> cleanedData = Map.from(data);

      cleanedData.remove('Workout Name');
      cleanedData.remove('name');
      cleanedData.forEach((key, value) {
        cleanedData[key] = removeUnwantedFields(value);
      });

      return cleanedData;
    } else if (data is List) {
      List cleanedList = [];
      for (var item in data) {
        cleanedList.add(removeUnwantedFields(item));
      }
      return cleanedList;
    }
    return data;
  }

  void buildWorkout() {
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
                child: Container(
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
                      buildHeaderRow(),
                      buildExerciseList(),
                      buildActionButtons(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ).whenComplete(() {
        setState(() {
          isWorkoutShowing = false;
        });
      });
    }
  }

  Widget buildHeaderRow() {
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
                  onOkPressed: ({
                    String? textInput,
                  }) {
                    deleteWorkout(currentWorkoutName);
                  },
                  okButtonText: 'Delete',
                  cancelButtonText: 'Cancel',
                ).show(context);
              },
            ),
            const Spacer(),
            Text(
              workoutNameNotifier.value.isNotEmpty
                  ? workoutNameNotifier.value
                  : currentWorkoutName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
                  onOkPressed: ({
                    String? textInput,
                  }) {
                    editWorkoutName(textInput!);
                  },
                  okButtonText: 'Edit',
                  cancelButtonText: 'Cancel',
                ).show(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget buildExerciseList() {
    final contentController = ScrollController();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: ValueListenableBuilder<List<ExerciseWidget>>(
        valueListenable: exerciseWidgetsNotifier,
        builder: (context, value, child) {
          if (value.isEmpty) {
            return const Center(
              child: Text('No Exercises Created. Add an exercise to start.'),
            );
          } else {
            return ListView(
              controller: contentController,
              children: value,
            );
          }
        },
      ),
    );
  }

  Widget buildActionButtons() {
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
                onOkPressed: ({String? textInput}) {
                  createExercise(currentWorkoutName, textInput!);
                },
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
                onOkPressed: ({String? textInput}) {
                  finishWorkout(currentWorkoutName);
                },
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
                onOkPressed: ({String? textInput}) {
                  cancelWorkout();
                },
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
        title: const Center(child: Text('Workout')),
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
                        onOkPressed: ({String? textInput}) {
                          createWorkout(textInput!);
                        },
                        okButtonText: 'Add',
                        cancelButtonText: 'Cancel',
                      ).show(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      fixedSize: const Size(320, 40),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('Create a Workout'),
                  ),
                  const SizedBox(height: 20.0),
                  FutureBuilder<List<String>?>(
                    future: getWorkoutNames(),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<String>?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox();
                      } else {
                        if (snapshot.data != null &&
                            snapshot.data!.isNotEmpty) {
                          return Column(
                            children: [
                              SizedBox(
                                width: 320,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    return ElevatedButton(
                                      onPressed: () {
                                        startWorkout(
                                            context, snapshot.data![index]);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blueGrey,
                                        fixedSize: const Size(300, 40),
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero),
                                      ),
                                      child: Text(snapshot.data![index]),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16.0),
                            ],
                          );
                        } else {
                          return const Text(
                              'No Saved Workouts, Create A Workout');
                        }
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
                    continueWorkout(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'Continue Workout - $currentWorkoutName',
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
