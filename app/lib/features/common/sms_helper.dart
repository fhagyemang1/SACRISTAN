import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device's own Messages app with [phone] and [body] pre-filled.
/// This is a deep link, not an SMS gateway integration — no account, API
/// key, or network request on our side; the OS hands off to whichever
/// messaging app is already installed, and the user taps Send themselves.
/// Works fully offline up to that point (composing/pre-filling); sending
/// the text obviously requires the device to have cellular/SMS service,
/// same as sending any text message normally would.
///
/// Returns whether the OS reported successfully launching a handler for
/// the `sms:` link — see [openSmsComposerWithFeedback] for the
/// user-facing version most call sites should actually use.
Future<bool> openSmsComposer({required String phone, String? body}) async {
  final uri = Uri(
    scheme: 'sms',
    path: phone,
    queryParameters: body == null ? null : {'body': body},
  );
  return launchUrl(uri);
}

/// Round 11: every call site of [openSmsComposer] in the app used to
/// ignore its returned bool entirely — a fire-and-forget `sms:` deep
/// link with no feedback if it failed. That's a real, silent gap on this
/// app's Windows build in particular (one of this app's three shipped
/// targets — see README/`docs/ARCHITECTURE.md`): Windows has no
/// registered handler for the `sms:` scheme at all, so tapping "Text
/// this contact" there does *nothing visible* — no crash, no message,
/// just an unresponsive-feeling button, which is worse than an honest
/// "this isn't supported here." The same silent failure can also happen
/// on a phone/tablet with no default messaging app configured. This
/// wrapper is what call sites should use instead of [openSmsComposer]
/// directly: it surfaces a SnackBar when the OS couldn't open anything.
Future<void> openSmsComposerWithFeedback(
  BuildContext context, {
  required String phone,
  String? body,
}) async {
  final launched = await openSmsComposer(phone: phone, body: body);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Couldn't open a messaging app on this device to send the "
          'text — this is expected on Windows, which has no SMS app to '
          'hand off to.',
        ),
      ),
    );
  }
}
