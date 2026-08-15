import 'dart:async';

import 'package:ocupa2/core/session/session_event.dart';

class SessionEventBus {
  final StreamController<SessionEvent> _controller =
      StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get events => _controller.stream;

  void notifySessionExpired() {
    if (_controller.isClosed) {
      return;
    }

    _controller.add(SessionEvent.expired);
  }

  void dispose() {
    _controller.close();
  }
}
