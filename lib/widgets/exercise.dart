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

  final int setValue;
  final int repsValue;
  final int weightValue;
  bool isSelected;
}

class ExerciseSet {
  ExerciseSet({
    required this.number,
    required this.reps,
    required this.weight,
  });

  final int number;
  final int reps;
  final int weight;
}

class ExerciseWidget extends StatefulWidget {
  final Map<Object?, Object?> exerciseEntry;

  const ExerciseWidget({super.key, required this.exerciseEntry});

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
          );
          fetchedRows.add(_Row(set.number, set.reps, set.weight, false));
        }
      }
    } else if (data is Map) {
      Map<dynamic, dynamic>? setsData = data;
      setsData.forEach((key, value) {
        ExerciseSet set = ExerciseSet(
          number: int.parse(key),
          reps: value['reps'],
          weight: value['weight'],
        );
        fetchedRows.add(_Row(set.number, set.reps, set.weight, false));
      });
    }

    setState(() {
      _rows = fetchedRows;
    });
  }

  List<DataColumn> createDataColumns() {
    return [
      DataColumn(
        label: Container(
          alignment: Alignment.center,
          width: 25,
          child: const Text('Set'),
        ),
      ),
      DataColumn(
        label: Container(
          alignment: Alignment.center,
          width: 50,
          child: const Text('Rep'),
        ),
      ),
      DataColumn(
        label: Container(
          alignment: Alignment.center,
          width: 50,
          child: const Text('lbs'),
        ),
      ),
      DataColumn(
        label: Container(
          alignment: Alignment.center,
          width: 50,
          child: const Text('\u2713'),
        ),
      ),
    ];
  }

  List<DataRow> createDataRows() {
    return _rows.map((row) {
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
                    onOkPressed: ({String? textInput, String? workout}) {
                      editReps();
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
                    onOkPressed: ({String? textInput, String? workout}) {
                      editWeight();
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

  void editReps() {}

  void editWeight() {}

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
    });

    setState(() {
      _rows.add(_Row(setNumber, 1, 10, false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: Column(
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 20,
              dataRowMaxHeight: 70,
              columns: createDataColumns(),
              rows: createDataRows(),
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
