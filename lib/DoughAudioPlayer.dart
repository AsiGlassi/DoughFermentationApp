import 'package:audioplayers/audioplayers.dart';


class DoughAudioPlayer {
  final AudioPlayer player = AudioPlayer();
  // Configure audio context to ensure output through speaker
  // This is important for both Android and iOS
  final audioContext = const AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: [
        AVAudioSessionOptions.mixWithOthers, // Allows mixing with other audio
        AVAudioSessionOptions.defaultToSpeaker, // Ensures speaker output
        AVAudioSessionOptions.allowBluetooth,
        // AVAudioSessionOptions.duckOthers, // Optional: lower other audio when playing
      ],
    ),
    android: AudioContextAndroid(
      isSpeakerphoneOn: true, // Crucial for Android to force speaker
      contentType: AndroidContentType.sonification, // For alerts/notifications
      usageType: AndroidUsageType.alarm, // Best for loud, attention-grabbing sounds
      audioFocus: AndroidAudioFocus.gainTransientExclusive, // Request exclusive focus
    ),
  );

  DoughAudioPlayer() {
    player.setVolume(1); // 100% volume
    player.setAudioContext(audioContext);
  }

  Future<void> PlaySound(String filename) async {
    String path = "../resources/sounds/$filename.mp3";
    await player.play(AssetSource(path));
  }
}