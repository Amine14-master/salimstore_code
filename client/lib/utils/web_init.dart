// web_init.dart - Web platform initialization
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void initializeWebView() {
  WebViewPlatform.instance = WebWebViewPlatform();
}
