import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static Future<String> readTextFromImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await recognizer.close();
    }
  }
}
