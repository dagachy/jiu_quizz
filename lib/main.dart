import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/services.dart';

import 'tabs_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      StreamProvider<Report>.value(value: Global.reportRef.documentStream),
      StreamProvider<User>.value(value: AuthService().user),
    ]);
    // return MaterialApp(
    //   title: 'Firebase Analytics Demo',
    //   theme: ThemeData(
    //     primarySwatch: Colors.blue,
    //   ),
    //   navigatorObservers: <NavigatorObserver>[observer],
    //   home: MyHomePage(
    //     title: 'Firebase Analytics Demo',
    //     analytics: analytics,
    //     observer: observer,
    //   ),
    // );
  }
}
