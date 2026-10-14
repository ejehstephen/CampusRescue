import 'audio_alert_service.dart';

class StubAudioAlertService implements AudioAlertService {
  @override
  void playEmergencyAlarm() {}

  @override
  void startRepeatingAlarm() {}

  @override
  void stopAlarm() {}

  @override
  bool get isPlaying => false;
}

final StubAudioAlertService _stubAudioAlertServiceInstance = StubAudioAlertService();
AudioAlertService getAudioAlertService() => _stubAudioAlertServiceInstance;
