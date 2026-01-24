import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import '../../Utils/tools.dart';

class FeedbackDialog {
  static Future<void> show(BuildContext context) async {
    final TextEditingController _controller = TextEditingController();
    final TextEditingController _nameController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            // Get theme colors
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            
            return AlertDialog(
              backgroundColor: theme.canvasColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "We value your feedback 💬",
                style: Tools.h2(context).copyWith(color: colorScheme.onSurface),
              ),
              content: isLoading
                  ? SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : Column(
                      spacing: 10,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _controller,
                          maxLines: 5,
                          style: Tools.h3(context).copyWith(color: colorScheme.inverseSurface),

                          decoration: InputDecoration(
                            hintText: "Type your feedback here...",
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _nameController,
                          maxLines: 1,
                          style: Tools.h3(context).copyWith(color: colorScheme.inverseSurface),
                          
                          decoration: InputDecoration(
                            hintText: "Your Name",
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              actions: isLoading
                  ? []
                  : [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        onPressed: () async {
                          final feedback = _controller.text.trim();
                          if (feedback.isNotEmpty) {
                            setState(() => isLoading = true);

                            final url = Uri.parse(
                              "https://script.google.com/macros/s/AKfycbz_IkJMPNTqbVKf8PBSH0JlGzce-5FiGY5xlXSlxPfrdJd4Qh_P7_rk4dv5FUGZgHXUJw/exec",
                            );
                            final name = _nameController.text.trim() == ''
                                ? 'PDF APP'
                                : "${_nameController.text.trim()} (PDF APP)";

                            try {
                              final response = await http.post(
                                url,
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode({
                                  "name": name,
                                  "email": "user@example.com",
                                  "message": feedback,
                                }),
                              );

                              Navigator.pop(context);

                              if (response.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Thanks for your feedback!")),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Thanks for your feedback!")),
                                );
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          }
                        },
                        child: Text(
                          "Submit",
                          style: Tools.h3(context).copyWith(
                            color: colorScheme.onPrimary,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }
}