import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/sms_data.dart';
import '../models/sms_message.dart';

enum Sensitivity { relaxed, balanced, strict }

class GuardState extends ChangeNotifier {
  GuardState() {
    _timer = Timer.periodic(const Duration(seconds: 40), (_) {
      if (monitoring) _receive();
    });
  }

  static const _baseScanned = 1240;
  static const _baseBlocked = 6;
  static const _baseSenders = 3;

  // ---- settings ----
  bool monitoring = true;
  bool autoBlock = true;
  bool linkScanning = true;
  bool alerts = true;
  bool shareIntel = false;
  Sensitivity sensitivity = Sensitivity.balanced;

  // ---- data ----
  List<SmsMessage> _messages = initialMessages();
  final Set<String> _blocked = {};
  int _nextId = 100;
  int _poolIndex = 0;
  int _extraScanned = 0;

  // ---- scan ----
  bool scanning = false;
  double scanProgress = 0;
  DateTime? lastScan;

  Timer? _timer;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ---- getters ----
  List<SmsMessage> get messages => List.unmodifiable(_messages);
  int get messagesScanned => _baseScanned + _extraScanned;
  int get blockedToday =>
      _baseBlocked + _messages.where((m) => m.risk >= 60).length;
  int get highRisk => _messages.where((m) => m.risk >= 80).length;
  int get totalThreats => _messages.where((m) => m.isThreat).length;

  List<String> get blockedSenders {
    final set = <String>{..._blocked};
    if (autoBlock) {
      set.addAll(_messages.where((m) => m.risk >= 60).map((m) => m.sender));
    }
    return set.toList()..sort();
  }

  int get blockedSenderCount => _baseSenders + blockedSenders.length;
  bool isBlocked(String sender) => blockedSenders.contains(sender);
  bool isManuallyBlocked(String sender) => _blocked.contains(sender);

  int get protectionScore {
    var s = monitoring ? 98 : 52;
    if (!autoBlock) s -= 6;
    if (!linkScanning) s -= 5;
    if (!alerts) s -= 2;
    return s < 0 ? 0 : s;
  }

  List<SmsMessage> get activity =>
      _messages.where((m) => m.isThreat).take(6).toList();

  List<int> get dailyTrend => [1, 0, 2, 5, 3, math.max(0, blockedToday - 11)];

  List<int> get weeklyTrend => [14, 19, 11, 23, 17, 26, blockedToday];

  List<String> get weekLabels {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        names[now.subtract(Duration(days: i)).weekday - 1],
    ];
  }

  List<MapEntry<ThreatCategory, int>> get categoryCounts {
    final map = <ThreatCategory, int>{};
    for (final m in _messages) {
      if (m.category == ThreatCategory.safe) continue;
      map[m.category] = (map[m.category] ?? 0) + 1;
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  // ---- actions ----
  void update(VoidCallback change) {
    change();
    _notify();
  }

  void blockSender(String sender) {
    _blocked.add(sender);
    _notify();
  }

  void unblockSender(String sender) {
    _blocked.remove(sender);
    _notify();
  }

  void _receive() {
    final msg = incomingMessage(_nextId++, _poolIndex++);
    _messages = [msg, ..._messages];
    if (_messages.length > 40) _messages = _messages.sublist(0, 40);
    _extraScanned++;
    _notify();
  }

  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (monitoring) _receive();
  }

  Future<void> runScan() async {
    if (scanning) return;
    scanning = true;
    scanProgress = 0;
    _notify();
    for (var i = 1; i <= 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 130));
      scanProgress = i / 20;
      _notify();
    }
    scanning = false;
    lastScan = DateTime.now();
    _extraScanned += 24;
    _notify();
  }

  void reset() {
    _messages = initialMessages();
    _blocked.clear();
    _extraScanned = 0;
    _poolIndex = 0;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
