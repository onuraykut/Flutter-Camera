import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'CameraPage.dart';

void main() {
  runApp(CamSplitMainPage());
}

class CamSplitMainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.black));
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.black),
      home: CameraPage(),
    );
  }
}
