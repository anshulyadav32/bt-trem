import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class AudioService {
  final AudioPlayer _keyPlayer = AudioPlayer();
  final AudioPlayer _messagePlayer = AudioPlayer();
  bool _soundEnabled = false;
  
  AudioService() {
    _init();
  }
  
  Future<void> _init() async {
    try {
      // Load sound assets
      // Note: These assets need to be added to the project
      final keyData = await rootBundle.load('assets/sounds/key_press.mp3');
      final messageData = await rootBundle.load('assets/sounds/message_received.mp3');
      
      await _keyPlayer.setAudioSource(
        AudioSource.uri(Uri.parse('data:audio/mp3;base64,${base64.encode(keyData.buffer.asUint8List())}')),
      );
      
      await _messagePlayer.setAudioSource(
        AudioSource.uri(Uri.parse('data:audio/mp3;base64,${base64.encode(messageData.buffer.asUint8List())}')),
      );
    } catch (e) {
      print('Error initializing audio: $e');
      // Silently fail - sounds aren't critical for app function
    }
  }
  
  void playKeySound() {
    if (_soundEnabled) {
      try {
        _keyPlayer.seek(Duration.zero);
        _keyPlayer.play();
      } catch (e) {
        print('Error playing key sound: $e');
      }
    }
  }
  
  void playMessageSound() {
    if (_soundEnabled) {
      try {
        _messagePlayer.seek(Duration.zero);
        _messagePlayer.play();
      } catch (e) {
        print('Error playing message sound: $e');
      }
    }
  }
  
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }
  
  void setSound(bool enabled) {
    _soundEnabled = enabled;
  }
  
  bool get isSoundEnabled => _soundEnabled;
}
