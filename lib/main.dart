import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:user/ui/splash_screen.dart';

void main() {
  Crashlytics.instance.enableInDevMode = true;

  // Pass all uncaught errors to Crashlytics.
  FlutterError.onError = Crashlytics.instance.recordFlutterError;

  runZoned(() {
    runApp(MyApp());
  }, onError: Crashlytics.instance.recordError);
  //runApp(MyApp());
}

class MyApp extends StatelessWidget {
  var yetToStartColor = const Color(0xfff58053);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Repeat Click',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        fontFamily: 'Nunito',
      ),
      home: SplashScreen(),
      locale: Locale('en', 'US'),
      supportedLocales: [
        const Locale('en', 'US'), // English// Thai
      ],
      // routes: routes,
    );
  }
}