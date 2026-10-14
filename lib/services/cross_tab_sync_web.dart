import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

typedef CrossTabCallback = void Function(Map<String, dynamic> data);

class CrossTabSync {
  static final CrossTabSync instance = CrossTabSync._();
  CrossTabSync._();

  html.BroadcastChannel? _channel;
  StreamSubscription? _subscription;

  void init(CrossTabCallback onMessage) {
    try {
      _channel = html.BroadcastChannel('campusrescue_cross_tab_sync');
      _subscription = _channel?.onMessage.listen((event) {
        try {
          final raw = event.data;
          if (raw is String) {
            final decoded = jsonDecode(raw) as Map<String, dynamic>;
            onMessage(decoded);
          } else if (raw is Map) {
            onMessage(Map<String, dynamic>.from(raw));
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void broadcast(Map<String, dynamic> data) {
    try {
      _channel?.postMessage(jsonEncode(data));
    } catch (_) {}
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.close();
  }
}
