import 'dart:async';

/// Broadcasts "session expired" from the network layer to the presentation
/// layer without the network layer depending on any feature.
final class SessionEvents {
  final StreamController<void> _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void notifyExpired() {
    if (!_expired.isClosed) _expired.add(null);
  }

  Future<void> dispose() => _expired.close();
}
