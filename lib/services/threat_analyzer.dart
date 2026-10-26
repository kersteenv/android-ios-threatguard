import 'dart:math' as math;

import '../models/inbox_message.dart';
import '../models/risk_info.dart';

class _Rule {
  _Rule(this.label, String pattern, this.why, {this.cred = false})
    : re = RegExp(pattern, caseSensitive: false);
  final String label, why;
  final RegExp re;
  final bool cred;
}

class HighlightRange {
  HighlightRange(this.start, this.end, this.isLink);
  int start, end;
  bool isLink;
}

class ThreatAnalyzer {
  ThreatAnalyzer._();

  static final _rules = <_Rule>[
    _Rule('urgent', r'\burgent(ly)?\b', 'Creates false urgency'),
    _Rule('immediately', r'\bimmediate(ly)?\b', 'Pressures you to act fast'),
    _Rule('action required', r'action required', 'Pressures you to act fast'),
    _Rule(
      'deadline',
      r'within \d+ ?(hours?|minutes?|days?)|expires? (today|soon)|final notice',
      'Uses a deadline to rush you',
    ),
    _Rule(
      'suspended',
      r'\b(suspended|locked|deactivated|disabled|closed)\b',
      'Threatens loss of an account',
    ),
    _Rule(
      'verify / confirm',
      r'\b(verify|confirm|validate)\b',
      'Asks you to confirm details',
      cred: true,
    ),
    _Rule(
      'password',
      r'\b(password|passcode)\b',
      'Asks for login credentials',
      cred: true,
    ),
    _Rule(
      'OTP / code',
      r'\b(otp|one-time (code|password)|security code|pin)\b',
      'Asks for a one-time code',
      cred: true,
    ),
    _Rule(
      'login',
      r'\b(log ?in|sign ?in)\b',
      'Pushes you to a login page',
      cred: true,
    ),
    _Rule(
      'bank / account',
      r'\b(bank|account|credit card)\b',
      'Mentions financial or account details',
    ),
    _Rule(
      'prize / reward',
      r'\b(winner|you won|prize|lottery|gift card|reward)\b',
      'Offers an unexpected reward',
    ),
    _Rule('claim', r'\bclaim\b', 'Asks you to claim something'),
    _Rule('click here', r'click (here|below|the link)', 'Pushes you to click'),
  ];

  static const _ruleWeight = 15;
  static final _linkRe = RegExp(
    r'(https?:\/\/|www\.)\S+|\b(?:[a-z0-9-]+\.)+(com|net|org|io|ly|co|info|xyz|ru|top|click|link)\b(\/\S*)?',
    caseSensitive: false,
  );
  static final _shortRe = RegExp(
    r'\b(bit\.ly|tinyurl\.com|t\.co|goo\.gl|is\.gd|cutt\.ly)\b',
    caseSensitive: false,
  );
  static final _ipRe = RegExp(
    r'https?:\/\/\d{1,3}(\.\d{1,3}){3}',
    caseSensitive: false,
  );

  static ScanResult analyze(String text) {
    final hits = <SignalHit>[];
    var score = 0;
    var asksForDetails = false;

    for (final rule in _rules) {
      if (!rule.re.hasMatch(text)) continue;
      hits.add(SignalHit(rule.label, rule.why));
      score += _ruleWeight;
      if (rule.cred) asksForDetails = true;
    }

    if (_linkRe.hasMatch(text)) {
      hits.add(
        const SignalHit(
          'link',
          'Contains a link. Check the real address before clicking',
        ),
      );
      score += 20;
      if (_shortRe.hasMatch(text)) {
        hits.add(
          const SignalHit(
            'short link',
            'Shortened links hide the real destination',
          ),
        );
        score += 15;
      }
      if (_ipRe.hasMatch(text)) {
        hits.add(
          const SignalHit(
            'IP address link',
            'Real services rarely link to a raw IP address',
          ),
        );
        score += 20;
      }
      if (asksForDetails) {
        hits.add(
          const SignalHit(
            'link + login request',
            'A link combined with a request for details is a classic phishing pattern',
          ),
        );
        score += 15;
      }
    }

    score = math.min(score, 100);
    final level = score >= 60
        ? RiskLevel.high
        : score >= 25
        ? RiskLevel.medium
        : RiskLevel.low;
    return ScanResult(score: score, level: level, hits: hits);
  }

  static List<HighlightRange> findRanges(String text) {
    final ranges = <HighlightRange>[];
    void collect(RegExp re, bool isLink) {
      for (final m in re.allMatches(text)) {
        if (m.end == m.start) continue;
        ranges.add(HighlightRange(m.start, m.end, isLink));
      }
    }

    for (final rule in _rules) {
      collect(rule.re, false);
    }
    collect(_linkRe, true);

    ranges.sort(
      (a, b) => a.start != b.start ? a.start - b.start : b.end - a.end,
    );
    final merged = <HighlightRange>[];
    for (final r in ranges) {
      if (merged.isNotEmpty && r.start < merged.last.end) {
        final last = merged.last;
        last.end = math.max(last.end, r.end);
        if (r.isLink) last.isLink = true;
      } else {
        merged.add(HighlightRange(r.start, r.end, r.isLink));
      }
    }
    return merged;
  }
}
