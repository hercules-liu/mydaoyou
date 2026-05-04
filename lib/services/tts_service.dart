import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused }

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final _stateController = StreamController<TtsState>.broadcast();
  
  TtsState _state = TtsState.stopped;
  TtsState get state => _state;
  Stream<TtsState> get stateStream => _stateController.stream;

  Future<void> init() async {
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _state = TtsState.playing;
      _stateController.add(_state);
    });

    _flutterTts.setCompletionHandler(() {
      _state = TtsState.stopped;
      _stateController.add(_state);
    });

    _flutterTts.setErrorHandler((msg) {
      _state = TtsState.stopped;
      _stateController.add(_state);
    });

    _flutterTts.setCancelHandler(() {
      _state = TtsState.stopped;
      _stateController.add(_state);
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _state = TtsState.stopped;
    _stateController.add(_state);
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _state = TtsState.paused;
    _stateController.add(_state);
  }

  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  void dispose() {
    _flutterTts.stop();
    _stateController.close();
  }
}