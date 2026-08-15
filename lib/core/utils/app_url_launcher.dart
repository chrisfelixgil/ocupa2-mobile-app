import 'package:url_launcher/url_launcher.dart';

typedef AppUriLauncher = Future<bool> Function(Uri uri);

Future<bool> launchAppUri(Uri uri) async {
  if (!await canLaunchUrl(uri)) {
    return false;
  }

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
