import 'package:flutter/material.dart';

class ExerciseWidget extends StatefulWidget {
  final Map<Object?, Object?> exerciseEntry;

  const ExerciseWidget({super.key, required this.exerciseEntry});

  @override
  ExerciseWidgetState createState() => ExerciseWidgetState();
}

class ExerciseWidgetState extends State<ExerciseWidget> {
  late List<_Row> _rows;
  int weight = 0;
  int reps = 0;
  bool isHighlighted = false;
  late String name;
  late Map exerciseMap;

  @override
  void initState() {
    super.initState();
    Map exerciseMap = widget.exerciseEntry;
    name = exerciseMap['name'];
    _rows = <_Row>[
      _Row(1, 2, 3, false),
      _Row(2, 3, 4, false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 350,
              child: DataTable(
                columnSpacing: 60,
                headingRowHeight: 40,
                dataRowMinHeight: 20,
                dataRowMaxHeight: 30,
                columns: const [
                  DataColumn(
                    label: Center(child: Text('Set')),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Center(child: Text('Reps')),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Center(child: Text('lbs')),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Center(child: Text('Finished')),
                    numeric: false,
                  ),
                ],
                rows: getRowWidgets(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<DataRow> getRowWidgets() {
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
            Align(
              alignment: Alignment.center,
              child: Text(row.setValue.toString()),
            ),
          ),
          DataCell(
            Align(
              alignment: Alignment.center,
              child: Text(row.repsValue.toString()),
            ),
          ),
          DataCell(
            Align(
              alignment: Alignment.center,
              child: Text(row.weightValue.toString()),
            ),
          ),
          DataCell(
            Container(
              alignment: Alignment.topLeft,
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
        ],
      );
    }).toList();
  }
}

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
