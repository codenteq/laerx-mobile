import 'dart:async';
import 'dart:io';
import 'package:http/http.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Permission.notification.request();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          primarySwatch: Colors.amber,
          cursorColor: Colors.red,
          textSelectionColor: Colors.black
      ),
      home: const MyHomePage(title: 'Codenteq'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewController _controller;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  String? _token;
  String initialUrl = 'https://drive-course-app.codenteq.com/';

  var appBarTitleText = '';

  _getToken() {
    setState(() {
      _firebaseMessaging
          .getToken()
          .then((deviceToken) => {_token = deviceToken});
    });
  }

  Future<void> makePostRequest(String userId) async {
    final url = Uri.parse(initialUrl + 'mobile/token');
    final headers = {"Content-type": "application/json"};
    final json = '{"userId": $userId, "token": "$_token"}';
    final response = await post(url, headers: headers, body: json);
    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');
  }

  @override
  void initState() {
    super.initState();
    _getToken();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  int indexPosition = 1;

  beginLoading(String A) {
    setState(() {
      indexPosition = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: (
            IconButton(
              icon: Icon(Icons.arrow_back),
              color: Color(0xffffffff),
              onPressed: () async {
                _controller.goBack();
              },
            )
        ),
        title: Text(
          appBarTitleText,
          style: TextStyle(color: Color(0xffffffff)),
        ),
        centerTitle: true,
        elevation: 1.0,
      ),
      body: IndexedStack(
        index: indexPosition,
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(0, 3, 0, 0),
            child: WebView(
              initialUrl: initialUrl,
              javascriptMode: JavascriptMode.unrestricted,
              gestureNavigationEnabled: true,
              allowsInlineMediaPlayback: true,

              onWebViewCreated: (WebViewController webViewController) {
                _controller = webViewController;
              },
              onPageStarted: beginLoading,
              onProgress: (int progress) async {
                await _controller.getTitle().then((title) =>  { setState(() {appBarTitleText = title!;} )});
                _controller.evaluateJavascript("var figure = document.querySelector('figure'); figure.remove();");
              },
              onPageFinished: (String url) {
                if (url == initialUrl + 'user/dashboard') {
                  _controller.evaluateJavascript("localStorage.getItem('auth');").then((userId) => {makePostRequest(userId)});
                }
                if (url == initialUrl + 'user/profile') {
                  _controller.evaluateJavascript("var photo = document.querySelector('input[name=photo]'); photo.remove();");
                  _controller.evaluateJavascript("var label = document.querySelector('label[for=inputGroupFile02]'); label.remove();");
                }
                setState(() {
                  indexPosition = 0;
                });
              },
              navigationDelegate: (NavigationRequest request) {
                if (request.url.startsWith(initialUrl)) {
                  return NavigationDecision.navigate;
                } else {
                  _launchURL(request.url);
                  return NavigationDecision.prevent;
                }
              },
            ),
          ),
          Container(
            color: Colors.white,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}