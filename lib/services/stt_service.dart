import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _speechToText = SpeechToText();
  final _resultController = StreamController<String>.broadcast();
  final _isListeningController = StreamController<bool>.broadcast();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Stream<String> get onResult => _resultController.stream;
  Stream<bool> get isListeningStream => _isListeningController.stream;

  Future<bool> init() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return _isInitialized;
  }

  Future<bool> startListening() async {
    if (!_isInitialized) {
      final ready = await init();
      if (!ready) return false;
    }

    _isListeningController.add(true);
    await _speechToText.listen(
      onResult: (result) {
        _resultController.add(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.dictation,
    );
    return true;
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListeningController.add(false);
  }

  void dispose() {
    _speechToText.cancel();
    _resultController.close();
    _isListeningController.close();
  }
}