import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// CPR ekranının sesleri: uyarı bipleri ve kompresyon metronomu.
class CprSounds {
  final _alertPlayer = AudioPlayer();
  final _metronomePlayer = AudioPlayer();
  bool _metronomeOn = false;

  bool get metronomeOn => _metronomeOn;

  /// Güçlü uyarı: üç bip ve titreşim.
  Future<void> alarm() async {
    HapticFeedback.vibrate();
    await _play(_alertPlayer, 'sounds/alarm.wav');
  }

  /// Hafif bilgi uyarısı: tek bip.
  Future<void> chime() async {
    HapticFeedback.mediumImpact();
    await _play(_alertPlayer, 'sounds/chime.wav');
  }

  /// Dakikada 110 vuruşluk metronom (önerilen aralık 100–120/dk).
  Future<void> setMetronome(bool on) async {
    _metronomeOn = on;
    try {
      if (on) {
        await _metronomePlayer.setReleaseMode(ReleaseMode.loop);
        await _metronomePlayer.play(AssetSource('sounds/metronome_110.wav'));
      } else {
        await _metronomePlayer.stop();
      }
    } catch (_) {
      // Ses çalınamazsa zamanlayıcı çalışmaya devam etmeli.
    }
  }

  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {
      // Ses çalınamazsa zamanlayıcı çalışmaya devam etmeli.
    }
  }

  void dispose() {
    _alertPlayer.dispose();
    _metronomePlayer.dispose();
  }
}
