import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physio_connect/custom_widget/physio_connect_logo.dart';
import 'package:physio_connect/ui/splash_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // The animated HTML splash runs in a WebView on mobile; webview_flutter has
  // no web implementation here, so the browser gets a native Flutter splash.
  WebViewController? _controller;
  SplashController splashController = SplashController.to;

  @override
  void initState() {
    super.initState();

    // Force fullscreen (optional)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadFlutterAsset('assets/splash.html'); // Load HTML from assets
    }
    splashController.onInit();
    splashController.launchPage();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return Scaffold(body: WebViewWidget(controller: controller));
    }
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0EA5E9), Color(0xFF22C55E), Color(0xFFA855F7)],
          ),
        ),
        child: Center(
          child: PhysioConnectLogo(
            size: LogoSize.extraLarge,
            variant: LogoVariant.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

