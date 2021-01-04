

import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cab_driver/datamodels/tripdetails.dart';
import 'package:cab_driver/globalvariables.dart';
import 'package:cab_driver/widgets/NotificationDialog.dart';
import 'package:cab_driver/widgets/ProgressDialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PushNotificationService{

  final FirebaseMessaging fcm = FirebaseMessaging();


  Future initialize(context) async {

    fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        fetchRideInfo( getRideID(message), context);
      },
      onLaunch: (Map<String, dynamic> message) async {
        fetchRideInfo( getRideID(message), context);
        },
      onResume: (Map<String, dynamic> message) async {
        fetchRideInfo( getRideID(message), context);
      },

    );

  }

  Future<String> getToken() async{

    String token = await fcm.getToken();
    print('token:$token');

    DatabaseReference tokenRef = FirebaseDatabase.instance.reference().child('drivers/${currentFirebaseUser.uid}/token');
    tokenRef.set(token);

    fcm.subscribeToTopic('alldrivers');
    fcm.subscribeToTopic('allusers');
  }

  String getRideID(Map<String, dynamic> message){
     String rideID = '';
    if(Platform.isAndroid){
      rideID = message['data']['ride_id'];
      print('ride_id: $rideID');
    }
    else{

    }
    return rideID;
  }

  void fetchRideInfo(String rideID, context){

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(status: 'Получение заказа..',),

    );

    DatabaseReference rideRef = FirebaseDatabase.instance.reference().child('rideRequest/$rideID');
    rideRef.once().then((DataSnapshot snapshot) {

      Navigator.pop(context);

      if(snapshot.value != null){

        assetsAudioPlayer.open(
          Audio('sounds/alert.mp3'),
        );
        assetsAudioPlayer.play();

        double pickupLat = double.parse(snapshot.value['location ']['latitude']);// Закоментировал
        double pickupLng = double.parse(snapshot.value['location ']['longitude']);// Закоментировал
        String pickupAddress = snapshot.value['pickup_address'].toString();

        double destinationLat = double.parse(snapshot.value['destination']['latitude'].toString());// Закоментировал
        double destinationLng = double.parse(snapshot.value['destination']['longitude'].toString());// Закоментировал
        String destinationAddress = snapshot.value['destination_address'];
        String paymentMethod = snapshot.value['payment_method'];
        String riderName = snapshot.value['rider_name'];
        String riderPhone = snapshot.value['rider_phone'];

        TripDetails tripDetails = TripDetails();

        tripDetails.rideID = rideID;
        tripDetails.pickupAddress = pickupAddress;
        tripDetails.destinationAddress = destinationAddress;
        tripDetails.pickup = LatLng(pickupLat , pickupLng);// Закоментировал
        tripDetails.destination = LatLng(destinationLat, destinationLng);// Закоментировал
        tripDetails.paymentMethod = paymentMethod;
        tripDetails.riderName = riderName;
        tripDetails.riderPhone = riderPhone;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => NotificationDialog(tripDetails: tripDetails,),

        );
      }

    });
  }

}
