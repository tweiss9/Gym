import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../widgets/popup.dart';

class _Row {
  _Row(
    this.setValue,
    this.repsValue,
    this.weightValue,
    this.isSelected,
  );

  int setValue;
  int repsValue;
  int weightValue;
  bool isSelected;
}

class ExerciseSet {
  ExerciseSet({
    required this.number,
    required this.reps,
    required this.weight,
    required this.isSelected,
  });

  final int number;
  final int reps;
  final int weight;
  final bool isSelected;
}

class ExerciseWidget extends StatefulWidget {
  final Map<Object?, Object?> exerciseEntry;
  final String uniqueId;
  final VoidCallback onDelete;

  const ExerciseWidget(
      {super.key,
      required this.uniqueId,
      required this.exerciseEntry,
      required this.onDelete});

  @override
  ExerciseWidgetState createState() => ExerciseWidgetState();
}

class ExerciseWidgetState extends State<ExerciseWidget> {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  late List<_Row> _rows = [];
  late Map exerciseMap;
  late ExerciseSet exerciseSet;
  late String name;
  bool isHighlighted = false;

  @override
  void initState() {
    super.initState();
    exerciseMap = widget.exerciseEntry;
    name = exerciseMap['name'];
    fetchExerciseDataFromFirebase();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void fetchExerciseDataFromFirebase() async {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await databaseReference
        .child('users')
        .child(uid)
        .child("Current Workout")
        .child(name)
        .child("sets")
        .once();

    List<_Row> fetchedRows = [];
    dynamic data = event.snapshot.value;

    if (data is List) {
      for (int i = 0; i < data.length; i++) {
        Map<dynamic, dynamic>? setMap = data[i] as Map<dynamic, dynamic>?;

        if (setMap != null) {
          ExerciseSet set = ExerciseSet(
            number: setMap['number'],
            reps: setMap['reps'],
            weight: setMap['weight'],
            isSelected: setMap['isCompleted'],
          );
          fetchedRows.add(_Row(set.number, set.reps, set.weight, set.isSelected));
        }
      }
    } else if (data is Map) {
      Map<dynamic, dynamic>? setsData = data;
      setsData.forEach((key, value) {
        ExerciseSet set = ExerciseSet(
          number: int.parse(key),
          reps: value['reps'],
          weight: value['weight'],
          isSelected: value['isCompleted'],
        );
        fetchedRows.add(_Row(set.number, set.reps, set.weight, set.isSelected));
      });
    }
    if (mounted) {
      setState(() {
        _rows = fetchedRows;
      });
    }
  }

  List<DataRow> createDataRows() {
    return _rows.asMap().entries.map((entry) {
      int rowIndex = entry.key;
      _Row row = entry.value;
      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (row.isSelected) {
              return Colors.green;
            }
            return null;
          },
        ),
        cells: [
          DataCell(
            Center(
              child: Text(row.setValue.toString()),
            ),
          ),
          DataCell(
            Center(
              child: GestureDetector(
                onTap: () {
                  Popup(
                    true,
                    false,
                    title: 'Edit Reps',
                    contentController: 'Enter the number of reps',
                    onOkPressed: ({String? textInput}) {
                      editReps(
                        textInput!,
                        rowIndex,
                      );
                    },
                    okButtonText: 'OK',
                    cancelButtonText: 'Cancel',
                  ).show(context);
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    row.repsValue.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          DataCell(
            Center(
              child: GestureDetector(
                onTap: () {
                  Popup(
                    true,
                    false,
                    title: 'Edit Weight',
                    contentController: 'Enter the weight',
                    onOkPressed: ({String? textInput}) {
                      editWeight(
                        textInput!,
                        rowIndex,
                      );
                    },
                    okButtonText: 'OK',
                    cancelButtonText: 'Cancel',
                  ).show(context);
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    row.weightValue.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          DataCell(
            Checkbox(
              value: row.isSelected,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() {
                    row.isSelected = value;
                  });
                }
              },
              activeColor: Colors.transparent,
            ),
          )
        ],
      );
    }).toList();
  }

  void editReps(String newReps, int rowIndex) {
    if (mounted) {
      setState(() {
        _rows[rowIndex].repsValue = int.parse(newReps);
      });
    }

    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    databaseReference
        .child('users')
        .child(uid)
        .child("Current Workout")
        .child(name)
        .child("sets")
        .child(_rows[rowIndex].setValue.toString())
        .update({
      'reps': int.parse(newReps),
    });
  }

  void editWeight(String newWeight, int rowIndex) {
    if (mounted) {
      setState(() {
        _rows[rowIndex].weightValue = int.parse(newWeight);
      });
    }

    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    databaseReference
        .child('users')
        .child(uid)
        .child("Current Workout")
        .child(name)
        .child("sets")
        .child(_rows[rowIndex].setValue.toString())
        .update({
      'weight': int.parse(newWeight),
    });
  }

  void addSet(String exerciseName) {
    int setNumber = _rows.length + 1;
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    databaseReference
        .child('users')
        .child(uid)
        .child("Current Workout")
        .child(exerciseName)
        .child("sets")
        .child(setNumber.toString())
        .set({
      'number': setNumber,
      'reps': 1,
      'weight': 10,
      'isCompleted': false,
    });

    setState(() {
      _rows.add(_Row(setNumber, 1, 10, false));
    });
  }

  void deleteSet(String exerciseName, int index) {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    String deletedSetKey = _rows[index].setValue.toString();

    databaseReference
        .child('users')
        .child(uid)
        .child("Current Workout")
        .child(exerciseName)
        .child("sets")
        .child(deletedSetKey)
        .remove()
        .then((_) {
      for (int i = index + 1; i < _rows.length; i++) {
        int newSetNumber = i;
        databaseReference
            .child('users')
            .child(uid)
            .child("Current Workout")
            .child(exerciseName)
            .child("sets")
            .child(_rows[i].setValue.toString())
            .remove();
        databaseReference
            .child('users')
            .child(uid)
            .child("Current Workout")
            .child(exerciseName)
            .child("sets")
            .child(newSetNumber.toString())
            .set({
          'number': newSetNumber,
          'reps': _rows[i].repsValue,
          'weight': _rows[i].weightValue,
        });

        setState(() {
          _rows[i].setValue = newSetNumber;
        });
      }

      setState(() {
        _rows.removeAt(index);
      });
    });
  }

  void editExerciseName(String exerciseName, String newName) async {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    databaseReference
        .child('users')
        .child(uid)
        .child("Current Workout")
        .child(exerciseName)
        .remove();
    databaseReference
        .child('users')
        .child(uid)
        .child("Current Workout")
        .child(newName)
        .set({
      'name': newName,
    });

    for (int i = 0; i < _rows.length; i++) {
      int newSetNumber = i + 1;
      databaseReference
          .child('users')
          .child(uid)
          .child("Current Workout")
          .child(newName)
          .child("sets")
          .child(newSetNumber.toString())
          .set({
        'number': newSetNumber,
        'reps': _rows[i].repsValue,
        'weight': _rows[i].weightValue,
      });
    }

    if (mounted) {
      setState(() {
        name = newName;
      });
    }
  }

  void toggleSelect(bool value, int rowIndex) async {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference
        .child('users')
        .child(uid)
        .child("Current Workout")
        .child(name)
        .child("sets")
        .child(_rows[rowIndex].setValue.toString())
        .update({
      'isCompleted': !isHighlighted,
    });
    setState(() {
      isHighlighted = !isHighlighted;
      _rows[rowIndex].isSelected = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete),
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Popup(
                      false,
                      true,
                      title: 'Edit Exercise',
                      contentController: 'Enter the exercise name',
                      onOkPressed: ({String? textInput}) {
                        editExerciseName(name, textInput!);
                      },
                      okButtonText: 'Edit',
                      cancelButtonText: 'Cancel',
                    ).show(context);
                  },
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
              child: const Row(
                children: [
                  SizedBox(
                    width: 73,
                    child: Center(
                      child: Text(
                        'Set',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Center(
                      child: Text(
                        'Rep',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 104,
                    child: Center(
                      child: Text(
                        'lbs',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: Center(
                      child: Text(
                        '\u2713',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            KeyedSubtree(
              key: UniqueKey(),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  _Row row = _rows[index];
                  return Dismissible(
                    key: Key(row.setValue.toString()),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) {
                      if (_rows.length <= 1) {
                        return Future.value(false);
                      }
                      return Future.value(true);
                    },
                    onDismissed: (direction) {
                      deleteSet(name, index);
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      decoration: BoxDecoration(
                        color: row.isSelected ? Colors.green : null,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(row.setValue.toString()),
                          GestureDetector(
                            onTap: () {
                              Popup(
                                true,
                                false,
                                title: 'Edit Reps',
                                contentController: 'Enter the number of reps',
                                onOkPressed: ({String? textInput}) {
                                  editReps(
                                    textInput!,
                                    index,
                                  );
                                },
                                okButtonText: 'OK',
                                cancelButtonText: 'Cancel',
                              ).show(context);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                row.repsValue.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Popup(
                                true,
                                false,
                                title: 'Edit Weight',
                                contentController: 'Enter the weight',
                                onOkPressed: ({String? textInput}) {
                                  editWeight(
                                    textInput!,
                                    index,
                                  );
                                },
                                okButtonText: 'OK',
                                cancelButtonText: 'Cancel',
                              ).show(context);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                row.weightValue.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Checkbox(
                            value: row.isSelected,
                            onChanged: (bool? value) {
                              if (value != null) {
                                toggleSelect(value, index);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                addSet(name);
              },
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        '+ Add Set',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
