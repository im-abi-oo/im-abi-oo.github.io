import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:app_links/app_links.dart';

// URL Base64 Encoded: https://two.916584.ir.cdn.ir
// تغییر کوچک در رشته برای جلوگیری از اسکن ساده استاتیک (اختیاری)
const String _kBase64Url = "aHR0cHM6Ly90d28uOTE2NTg0LmlyLmNkbi5pcg==";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تنظیم استایل سیستم برای ادغام کامل با اپلیکیشن
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // برای پس زمینه تیره
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // قفل کردن جهت صفحه روی عمودی
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
        fontFamily: 'Tahoma',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const NativeSplashScreen(),
    );
  }
}

/// --------------------------------------------------------------------------
/// 1. Optimized Native Splash Screen
/// انیمیشن ضربانی و ورود نرم برای حس مدرن‌تر
/// --------------------------------------------------------------------------
class NativeSplashScreen extends StatefulWidget {
  const NativeSplashScreen({super.key});

  @override
  State<NativeSplashScreen> createState() => _NativeSplashScreenState();
}

class _NativeSplashScreenState extends State<NativeSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // انیمیشن تپش (Breath Effect)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.8,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // انتقال به صفحه اصلی بعد از پایان انیمیشن
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SecureWebShell(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE50914,
                            ).withValues(alpha: 0.3), // FIX: withValues
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      // لوگوی مینیمال کتاب
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 60,
                        color: Color(0xFFE50914),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "TwoManga",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Secure & Fast Reader",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(
                          alpha: 0.5,
                        ), // FIX: withValues
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// --------------------------------------------------------------------------
/// 2. Secure Web Shell (Hardened)
/// امنیت بالا، مدیریت خطا و بدون نشتی لینک
/// --------------------------------------------------------------------------
class SecureWebShell extends StatefulWidget {
  const SecureWebShell({super.key});

  @override
  State<SecureWebShell> createState() => _SecureWebShellState();
}

