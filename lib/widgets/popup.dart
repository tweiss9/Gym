import 'package:flutter/material.dart';
import '../widgets/show_error.dart';

class Popup {
  final String title;
  final String contentController;
  final Function({String? textInput, String? workout}) onOkPressed;
  final String? workoutName;
  final String okButtonText;
  final String cancelButtonText;
  final bool isNumber;
  final bool isText;
  final TextEditingController textController = TextEditingController();

  Popup(this.isNumber, this.isText,
      {required this.title,
      required this.contentController,
      required this.onOkPressed,
      this.workoutName,
      required this.okButtonText,
      required this.cancelButtonText});

  void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: isNumber || isText
              ? (isNumber
                  ? TextField(
                      controller: textController,
                      decoration: InputDecoration(hintText: contentController),
                      keyboardType: TextInputType.number,
                    )
                  : TextField(
                      controller: textController,
                      decoration: InputDecoration(hintText: contentController),
                    ))
              : Text(contentController),
          actions: <Widget>[
            TextButton(
              child: Text(cancelButtonText),
              onPressed: () {
                Navigator.of(context).pop();
                textController.clear();
              },
            ),
            TextButton(
              child: Text(okButtonText),
              onPressed: () {
                String? textInput =
                    isText || isNumber ? textController.text.trim() : null;
                if (textController.text.trim() == "" && isText) {
                  ErrorHandler.showError(context, 'Input cannot be empty');
                  return;
                }
                if (isNumber) {
                  try {
                    int.parse(textInput!);
                  } catch (e) {
                    ErrorHandler.showError(context, 'Input must be a number');
                    return;
                  }
                }
                if (isNumber && int.parse(textInput!) <= 0) {
                  ErrorHandler.showError(
                      context, 'Input must be greater than 0');
                  return;
                }
                onOkPressed(textInput: textInput, workout: workoutName);
                Navigator.of(context).pop();
                textController.clear();
              },
            ),
          ],
        );
      },
    );
  }
}
