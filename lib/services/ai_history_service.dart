class AiHistoryEntry {
  final String userPrompt;
  final String aiResponse;
  final DateTime timestamp;

  const AiHistoryEntry({
    required this.userPrompt,
    required this.aiResponse,
    required this.timestamp,
  });
}

class AiHistoryService {
  static final Map<String, List<AiHistoryEntry>> _entriesByMode = {};

  static List<AiHistoryEntry> entriesFor(String historyKey) {
    return List.unmodifiable(_entriesByMode[historyKey] ?? const []);
  }

  static Future<void> add({
    required String historyKey,
    required String userPrompt,
    required String aiResponse,
  }) async {
    if (userPrompt.trim().isEmpty || aiResponse.trim().isEmpty) {
      return;
    }

    final entries = _entriesByMode.putIfAbsent(historyKey, () => []);

    entries.add(
      AiHistoryEntry(
        userPrompt: userPrompt.trim(),
        aiResponse: aiResponse.trim(),
        timestamp: DateTime.now(),
      ),
    );
  }
}
