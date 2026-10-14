typedef CrossTabCallback = void Function(Map<String, dynamic> data);

class CrossTabSync {
  static final CrossTabSync instance = CrossTabSync._();
  CrossTabSync._();

  void init(CrossTabCallback onMessage) {}
  void broadcast(Map<String, dynamic> data) {}
  void dispose() {}
}
