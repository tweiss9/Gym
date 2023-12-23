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
  int _currentIndex = 2;
  List<Widget> exerciseFields = [
    const TextField(
        decoration: InputDecoration(hintText: "Enter exercise name"))
  ];
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

  void createWorkout() {
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
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String workoutName = workoutNameController.text;
    DatabaseReference workoutsRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Workouts');

    DatabaseEvent snapshot = await workoutsRef.once();
    Object? workouts = snapshot.snapshot.value;

    if (workouts is Map && workouts.containsKey(workoutName)) {
      if (mounted) {
        ErrorHandler.showError(context, 'Workout already exists');
      }
    } else {
      await workoutsRef.set({
        workoutName: {'default': 'No workouts Details yet'}
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Page'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: createWorkout,
          child: const Text('Create a Workout'),
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
