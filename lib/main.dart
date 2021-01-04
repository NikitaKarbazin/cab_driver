import 'dart:io';

import 'package:cab_driver/globalvariables.dart';
import 'package:cab_driver/screens/loginpage.dart';
import 'package:cab_driver/screens/mainpage.dart';
import 'package:cab_driver/screens/registration.dart';
import 'package:cab_driver/screens/vehicleinfo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp(
    name: 'db2',
    options: FirebaseOptions(
      appId: '1:23229613825:android:f5c7bce4da841e2352fd00',
      apiKey: 'AIzaSyCfgEzfRyw5fgKK7xf3m3Q-t9ri7QjNFis',
      messagingSenderId: '23229613825',
      projectId: 'flutter-firebase-plugins',
      databaseURL: 'https://platform-iceberg-default-rtdb.europe-west1.firebasedatabase.app',
    ),
  );

  currentFirebaseUser = await FirebaseAuth.instance.currentUser;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(


        fontFamily: 'Brand-Regular',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute:(currentFirebaseUser == null) ? LoginPage.id : MainPage.id,
      routes: {
        MainPage.id: (context) => MainPage(),
        RegistrationPage.id: (context) => RegistrationPage(),
        VehicleInfoPage.id: (context) => VehicleInfoPage(),
        LoginPage.id: (context) => LoginPage(),
      },
    );
  }
}

