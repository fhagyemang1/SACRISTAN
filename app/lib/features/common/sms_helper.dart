import 'package:url_launcher/url_launcher.dart';

/// Opens the device's own Messages app with [phone] and [body] pre-filled.
/// This is a deep link, not an SMS gateway integration — no account, API
/// key, or network request on our side; the OS hands off to whichever
/// messaging app is already installed, and the user taps Send themselves.
/// Works fully offline up to that point (composing/pre-filling); sending
/// the text obviously requires the device to have cellular/SMS service,
/// same as sending any text message normally would.
Future<bool> openSmsComposer({required String phone, String? body}) async {
  final uri = Uri(
    scheme: 'sms',
    path: phone,
    queryParameters: body == null ? null : {'body': body},
  );
  return launchUrl(uri);
}
