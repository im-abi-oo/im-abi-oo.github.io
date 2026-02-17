import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF121212),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const TwoMangaApp());
}

class TwoMangaApp extends StatelessWidget {
  const TwoMangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TwoManga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFE50914),
        useMaterial3: true,
      ),
      home: const SecureWebShell(),
    );
  }
}

class SecureWebShell extends StatefulWidget {
  const SecureWebShell({super.key});

  @override
  State<SecureWebShell> createState() => _SecureWebShellState();
}

class _SecureWebShellState extends State<SecureWebShell> with WidgetsBindingObserver {
  InAppWebViewController? webViewController;
  late PullToRefreshController pullToRefreshController;
  
  bool _isLoading = true;
  bool _isOffline = false;
  double _progress = 0;
  DateTime? _lastPressedBack;

  final String _encodedUrl = "aHR0cDovL21hbmdhZHJlYW0uY2xpY2sv";

  final String _securityScript = """
    (function() {
      document.addEventListener('contextmenu', e => e.preventDefault());
      const style = document.createElement('style');
      style.innerHTML = `
        * { -webkit-user-select: none !important; user-select: none !important; -webkit-touch-callout: none !important; }
        img { pointer-events: none !important; user-drag: none !important; -webkit-user-drag: none !important; max-width: 100% !important; }
        ::-webkit-scrollbar { width: 0px; background: transparent; }
      `;
      document.head.appendChild(style);
    })();
  """;

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _activateSecurity();
    _setupPullToRefresh();
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
       bool hasConnection = !results.contains(ConnectivityResult.none);
       setState(() => _isOffline = !hasConnection);
       if (hasConnection && _isLoading) {
         webViewController?.reload();
       }
    });
  }

  void _setupPullToRefresh() {
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: const Color(0xFFE50914), backgroundColor: const Color(0xFF1E1E1E)),
      onRefresh: () async {
        HapticFeedback.lightImpact();
        webViewController?.reload();
      },
    );
  }

  void _activateSecurity() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageWithBlur();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    if (await webViewController?.canGoBack() ?? false) {
      webViewController?.goBack();
      return;
    }
    final now = DateTime.now();
    if (_lastPressedBack == null || now.difference(_lastPressedBack!) > const Duration(seconds: 2)) {
      _lastPressedBack = now;
      _showSnack("برای خروج دوباره بازگشت را بزنید");
      return;
    }
    SystemNavigator.pop();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Tahoma')),
        backgroundColor: Colors.red[900],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String decodedUrl = utf8.decode(base64.decode(_encodedUrl));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(decodedUrl)),
                pullToRefreshController: pullToRefreshController,
                initialUserScripts: UnmodifiableListView<UserScript>([
                  UserScript(source: _securityScript, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
                ]),
                initialSettings: InAppWebViewSettings(
                  cacheMode: CacheMode.LOAD_DEFAULT,
                  domStorageEnabled: true,
                  javaScriptEnabled: true,
                  useHybridComposition: true,
                  allowsBackForwardNavigationGestures: true,
                  verticalScrollBarEnabled: false,
                  userAgent: "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36 TwoManga/2.1",
                ),
                onWebViewCreated: (controller) => webViewController = controller,
                onLoadStart: (controller, url) => setState(() => _isLoading = true),
                onLoadStop: (controller, url) async {
                  pullToRefreshController.endRefreshing();
                  setState(() => _isLoading = false);
                },
                onProgressChanged: (controller, progress) => setState(() => _progress = progress / 100),
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  if (!uri.toString().contains("mangadream.click")) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
              
              // نوار پیشرفت بارگذاری
              if (_isLoading && _progress < 1.0)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.transparent,
                    color: const Color(0xFFE50914),
                    minHeight: 2,
                  ),
                ),

              // نمای آفلاین (فقط زمانی که اینترنت نیست و صفحه لود نشده)
              if (_isOffline && _isLoading)
                Container(
                  color: const Color(0xFF121212),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text("اتصال برقرار نیست"),
                        TextButton(
                          onPressed: () => webViewController?.reload(),
                          child: const Text("تلاش مجدد", style: TextStyle(color: Color(0xFFE50914))),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}