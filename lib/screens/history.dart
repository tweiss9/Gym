import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_navigation.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  int _currentIndex = 0;
  String? uid;

  @override
  void initState() {
    super.initState();
    getUid();
  }

  void getUid() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      uid = pref.getString('uid');
    });
  }

  Future<List<Map<String, String>>?> getHistoryData() async {
    DatabaseReference historyRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid!)
        .child('History');

    DatabaseEvent snapshot = await historyRef.once();
    List<Map<String, String>> historyList = [];

    if (snapshot.snapshot.value != null) {
      (snapshot.snapshot.value as Map<dynamic, dynamic>)
          .forEach((exerciseKey, value) {
        String name = value['Name'];
        String date = value['Date'];
        Map<String, String> historyData = {
          'Key': exerciseKey,
          'Name': name,
          'Date': date
        };
        historyList.add(historyData);
      });
    }

    return historyList;
  }

  Future<void> viewHistoryDetails(
      BuildContext context, String key, String workoutName, String date) async {
    DatabaseReference historyRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid!)
        .child('History')
        .child(key)
        .child('Workout Data');

    DatabaseEvent snapshot = await historyRef.once();
    List<Map<String, String>> workoutDataList = [];

    if (snapshot.snapshot.value != null) {
      Map<dynamic, dynamic>? data =
          snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((exerciseKey, exerciseValue) {
          String exerciseName = exerciseKey.toString();
          bool exerciseNameAdded = false;

          if (exerciseValue.containsKey('sets') &&
              exerciseValue['sets'] is List) {
            List<dynamic>? setsDataList = exerciseValue['sets'];

            if (setsDataList != null) {
              for (var setValue in setsDataList) {
                if (setValue != null && setValue is Map<dynamic, dynamic>) {
                  String setNumber = setValue['number']?.toString() ?? '';
                  String number = setValue['number']?.toString() ?? '';
                  String reps = setValue['reps']?.toString() ?? '';
                  String weight = setValue['weight']?.toString() ?? '';

                  Map<String, String> workoutData = {
                    'Exercise': exerciseNameAdded ? '' : exerciseName,
                    'Set': setNumber,
                    'Number': number,
                    'Reps': reps,
                    'Weight': weight,
                  };

                  workoutDataList.add(workoutData);
                  exerciseNameAdded = true;
                }
              }
            }
          }
        });
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Workout Details"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name: $workoutName"),
                    Text("Date: $date"),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: workoutDataList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text("${workoutDataList[index]['Exercise']}"),
                          subtitle: Text(
                              "Set: ${workoutDataList[index]['Set']}, Reps: ${workoutDataList[index]['Reps']}, Weight: ${workoutDataList[index]['Weight']}"),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
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
                  Column(
                    children: [
                      FutureBuilder<List<Map<String, String>>?>(
                        future: getHistoryData(),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Map<String, String>>?>
                                snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: snapshot.data!.length,
                                      itemBuilder: (context, index) {
                                        return ElevatedButton(
                                          onPressed: () {
                                            viewHistoryDetails(
                                              context,
                                              snapshot.data![index]['Key']!,
                                              snapshot.data![index]['Name']!,
                                              snapshot.data![index]['Date']!,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.blueGrey,
                                            fixedSize: const Size(300, 40),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                          ),
                                          child: Text(
                                              '${snapshot.data![index]['Date']!} - ${snapshot.data![index]['Name']!}'),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                ],
                              );
                            } else {
                              return const Text(
                                  'No Finished Workouts, Finish a Workout');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
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
