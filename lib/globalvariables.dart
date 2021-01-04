 import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cab_driver/datamodels/driver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

User currentFirebaseUser;

 Position currentPosition;

 DatabaseReference rideRef;

 Driver currentDriverInfo;

 final assetsAudioPlayer = AssetsAudioPlayer();


 StreamSubscription<Position> homeTabPositionStream;


 StreamSubscription<Position> ridePositionStream;


 String mapKey = 'AIzaSyCfgEzfRyw5fgKK7xf3m3Q-t9ri7QjNFis';

 final CameraPosition googlePlex = CameraPosition(
   target: LatLng(49.8353139,36.663565),
   zoom: 14.4746,
 );


