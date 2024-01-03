import 'package:flutter/material.dart';

class ExerciseWidget extends StatefulWidget {
  final Map<Object?, Object?> exercise;

  const ExerciseWidget({super.key, required this.exercise});

  @override
  ExerciseWidgetState createState() => ExerciseWidgetState();
}

class ExerciseWidgetState extends State<ExerciseWidget> {
  late List<_Row> _rows;
  int weight = 0;
  int reps = 0;
  bool isHighlighted = false;

  @override
  void initState() {
    super.initState();
    // Map<Object?, Object?> exercise = widget.exercise;
    _rows = <_Row>[
      _Row(1, 2, 3, false),
      _Row(2, 3, 4, false),
      _Row(3, 4, 5, false),
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
                'Table Header',
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
              child: Text(row.valueA.toString()),
            ),
          ),
          DataCell(
            Align(
              alignment: Alignment.center,
              child: Text(row.valueB.toString()),
            ),
          ),
          DataCell(
            Align(
              alignment: Alignment.center,
              child: Text(row.valueC.toString()),
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
    this.valueA,
    this.valueB,
    this.valueC,
    this.isSelected,
  );

  final int valueA;
  final int valueB;
  final int valueC;
  bool isSelected;
}
