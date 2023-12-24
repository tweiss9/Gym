import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gym/widgets/show_error.dart';
import '../widgets/bottom_navigation.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  WorkoutPageState createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage> {
  late TextEditingController workoutNameController;
  String uid = FirebaseAuth.instance.currentUser!.uid;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    workoutNameController = TextEditingController();
  }

  @override
  void dispose() {
    workoutNameController.dispose();
    super.dispose();
  }

  Future<Object?> getWorkouts() async {
    DatabaseReference workoutsRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Workouts');
    DatabaseEvent snapshot = await workoutsRef.once();
    Object? workouts = snapshot.snapshot.value;
    return workouts;
  }

  void showWorkoutPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: AlertDialog(
            titlePadding: const EdgeInsets.all(0),
            title: Stack(
              children: <Widget>[
                const Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: Text('Create a Workout'),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: workoutNameController,
                    decoration:
                        const InputDecoration(hintText: "Enter workout name"),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: addWorkoutToAccount,
                      child: const Text(
                        'Create Workout',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void addWorkoutToAccount() async {
    String? workoutName = workoutNameController.text.trim();
    Object? workouts = getWorkouts();
    if (workoutName == '') {
      if (mounted) {
        ErrorHandler.showError(context, 'Workout name cannot be empty');
      }
    } else {
      if (workouts is Map && workouts.containsKey(workoutName)) {
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
      }
      workoutNameController.clear();
    }
  }

  Future<List<String>?> fetchWorkouts() async {
    Map? workouts = (await getWorkouts()) as Map?;
    return workouts?.keys.cast<String>().toList();
  }

  void showActiveWorkout(BuildContext context, String workoutName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
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
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 325,
                      child: Divider(
                        color: Colors.grey,
                        thickness: 4.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        workoutName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white)),
                    ),
                    // Add other widgets here
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
                onPressed: showWorkoutPopup,
                child: const Text('Create a Workout'),
              ),
              const SizedBox(height: 20.0),
              FutureBuilder<List<String>?>(
                future: fetchWorkouts(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<String>?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return snapshot.data != null && snapshot.data!.isEmpty
                        ? const Text('No data available')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return ElevatedButton(
                                onPressed: () {
                                  showActiveWorkout(context,
                                      snapshot.data![index].toString());
                                },
                                child: Text(snapshot.data![index].toString()),
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
