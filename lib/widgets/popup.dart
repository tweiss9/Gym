import 'package:flutter/material.dart';
import '../widgets/show_error.dart';

class Popup {
  final String title;
  final String contentController;
  final Function({String? textInput}) onOkPressed;
  final String okButtonText;
  final String cancelButtonText;
  final bool isNumber;
  final bool isText;
  final bool isWarning;
  final TextEditingController textController = TextEditingController();

  Popup(
    this.isNumber,
    this.isText,
    this.isWarning, {
    required this.title,
    required this.contentController,
    required this.onOkPressed,
    required this.okButtonText,
    required this.cancelButtonText,
  });

  void show(BuildContext context) {
    //final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
              child: Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          )),
          content: isNumber || isText
              ? (isNumber
                  ? TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: contentController,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      cursorColor: Colors.black,
                    )
                  : TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: contentController,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      cursorColor: Colors.black,
                    ))
              : Text(contentController,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center),
          actions: <Widget>[
            Column(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          String? textInput = isText || isNumber
                              ? textController.text.trim()
                              : null;
                          if (textController.text.trim() == "" && isText) {
                            ErrorHandler.showError(
                                context, 'Input cannot be empty');
                            return;
                          }
                          if (isNumber) {
                            try {
                              int.parse(textInput!);
                            } catch (e) {
                              ErrorHandler.showError(
                                  context, 'Input must be a number');
                              return;
                            }
                          }
                          if (isNumber && int.parse(textInput!) <= 0) {
                            ErrorHandler.showError(
                                context, 'Input must be greater than 0');
                            return;
                          }
                          onOkPressed(textInput: textInput);
                          Navigator.of(context).pop();
                          textController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              isWarning ? Colors.red : Colors.green,
                          fixedSize: const Size(300, 40),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(okButtonText,
                            style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          textController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.grey,
                          fixedSize: const Size(300, 40),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(cancelButtonText,
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
