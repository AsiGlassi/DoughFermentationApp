import 'package:audioplayers/audioplayers.dart';


class DoughAudioPlayer {
  final AudioPlayer player = AudioPlayer();

  DoughAudioPlayer() {
    player.setVolume(0.5); // 50% volume
  }

  Future<void> PlaySound(String filename) async {
    String path = "../resources/sounds/$filename.mp3";
    await player.play(AssetSource(path));
  }
}