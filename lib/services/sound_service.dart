import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._privateConstructor();
  static final SoundService _instance = SoundService._privateConstructor();
  factory SoundService() => _instance;
  static SoundService get instance => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playCompletionSound() async {
    try {
      if (kDebugMode) {
        print('Playing completion sound...');
      }
      await _audioPlayer.stop(); // Stop any currently playing sound
      await _audioPlayer.play(AssetSource('sound/Notification.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound: $e');
      }
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