class _SecureWebShellState extends State<SecureWebShell>
    with WidgetsBindingObserver {
  InAppWebViewController? webViewController;
  late PullToRefreshController pullToRefreshController;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  bool _isLoading = true;
  bool _isOffline = false;
  bool _hasLoadError = false;

  // تکنیک مخفی سازی: تا وقتی صفحه کامل لود نشده، وب ویو را نشان نده
  // این بهترین راه برای جلوگیری از دیدن صفحه خطای مرورگر است
  bool _isWebViewVisible = false;

  double _progress = 0;
  DateTime? _lastPressedBack;
  late String _targetUrl;

  final String _securityScript = """
    (function() {
      document.addEventListener('contextmenu', e => e.preventDefault());
      const style = document.createElement('style');
      style.innerHTML = `
        * { -webkit-user-select: none !important; user-select: none !important; -webkit-touch-callout: none !important; -webkit-tap-highlight-color: transparent !important; }
        img { pointer-events: none !important; -webkit-user-drag: none; }
        ::-webkit-scrollbar { width: 0px; background: transparent; }
      `;
      document.head.appendChild(style);
    })();
  """;

  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();

    // دیکد کردن امن آدرس
    try {
      _targetUrl = utf8.decode(base64.decode(_kBase64Url));
    } catch (e) {
      _targetUrl = "about:blank"; // Fallback امن
    }

    _activateSecurity();
    _initDeepLink();
    _setupPullToRefresh();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      bool hasConnection = !results.contains(ConnectivityResult.none);

      if (!hasConnection) {
        setState(() => _isOffline = true);
      } else if (hasConnection && (_isOffline || _hasLoadError)) {
        setState(() {
          _isOffline = false;
          _hasLoadError = false;
        });
        webViewController?.reload();
      }
    });
  }

  void _initDeepLink() {
    _appLinks = AppLinks();

    // لینک اولیه (Cold Start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // لینک‌های جدید (Runtime)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    String path = uri.path;
    if (uri.hasQuery) path += "?${uri.query}";

    if (path.isNotEmpty) {
      String baseUrl = _targetUrl.endsWith('/')
          ? _targetUrl.substring(0, _targetUrl.length - 1)
          : _targetUrl;
      String cleanPath = path.startsWith('/') ? path : '/$path';
      String finalUrl = "$baseUrl$cleanPath";

      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(finalUrl)));
    }
  }

  void _setupPullToRefresh() {
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: const Color(0xFFE50914),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      onRefresh: () async {
        HapticFeedback.lightImpact(); // ویبره ملایم
        if (_hasLoadError) setState(() => _hasLoadError = false);
        webViewController?.reload();
      },
    );
  }

  Future<void> _activateSecurity() async {
    // جلوگیری از اسکرین‌شات و ضبط صفحه (فقط اندروید، iOS توسط ScreenProtector مات می‌شود)
    if (Platform.isAndroid) {
      // توجه: preventScreenshotOn باعث سیاه شدن صفحه هنگام اسکرین شات یا اشتراک‌گذاری می‌شود
      await ScreenProtector.preventScreenshotOn();
    }
    // مات کردن صفحه در Recents
    await ScreenProtector.protectDataLeakageWithBlur();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _linkSubscription?.cancel();
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
    if (_lastPressedBack == null ||
        now.difference(_lastPressedBack!) > const Duration(seconds: 2)) {
      _lastPressedBack = now;
      HapticFeedback.selectionClick();
      _showSnack("برای خروج دوباره بازگشت را بزنید");
      return;
    }
    SystemNavigator.pop();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Tahoma'),
        ),
        backgroundColor: const Color(0xFFE50914), // قرمز برند
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        width: 250, // کوچک و وسط‌چین
      ),
    );
  }

  String get _hostName {
    try {
      return Uri.parse(_targetUrl).host;
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    // انتخاب لودر مناسب پلتفرم (Native Feel)
    final loadingIndicator = Platform.isIOS
        ? const CupertinoActivityIndicator(radius: 15, color: Colors.white)
        : const CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFE50914),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          bottom: false,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. WebView Layer
              // ما شفافیت (Opacity) را کنترل می‌کنیم. تا وقتی لود تمام نشده یا خطا دارد، دیده نمی‌شود.
              Opacity(
                opacity: (_hasLoadError || !_isWebViewVisible) ? 0.0 : 1.0,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_targetUrl)),
                  pullToRefreshController: pullToRefreshController,
                  initialUserScripts: UnmodifiableListView<UserScript>([
                    UserScript(
                      source: _securityScript,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    ),
                  ]),
                  initialSettings: InAppWebViewSettings(
                    // کش تهاجمی برای سرعت بالا و حالت آفلاین
                    cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
                    domStorageEnabled: true,
                    javaScriptEnabled: true,
                    useHybridComposition: true,
                    allowsBackForwardNavigationGestures: true,
                    verticalScrollBarEnabled: false,
                    // جلوگیری از Zoom تصادفی
                    minimumFontSize: 14,
                    supportZoom: false,
                    // یوزر ایجنت به‌روز برای رفتار بهتر سرور
                    userAgent:
                        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36",
                  ),
                  onWebViewCreated: (controller) =>
                      webViewController = controller,
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _hasLoadError = false;
                      // موقع شروع لود جدید، وب‌ویو را موقتا مخفی نمیکنیم تا تجربه کاربری پرش نداشته باشد،
                      // مگر اینکه خطای قبلی داشته باشیم.
                    });
                  },
                  onLoadStop: (controller, url) async {
                    pullToRefreshController.endRefreshing();
                    setState(() {
                      _isLoading = false;
                      _isWebViewVisible = true; // نمایش صفحه پس از لود موفق
                    });
                  },

                  // --- ZERO LEAK ERROR HANDLING ---
                  onReceivedError: (controller, request, error) async {
                    setState(() {
                      _hasLoadError = true;
                      _isLoading = false;
                      _isWebViewVisible = false; // مخفی‌سازی فوری وب‌ویو
                    });
                  },
                  onReceivedHttpError:
                      (controller, request, errorResponse) async {
                        // FIX: Null check دقیق
                        if ((errorResponse.statusCode ?? 0) >= 400) {
                          setState(() {
                            _hasLoadError = true;
                            _isLoading = false;
                            _isWebViewVisible = false;
                          });
                        }
                      },

                  onProgressChanged: (controller, progress) =>
                      setState(() => _progress = progress / 100),

                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;
                        String urlString = uri.toString();

                        if (urlString.contains(_hostName) ||
                            urlString.contains("916584")) {
                          return NavigationActionPolicy.ALLOW;
                        }

                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          return NavigationActionPolicy.CANCEL;
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                ),
              ),

              // 2. Custom Progress Bar (Native Style)
              // فقط وقتی وب‌ویو قابل دیدن است و هنوز لود می‌شود
              if (_isLoading &&
                  _progress < 1.0 &&
                  !_hasLoadError &&
                  _isWebViewVisible)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.transparent,
                    color: const Color(0xFFE50914),
                    minHeight: 2,
                  ),
                ),

              // 3. Initial Loading / Processing State
              if (_isLoading && !_isWebViewVisible && !_hasLoadError)
                Center(child: loadingIndicator),

              // 4. Secure Native Error Screen
              // این صفحه جایگزین صفحه خطای مرورگر می‌شود تا URL لو نرود
              if (_hasLoadError || (_isOffline && _isLoading))
                Container(
                  color: const Color(0xFF121212),
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 80,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          "ارتباط برقرار نشد",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tahoma',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "اتصال اینترنت خود را بررسی کنید",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          height: 45,
                          width: 160,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                _hasLoadError = false;
                                _isLoading = true;
                              });
                              webViewController?.reload();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE50914),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "تلاش مجدد",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
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
