import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Whether the app may read SMS on this device.
/// Set by the backend / permission layer, never guessed by the UI.
enum SmsPermission { notGranted, granted, unsupported }

/// What the app can honestly say about protection right now.
/// It is derived from real state only (see `GuardState.status`).
enum ProtectionStatus {
  permissionRequired,
  readyToScan,
  scanning,
  lastScanCompleted,
  monitoringActive,
  notSupported,
}

extension ProtectionStatusInfo on ProtectionStatus {
  /// Full name, e.g. for headings and the Settings card.
  String get label => switch (this) {
    ProtectionStatus.permissionRequired => 'Permission Required',
    ProtectionStatus.readyToScan => 'Ready to Scan',
    ProtectionStatus.scanning => 'Scanning',
    ProtectionStatus.lastScanCompleted => 'Last Scan Completed',
    ProtectionStatus.monitoringActive => 'Monitoring Active',
    ProtectionStatus.notSupported => 'Not Supported',
  };

  /// Short form for small pills.
  String get shortLabel => switch (this) {
    ProtectionStatus.permissionRequired => 'NEEDS ACCESS',
    ProtectionStatus.readyToScan => 'READY',
    ProtectionStatus.scanning => 'SCANNING',
    ProtectionStatus.lastScanCompleted => 'SCANNED',
    ProtectionStatus.monitoringActive => 'LIVE',
    ProtectionStatus.notSupported => 'UNSUPPORTED',
  };

  String get description => switch (this) {
    ProtectionStatus.permissionRequired =>
      'Allow SMS access so ThreatGuard can analyze your messages.',
    ProtectionStatus.readyToScan =>
      'SMS access is granted. Run a scan to analyze your messages.',
    ProtectionStatus.scanning => 'Analyzing your messages…',
    ProtectionStatus.lastScanCompleted =>
      'Your last scan has finished. See the results below.',
    ProtectionStatus.monitoringActive =>
      'New messages are analyzed as they arrive.',
    ProtectionStatus.notSupported =>
      'SMS scanning is not available on this device.',
  };

  Color get color => switch (this) {
    ProtectionStatus.permissionRequired => AppColors.orange,
    ProtectionStatus.readyToScan => AppColors.primary,
    ProtectionStatus.scanning => AppColors.primary,
    ProtectionStatus.lastScanCompleted => AppColors.green,
    ProtectionStatus.monitoringActive => AppColors.green,
    ProtectionStatus.notSupported => AppColors.muted,
  };

  /// Gradient used for the big headline on the Dashboard.
  LinearGradient get gradient => switch (this) {
    ProtectionStatus.permissionRequired => const LinearGradient(
      colors: [AppColors.orange, Color(0xFFFFD58A)],
    ),
    ProtectionStatus.readyToScan || ProtectionStatus.scanning =>
      const LinearGradient(colors: [AppColors.primary, AppColors.blue]),
    ProtectionStatus.lastScanCompleted ||
    ProtectionStatus.monitoringActive => AppGradients.safe,
    ProtectionStatus.notSupported => const LinearGradient(
      colors: [AppColors.muted, Color(0xFFCBD5E1)],
    ),
  };
}
