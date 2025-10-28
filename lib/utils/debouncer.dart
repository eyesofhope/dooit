import 'dart:async';

/// Lightweight debouncer used to throttle high-frequency callbacks such as
/// search input changes. The debouncer cancels the outstanding callback when a
/// new value arrives and only invokes the callback after the configured delay
/// has elapsed without additional calls. This keeps provider notifications in
/// check while keeping the implementation dependency-free.
class Debouncer {
  Debouncer({Duration delay = const Duration(milliseconds: 300)})
      : _delay = delay;

  final Duration _delay;
  Timer? _timer;

  bool get isActive => _timer?.isActive ?? false;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(_delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
