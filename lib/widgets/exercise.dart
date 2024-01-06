import 'package:flutter/material.dart';

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

class ExerciseWidget extends StatefulWidget {
  final Map<Object?, Object?> exerciseEntry;

  const ExerciseWidget({super.key, required this.exerciseEntry});

  @override
  ExerciseWidgetState createState() => ExerciseWidgetState();
}

class ExerciseWidgetState extends State<ExerciseWidget> {
  late List<_Row> _rows;
  late Map exerciseMap;
  late String name;
  late int setNumber;
  late int weight;
  late int reps;
  bool isHighlighted = false;

  @override
  void initState() {
    super.initState();
    Map exerciseMap = widget.exerciseEntry;
    name = exerciseMap['name'];
    setNumber = exerciseMap['sets']['number'];
    reps = exerciseMap['sets']['reps'];
    weight = exerciseMap['sets']['weight'];
    _rows = <_Row>[
      _Row(setNumber, reps, weight, false),
    ];
  }

  List<DataRow> populateRows() {
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
              child: TextButton(
                onPressed: () {
                  editRepsPopup(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  minimumSize: const Size(10, 60),
                ),
                child: Text(row.repsValue.toString()),
              ),
            ),
          ),
          DataCell(
            Center(
              child: TextButton(
                onPressed: () {
                  editWeightPopup(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  minimumSize: const Size(10, 60),
                ),
                child: Text(row.weightValue.toString()),
              ),
            ),
          ),
          DataCell(
            Center(
              child: Container(
                alignment: Alignment.center,
                child: Checkbox(
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
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  void editRepsPopup(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Reps'),
          content: const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter the number of reps',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                editReps();
              },
            ),
          ],
        );
      },
    );
  }

  void editWeightPopup(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Weight'),
          content: const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter the weight',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                editWeight();
              },
            ),
          ],
        );
      },
    );
  }

  void editReps() {
    Navigator.of(context).pop();
  }

  void editWeight() {
    Navigator.of(context).pop();
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
              columnSpacing: 40,
              headingRowHeight: 40,
              dataRowMinHeight: 20,
              dataRowMaxHeight: 70,
              columns: const [
                DataColumn(
                  label: Text('Set'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Rep'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('lbs'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('\u2713'),
                  numeric: false,
                ),
              ],
              rows: populateRows(),
            ),
          ],
        ),
      ),
    );
  }
}
