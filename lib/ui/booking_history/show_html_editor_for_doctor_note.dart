import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:html_editor_enhanced/html_editor.dart';

/// A simplified HTML editor in a bottom sheet with live preview and save functionality.
void showHtmlEditorForDoctorNote({
  required BuildContext context,
  required String initialHtml,
  required Future<void> Function(String) onSave,
  String title = "Doctor's Note",
}) {
  showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(40),
          )),
      context: Get.context!,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: HtmlEditorForDoctorNote(
              initialHtml: initialHtml,
              onSave: onSave,
              title: title,
            ),
          ),
        );
      });
}

class HtmlEditorForDoctorNote extends StatefulWidget {
  final String initialHtml;
  final Future<void> Function(String) onSave;
  final String title;

  const HtmlEditorForDoctorNote({
    super.key,
    required this.initialHtml,
    required this.onSave,
    required this.title,
  });

  @override
  State<HtmlEditorForDoctorNote> createState() => _HtmlEditorForDoctorNoteState();
}

class _HtmlEditorForDoctorNoteState extends State<HtmlEditorForDoctorNote> {
  late final HtmlEditorController controller;
  late String htmlContent;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = HtmlEditorController();
    htmlContent = widget.initialHtml;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Editor section
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: HtmlEditor(
                controller: controller,
                htmlEditorOptions: HtmlEditorOptions(
                  initialText: htmlContent,
                  hint: "Write your notes here...",
                ),
                htmlToolbarOptions: const HtmlToolbarOptions(
                  toolbarPosition: ToolbarPosition.aboveEditor,
                  defaultToolbarButtons: [
                    FontButtons(clearAll: false),
                    ColorButtons(),
                    ListButtons(listStyles: false),
                    ParagraphButtons(
                        textDirection: false, lineHeight: false, caseConverter: false),
                    InsertButtons(
                        video: false,
                        audio: false,
                        table: false,
                        hr: false,
                        otherFile: false),
                  ],
                ),
                callbacks: Callbacks(
                  onChangeContent: (String? changed) {
                    setState(() => htmlContent = changed ?? "");
                  },
                ),
              ),
            ),

            const Divider(thickness: 1),

            // Preview section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Spacer(),
                  // Save button (moved to top-right of preview)
                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      setState(() => isLoading = true);
                      try {
                        await widget.onSave(await controller.getText());
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: ${e.toString()}")),
                        );
                      } finally {
                        if (context.mounted) setState(() => isLoading = false);
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Save"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
