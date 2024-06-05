import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WebViewScreen extends StatefulWidget {
  final String env;
  WebViewScreen({required this.env});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  Color _backgroundColor = Colors.white;
  bool isUserSeqSaved = false;
  String? userSeq;
  String? env;
  late final String baseUrl;
  final String authSignupPath = '/auth/signup';
  final String initialPath = '/';

  @override
  void initState() {
    super.initState();
    env = widget.env;
    print('현재 환경 모드: $env');
    if (WebView.platform == null) {
      WebView.platform = SurfaceAndroidWebView();
    }
    _clearUserSeq();
    _loadUserSeq();

    // 환경 변수에 따라 baseUrl 설정
    switch (env) {
      case 'dev':
        baseUrl = dotenv.env['DEV_WEBVIEW_URL'] ?? 'https://google.com';
        break;
      case 'prod':
        baseUrl = dotenv.env['PROD_WEBVIEW_URL'] ?? 'https://chatgpt.com';
        break;
      case 'local':
      default:
        baseUrl = dotenv.env['LOCAL_WEBVIEW_URL'] ?? 'https://naver.com';
        break;
    }
    print('Base URL: $baseUrl');
  }

  Future<void> _clearUserSeq() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userSeq');
    setState(() {
      isUserSeqSaved = false;
      userSeq = null;
    });
  }

  Future<void> _loadUserSeq() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userSeq = prefs.getString('userSeq');
    setState(() {
      isUserSeqSaved = userSeq != null;
    });
  }

  Future<void> _saveUserSeq(String seq) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userSeq', seq);
    setState(() {
      isUserSeqSaved = true;
      userSeq = seq;
    });
  }

  String? _getSeqFromUrl(String url) {
    Uri uri = Uri.parse(url);
    return uri.queryParameters['userSeq'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // 배경색 설정
      body: SafeArea(
        child: WebView(
          initialUrl: '$baseUrl$initialPath',
          javascriptMode: JavascriptMode.unrestricted,
          javascriptChannels: <JavascriptChannel>{
            JavascriptChannel(
              name: 'UserSeqChannel',
              onMessageReceived: (JavascriptMessage message) async {
                String seq = message.message;
                await _saveUserSeq(seq);
                print('Received userSeq from JavaScript: $seq');
              },
            ),
          },
          onWebViewCreated: (WebViewController webViewController) {
            _controller = webViewController;
          },
          onPageStarted: (String url) async {
            // URL이 변경될 때 호출됨
            print('현재 url은?: $url');
            print('로그인 상태는?: $isUserSeqSaved');

            if (isUserSeqSaved) {
              print('UserSeq는?: $userSeq');
              _backgroundColor = const Color(0xFF242830);
            }

            if (url.contains(authSignupPath)) {
              String? seq = _getSeqFromUrl(url);
              if (seq != null) {
                await _saveUserSeq(seq);
                print('Extracted userSeq: $seq');
              }
            }

            // 시작 페이지가 아닌 경우 혹은 이미 로그인한 것이 남아 있으면서 /signup 이면 배경색 변경
            var isNotStartPage = !(url == '$baseUrl$authSignupPath') && !(url == '$baseUrl$initialPath');
            if (isNotStartPage || (isUserSeqSaved && url == '$baseUrl$authSignupPath')) {
              setState(() {
                _backgroundColor = const Color(0xFF242830); // 로그인 성공시 배경색 변경
              });
            } else {
              setState(() {
                _backgroundColor = Colors.white; // 다른 URL일 경우 기본 배경색으로 변경
              });
            }
          },
        ),
      ),
    );
  }
}
