import 'package:url_launcher/url_launcher.dart';


class UrlLaunchUtil {
  /// Launch URL in inBuilt-browser or inApp if boolean conditions are all FALSE, then launch In Browser[urlLauncher]
  static Future<void> urlLauncher({
    required dynamic url,
    bool inApp = false,
    bool withJavaScript = true,
    bool withDomStorage = false,
  }) async {
    final Uri toLaunch = Uri.parse(url);

    if (!await launchUrl(
      toLaunch,
      webOnlyWindowName: "Web Browser",
      // IOS launchInWebViewOrVC
      mode: inApp ? LaunchMode.inAppWebView : LaunchMode.platformDefault,
      // launch In WebView with JavaScript, DomStorage
      webViewConfiguration: WebViewConfiguration(
        enableJavaScript: withJavaScript,
        enableDomStorage: withDomStorage,
      ),
      //headers: <String, String>{'my_header_key': 'my_header_value'},
    )) {
      throw 'Could not launch $url';
    }
  }

  /// Launch URL in Universal Link Ios
  static Future<void> launchUniversalLinkIos({required String url}) async {
    final Uri toLaunch = Uri.parse(url);

    final bool nativeAppLaunchSucceeded = await launchUrl(
      toLaunch,
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (!nativeAppLaunchSucceeded) {
      await launchUrl(
        toLaunch,
        webOnlyWindowName: "Web Browser",
        mode: LaunchMode.inAppWebView,
      );
    }
  }

  /// Make phone call using inBuilt OS CallApp
  static Future<void> makePhoneCall(String phoneNumber) async {
    // Use `Uri` to ensure that `phoneNumber` is properly URL-encoded.
    // Just using 'tel:$phoneNumber' would create invalid URLs in some cases,
    // such as spaces in the input, which would cause `launch` to fail on some
    // platforms.
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  /// Launch Google map
  static Future<void> openMap(String address) async {
    // Use `Uri` to ensure that `address` is properly URL-encoded.
    // Just using 'geo:$address' would create invalid URLs in some cases,
    // such as spaces in the input, which would cause `launch` to fail on some
    // platforms.
    final Uri toLaunch =
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');

    if (!await launchUrl(toLaunch)) {
      throw 'Could not launch $address';
    }
    /*final Uri launchUri = Uri(scheme: 'geo', host: '0,0', queryParameters: {
      'q': 'https://www.google.com/maps/search/?api=1&query=$address'
    });*/
  }

  /// Send SMS using inBuilt OS SMSApp
  static Future<void> sendSMS(String phoneNumber) async {
    // Use `Uri` to ensure that `phoneNumber` is properly URL-encoded.
    // Just using 'sms:$phoneNumber' would create invalid URLs in some cases,
    // such as spaces in the input, which would cause `launch` to fail on some
    // platforms.
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  /// Send Email messages using inBuilt OS EmailApp [sendEmail]
  static Future<bool> handleSendEmail({
    String? to,
    String? from,
    String? subject,
    required String message,
  }) async {
    // Use `Uri` to ensure that `email msg` is properly URL-encoded.

    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) =>
      '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: to,
      userInfo: from,
      query: encodeQueryParameters(<String, String>{
        'subject': subject ?? 'New Message',
        'message': message,
      }),
    );
    if (!await launchUrl(emailLaunchUri, webOnlyWindowName: "Web Browser")) {
      throw 'Could not send email $to';
    }
    // Email sent
    return true;
  }
}