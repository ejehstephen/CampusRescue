import 'audio_alert_service_stub.dart'
    if (dart.library.html) 'audio_alert_service_web.dart';

abstract class AudioAlertService {
  static final AudioAlertService instance = getAudioAlertService();

  void playEmergencyAlarm();
  void startRepeatingAlarm();
  void stopAlarm();
  bool get isPlaying;
}
