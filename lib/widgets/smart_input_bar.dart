import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/task_entry.dart';
import '../services/ai_history_service.dart';
import '../services/command_parser_service.dart';
import '../services/ocr_service.dart';
import '../services/speech_service.dart';

class SmartInputBar extends StatefulWidget {
  final int nextId;
  final String historyKey;
  final Future<void> Function(List<TaskEntry>) onEntriesCreated;
  final VoidCallback? onHistoryChanged;

  const SmartInputBar({
    super.key,
    required this.nextId,
    required this.historyKey,
    required this.onEntriesCreated,
    this.onHistoryChanged,
  });

  @override
  State<SmartInputBar> createState() => _SmartInputBarState();
}

class _SmartInputBarState extends State<SmartInputBar> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final SpeechService _speechService = SpeechService();

  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _speechService.cancelListening();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitText({String source = "text"}) async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    final task = CommandParserService.parse(
      id: widget.nextId,
      input: text,
      source: source,
    );

    await AiHistoryService.add(
      historyKey: widget.historyKey,
      userPrompt: text,
      aiResponse: "Added task: ${task.title}",
    );
    widget.onHistoryChanged?.call();

    await widget.onEntriesCreated([task]);
    _controller.clear();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    setState(() => _isProcessing = true);

    try {
      final image = await _imagePicker.pickImage(source: source);
      if (image == null) {
        return;
      }

      final extractedText = await OcrService.readTextFromImage(image.path);
      final tasks = CommandParserService.parseMany(
        startId: widget.nextId,
        input: extractedText,
        source: "image",
      );

      if (tasks.isNotEmpty) {
        await AiHistoryService.add(
          historyKey: widget.historyKey,
          userPrompt: extractedText,
          aiResponse:
              "Detected and added ${tasks.length} scheduled task${tasks.length == 1 ? "" : "s"} from the image.",
        );
        widget.onHistoryChanged?.call();
        await widget.onEntriesCreated(tasks);
      } else {
        await AiHistoryService.add(
          historyKey: widget.historyKey,
          userPrompt: extractedText.isEmpty ? "Uploaded image" : extractedText,
          aiResponse:
              "I could not find a clear task with a date and time in this image.",
        );
        widget.onHistoryChanged?.call();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      await _submitText(source: "voice");
      return;
    }

    final available = await _speechService.startListening(
      onTextChanged: (text) {
        if (!mounted) {
          return;
        }
        setState(() {
          _controller.text = text;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );

    if (!available || !mounted) {
      return;
    }

    setState(() => _isListening = true);
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1B1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text("Upload from gallery"),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text("Take a photo"),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF303030)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _isProcessing ? null : _showImageOptions,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Add a task...",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _submitText(),
                ),
              ),
              IconButton(
                onPressed: _toggleVoice,
                icon: Icon(
                  _isListening ? Icons.stop_circle_outlined : Icons.mic_none,
                  color: _isListening ? const Color(0xFFFF6B6B) : null,
                ),
              ),
              IconButton(
                onPressed: _submitText,
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
