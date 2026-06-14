import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../models/task_entry.dart';
import '../services/ai_history_service.dart';
import '../services/ai_planner_service.dart';
import '../services/command_parser_service.dart';
import '../services/ocr_service.dart';
import '../services/speech_service.dart';

class SmartInputBar extends StatefulWidget {
  final int nextId;
  final String historyKey;
  final bool enableStudentAi;
  final Future<void> Function(List<TaskEntry>) onEntriesCreated;
  final VoidCallback? onHistoryChanged;

  const SmartInputBar({
    super.key,
    required this.nextId,
    required this.historyKey,
    this.enableStudentAi = false,
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

  Future<void> _pickImage(
    ImageSource source, {
    bool analyzeExamTimetable = false,
  }) async {
    Navigator.pop(context);
    setState(() => _isProcessing = true);

    try {
      final image = await _imagePicker.pickImage(source: source);
      if (image == null) {
        return;
      }

      final extractedText = await OcrService.readTextFromImage(image.path);
      final shouldAnalyze = analyzeExamTimetable || widget.enableStudentAi;
      var tasks = shouldAnalyze
          ? AiPlannerService.analyzeExamTimetable(
              startId: widget.nextId,
              text: extractedText,
            )
          : <TaskEntry>[];

      if (tasks.isEmpty) {
        tasks = CommandParserService.parseMany(
          startId: widget.nextId,
          input: extractedText,
          source: "image",
        );
      }

      if (tasks.isNotEmpty) {
        await AiHistoryService.add(
          historyKey: widget.historyKey,
          userPrompt: extractedText,
          aiResponse: shouldAnalyze
              ? "Analyzed the image and added ${tasks.length} scheduled task${tasks.length == 1 ? "" : "s"}."
              : "Detected and added ${tasks.length} scheduled task${tasks.length == 1 ? "" : "s"} from the image.",
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

  Future<void> _createStudyPlanFromNotes() async {
    Navigator.pop(context);

    final planRequest = await _showStudyPlanDialog();
    if (planRequest == null) {
      return;
    }

    final notes = planRequest.notes.trim();
    if (notes.isEmpty) {
      await AiHistoryService.add(
        historyKey: widget.historyKey,
        userPrompt: "Create a study plan",
        aiResponse: "Add your notes first so I can create a study plan.",
      );
      widget.onHistoryChanged?.call();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final tasks = AiPlannerService.createStudyPlan(
        startId: widget.nextId,
        notes: notes,
        days: planRequest.days,
      );

      if (tasks.isEmpty) {
        await AiHistoryService.add(
          historyKey: widget.historyKey,
          userPrompt: notes,
          aiResponse: "I could not find enough notes to create a study plan.",
        );
        widget.onHistoryChanged?.call();
        return;
      }

      await AiHistoryService.add(
        historyKey: widget.historyKey,
        userPrompt: notes,
        aiResponse:
            "Created a ${planRequest.days}-day study plan and added it to your calendar.",
      );
      widget.onHistoryChanged?.call();
      await widget.onEntriesCreated(tasks);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<_StudyPlanRequest?> _showStudyPlanDialog() async {
    return showDialog<_StudyPlanRequest>(
      context: context,
      builder: (context) => _StudyPlanDialog(initialNotes: _controller.text),
    );
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
                if (widget.enableStudentAi) ...[
                  ListTile(
                    leading: const Icon(Icons.view_timeline_outlined),
                    title: const Text("Create study plan"),
                    subtitle: const Text("Add notes and choose timeline"),
                    onTap: _createStudyPlanFromNotes,
                  ),
                  const Divider(height: 18),
                ],
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

class _StudyPlanRequest {
  final String notes;
  final int days;

  const _StudyPlanRequest({required this.notes, required this.days});
}

class _StudyPlanDialog extends StatefulWidget {
  final String initialNotes;

  const _StudyPlanDialog({required this.initialNotes});

  @override
  State<_StudyPlanDialog> createState() => _StudyPlanDialogState();
}

class _StudyPlanDialogState extends State<_StudyPlanDialog> {
  late final TextEditingController _notesController;
  late final TextEditingController _daysController;
  String? _fileMessage;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes.trim());
    _daysController = TextEditingController(text: "5");
  }

  @override
  void dispose() {
    _notesController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        "Create study plan",
        style: TextStyle(
          color: Color(0xFF151515),
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _notesController,
              minLines: 4,
              maxLines: 10,
              style: const TextStyle(color: Color(0xFF151515)),
              decoration: _dialogInputDecoration("Paste your notes here"),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadNotesFile,
              icon: const Icon(Icons.attach_file),
              label: const Text("Add file/PDF"),
            ),
            if (_fileMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _fileMessage!,
                style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFF151515)),
              decoration: _dialogInputDecoration("How many days?"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final days = int.tryParse(_daysController.text.trim()) ?? 5;
            Navigator.pop(
              context,
              _StudyPlanRequest(
                notes: _notesController.text,
                days: days.clamp(1, 60),
              ),
            );
          },
          child: const Text("Create"),
        ),
      ],
    );
  }

  Future<void> _loadNotesFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["txt", "md", "pdf"],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final extension = file.extension?.toLowerCase();

    if (extension == "pdf") {
      setState(() {
        _fileMessage =
            "PDF selected. Paste the PDF text here for now, then create the plan.";
      });
      return;
    }

    final bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _fileMessage = "Could not read ${file.name}. Try txt/md or paste notes.";
      });
      return;
    }

    setState(() {
      _notesController.text = String.fromCharCodes(bytes);
      _notesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _notesController.text.length),
      );
      _fileMessage = "Loaded ${file.name}.";
    });
  }

  InputDecoration _dialogInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF777777)),
      filled: true,
      fillColor: const Color(0xFFF7F2F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}
