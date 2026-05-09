import "dart:async";

class MarketFetchQueueProgress {
  const MarketFetchQueueProgress({required this.totalCount, required this.completedCount, required this.running, required this.currentLabel});

  final int totalCount;
  final int completedCount;
  final bool running;
  final String? currentLabel;

  bool get isActive => running || completedCount < totalCount;
}

class MarketFetchQueueTask {
  const MarketFetchQueueTask({required this.cacheKey, required this.label, required this.operation});

  final String cacheKey;
  final String label;
  final Future<void> Function() operation;
}

class MarketFetchQueue {
  final List<String> _pendingKeys = <String>[];
  final Map<String, MarketFetchQueueTask> _pendingByKey = <String, MarketFetchQueueTask>{};
  int _completedCount = 0;
  bool _running = false;
  String? _runningKey;
  String? _currentLabel;
  DateTime? _lastStart;
  StreamController<MarketFetchQueueProgress>? _controller;

  Stream<MarketFetchQueueProgress> progressStream() {
    _controller ??= StreamController<MarketFetchQueueProgress>.broadcast();
    _emit();
    return _controller!.stream;
  }

  MarketFetchQueueProgress get progress => MarketFetchQueueProgress(
        totalCount: _completedCount + _pendingByKey.length + (_running ? 1 : 0),
        completedCount: _completedCount,
        running: _running,
        currentLabel: _currentLabel,
      );

  MarketFetchQueueProgress clearPending({bool resetCompletedCount = false}) {
    _pendingKeys.clear();
    _pendingByKey.clear();
    if (resetCompletedCount) {
      _completedCount = 0;
    }
    _emit();
    return progress;
  }

  MarketFetchQueueProgress enqueue(MarketFetchQueueTask task) {
    final String key = task.cacheKey.trim();
    if (key.isEmpty || _pendingByKey.containsKey(key) || (_running && _runningKey == key)) {
      return progress;
    }
    _pendingKeys.add(key);
    _pendingByKey[key] = MarketFetchQueueTask(cacheKey: key, label: task.label, operation: task.operation);
    _pump();
    _emit();
    return progress;
  }

  Future<void> _pump() async {
    if (_running) {
      return;
    }
    while (_pendingKeys.isNotEmpty) {
      final String key = _pendingKeys.removeAt(0);
      final MarketFetchQueueTask? task = _pendingByKey.remove(key);
      if (task == null) {
        continue;
      }

      final DateTime now = DateTime.now();
      if (_lastStart != null) {
        final int elapsed = now.difference(_lastStart!).inMilliseconds;
        if (elapsed < 1000) {
          await Future<void>.delayed(Duration(milliseconds: 1000 - elapsed));
        }
      }

      _running = true;
      _runningKey = key;
      _currentLabel = task.label;
      _lastStart = DateTime.now();
      _emit();
      try {
        await task.operation();
      } catch (_) {}
      _completedCount += 1;
      _running = false;
      _runningKey = null;
      _currentLabel = null;
      _emit();
    }
  }

  void _emit() {
    _controller?.add(progress);
  }
}
