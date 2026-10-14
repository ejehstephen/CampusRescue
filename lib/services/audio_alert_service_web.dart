import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'audio_alert_service.dart';

class WebAudioAlertService implements AudioAlertService {
  Timer? _repeatTimer;
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  void playEmergencyAlarm() {
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          try {
            var AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (!AudioCtx) return;
            if (window._sosActiveAudioCtx) {
              try { window._sosActiveAudioCtx.close(); } catch(e) {}
            }
            var ctx = new AudioCtx();
            window._sosActiveAudioCtx = ctx;
            if (ctx.state === 'suspended') {
              ctx.resume();
            }
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = "sawtooth";
            var now = ctx.currentTime;
            osc.frequency.setValueAtTime(880, now);
            osc.frequency.setValueAtTime(659.25, now + 0.15);
            osc.frequency.setValueAtTime(880, now + 0.30);
            osc.frequency.setValueAtTime(659.25, now + 0.45);
            osc.frequency.setValueAtTime(880, now + 0.60);
            gain.gain.setValueAtTime(0.25, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.85);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + 0.85);
          } catch(e) {}
        })();
        '''
      ]);
    } catch (_) {}
  }

  @override
  void startRepeatingAlarm() {
    if (_isPlaying) return;
    _isPlaying = true;
    playEmergencyAlarm();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (_isPlaying) {
        playEmergencyAlarm();
      } else {
        _repeatTimer?.cancel();
        _repeatTimer = null;
      }
    });
  }

  @override
  void stopAlarm() {
    _isPlaying = false;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          try {
            if (window._sosActiveAudioCtx) {
              window._sosActiveAudioCtx.close();
              window._sosActiveAudioCtx = null;
            }
          } catch(e) {}
        })();
        '''
      ]);
    } catch (_) {}
  }
}

final WebAudioAlertService _webAudioAlertServiceInstance = WebAudioAlertService();
AudioAlertService getAudioAlertService() => _webAudioAlertServiceInstance;
