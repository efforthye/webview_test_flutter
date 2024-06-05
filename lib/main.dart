import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_test_flutter/webview_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  final String env = dotenv.env['ENV'] ?? 'local';
  runApp(MyApp(env: env));
}

class MyApp extends StatelessWidget {
  final String env;

  MyApp({required this.env});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,  // DEBUG 배지 제거
      home: WebViewScreen(env: env),  // 바로 WebViewScreen을 홈 화면으로 설정
    );
  }
}
