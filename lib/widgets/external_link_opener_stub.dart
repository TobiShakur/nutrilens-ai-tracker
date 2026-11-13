import 'package:flutter/services.dart';

/// Fallback external link handler for non-web targets and unit/widget tests.
Future<void> openExternalLink(String url) async {
  try {
    await Clipboard.setData(ClipboardData(text: url));
  } catch (_) {
    // Ignore platform channel unavailability in headless environments.
  }
}
