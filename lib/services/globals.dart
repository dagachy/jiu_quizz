import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'services.dart';

/// Static global staet. Immutable services that do not care about build context.
class Global {
  // App Data
  static final String title = 'Fireship';

  // Services
  static final FirebaseAnalytics analytics = FirebaseAnalytics();

  // Data Models
  static final Map models = {
    Topic: (data) => Topic.fromMap(data),
    Quiz: (data) => Quiz.fromMap(data),
    Report: (data) => Report.fromMap(data),
  };

  // Firestore References for Writes
  static final Collection<Topic> topicsRef = Collection<Topic>(path: 'topics');
  static final UserData<Report> reportRef =
      UserData<Report>(collection: 'reports');
  static final AudioCache audioCache = AudioCache();
  static AudioPlayer audioPlayer;

  static void loopSound(String sound) async {
    audioPlayer = await audioCache.loop(sound);
  }

  static void stopLoopSound() {
    audioPlayer?.stop();
  }
}
