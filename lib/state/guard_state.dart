import 'package:flutter/foundation.dart';

import '../data/sms_data.dart';
import '../models/protection_status.dart';
import '../models/sms_message.dart';

export '../models/protection_status.dart';

enum Sensitivity { relaxed, balanced, strict }

/// Backend hook: analyze the device's messages. The backend implementation
/// reports progress with [GuardState.setScanProgress] and delivers results
/// with [GuardState.setDeviceMessages]. Null until the backend is connected.
typedef ScanHandler = Future<void> Function(GuardState state);

/// Backend hook: ask Android for SMS access and return the outcome.
typedef PermissionHandler = Future<SmsPermission> Function();

/// Frontend state for ThreatGuard AI.
///
/// There are three clearly separate groups:
///  * **Preferences**: what the user switched on in Settings (saved intent).
///  * **Real state**: permission, scan progress, messages from the device.
///    Only the backend sets these (see the "backend entry points" below).
///  * **Demo state**: sample messages, shown only while [demoMode] is on.
///
/// Nothing here pretends a feature works. Status text is derived from the
/// real-state fields only.
class GuardState extends ChangeNotifier {
  // ---------------------------------------------------------- preferences
  // These record what the user wants. The features behind them are provided
  // by the backend, so they do not change the protection status.
  bool monitoring = true;
  bool autoBlock = true;
  bool linkScanning = true;
  bool alerts = true;
  bool shareIntel = false;
  Sensitivity sensitivity = Sensitivity.balanced;

  // ----------------------------------------------------------- real state
  SmsPermission smsPermission = SmsPermission.notGranted;
  bool engineConnected = false; // AI detection engine reachable
  bool monitoringRunning = false; // real-time monitoring actually running
  bool blockingAvailable = false; // real blocking exists on the device

  /// Null until a real calculation exists (shown as a neutral placeholder).
  int? protectionScore;

  ScanHandler? scanHandler;
  PermissionHandler? permissionHandler;

  List<SmsMessage> _deviceMessages = const [];

  // ----------------------------------------------------------- demo state
  bool demoMode = false;
  List<SmsMessage> _demoMessages = const [];

  // ----------------------------------------------------------------- scan
  bool scanning = false;
  double scanProgress = 0; // 0 – 1
  DateTime? lastScan;
  String? scanError;

  // ---------------------------------------------------------- local flags
  final Set<String> _blocked = {};
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // -------------------------------------------------------------- getters
  /// The message list currently shown: demo samples in demo mode, otherwise
  /// the messages delivered by the backend (empty until then).
  List<SmsMessage> get messages =>
      List.unmodifiable(demoMode ? _demoMessages : _deviceMessages);

  bool get hasMessages => messages.isNotEmpty;

  // All statistics are derived from [messages], so they always agree.
  int get messagesScanned => messages.length;
  int get threatCount => messages.where((m) => m.isThreat).length;
  int get totalThreats => threatCount;
  int get safeCount => messagesScanned - threatCount;
  int get highRisk => messages.where((m) => m.risk >= 80).length;

  bool get canScan =>
      !demoMode &&
      smsPermission == SmsPermission.granted &&
      scanHandler != null;

  ProtectionStatus get status {
    if (smsPermission == SmsPermission.unsupported) {
      return ProtectionStatus.notSupported;
    }
    if (smsPermission == SmsPermission.notGranted) {
      return ProtectionStatus.permissionRequired;
    }
    if (scanning) return ProtectionStatus.scanning;
    if (monitoringRunning) return ProtectionStatus.monitoringActive;
    if (lastScan != null) return ProtectionStatus.lastScanCompleted;
    return ProtectionStatus.readyToScan;
  }

  /// Senders blocked by the user. Automatic blocking is only included when
  /// real blocking exists ([blockingAvailable]).
  List<String> get blockedSenders {
    final set = <String>{..._blocked};
    if (blockingAvailable && autoBlock) {
      set.addAll(messages.where((m) => m.risk >= 60).map((m) => m.sender));
    }
    return set.toList()..sort();
  }

  bool isBlocked(String sender) => blockedSenders.contains(sender);
  bool isManuallyBlocked(String sender) => _blocked.contains(sender);

  List<SmsMessage> get activity =>
      messages.where((m) => m.isThreat).take(6).toList();

  // Activity over time needs timestamped history from the backend. Until
  // then these exist only as labelled demo data.
  List<int> get dailyTrend =>
      demoMode ? const [1, 0, 2, 5, 3, 8] : const <int>[];

  List<int> get weeklyTrend =>
      demoMode ? const [14, 19, 11, 23, 17, 26, 12] : const <int>[];

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
    for (final m in messages) {
      if (m.category == ThreatCategory.safe) continue;
      map[m.category] = (map[m.category] ?? 0) + 1;
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  // ------------------------------------------------------ user actions (UI)
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

  /// Turns the labelled sample data on or off.
  void setDemoMode(bool on) {
    demoMode = on;
    _demoMessages = on ? initialMessages() : const [];
    _notify();
  }

  /// Reloads the sample data (demo mode only).
  void reset() {
    _blocked.clear();
    if (demoMode) _demoMessages = initialMessages();
    _notify();
  }

  /// True once the backend has provided a permission handler.
  bool get canRequestPermission => permissionHandler != null;

  Future<void> requestSmsPermission() async {
    final handler = permissionHandler;
    if (handler == null) return;
    smsPermission = await handler();
    _notify();
  }

  /// Runs the backend scan. Does nothing until a [scanHandler] is connected.
  Future<void> runScan() async {
    final handler = scanHandler;
    if (scanning || !canScan || handler == null) return;
    scanning = true;
    scanProgress = 0;
    scanError = null;
    _notify();
    try {
      await handler(this);
      scanProgress = 1;
      lastScan = DateTime.now();
    } catch (_) {
      scanError = 'The scan could not be completed.';
    } finally {
      scanning = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    if (canScan) await runScan();
  }

  // ------------------------------------------------ backend entry points
  // The backend team calls these. The UI rebuilds automatically.

  void setSmsPermission(SmsPermission value) {
    smsPermission = value;
    _notify();
  }

  void setEngineConnected(bool value) {
    engineConnected = value;
    _notify();
  }

  void setMonitoringRunning(bool value) {
    monitoringRunning = value;
    _notify();
  }

  void setBlockingAvailable(bool value) {
    blockingAvailable = value;
    _notify();
  }

  void setProtectionScore(int? value) {
    protectionScore = value;
    _notify();
  }

  void setScanProgress(double value) {
    scanning = true;
    scanProgress = value.clamp(0.0, 1.0).toDouble();
    _notify();
  }

  /// Replaces the real message list with the latest analyzed messages.
  void setDeviceMessages(List<SmsMessage> value) {
    _deviceMessages = List.of(value);
    _notify();
  }

  /// Adds one newly analyzed message at the top of the real list.
  void addDeviceMessage(SmsMessage message) {
    _deviceMessages = [message, ..._deviceMessages];
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
