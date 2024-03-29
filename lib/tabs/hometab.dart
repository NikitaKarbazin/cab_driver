import 'dart:async';

import 'package:cab_driver/brand_colors.dart';
import 'package:cab_driver/datamodels/driver.dart';
import 'package:cab_driver/globalvariables.dart';
import 'package:cab_driver/helpers/pushnotificationservice.dart';
import 'package:cab_driver/widgets/AvailabilityButton.dart';
import 'package:cab_driver/widgets/ConfirmSheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

  GoogleMapController mapController;
  Completer<GoogleMapController> _controller = Completer();


  DatabaseReference tripRequestRef;

  String availabilityTitle = 'ПРИСТУПИТЬ';
  Color availabilityColor = BrandColors.colorOrange;

  bool isAvailable = false;

  void getCurrentPosition() async {

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPosition = position;
    LatLng pos = LatLng(position.latitude, position.longitude);
    CameraPosition cp = new CameraPosition(target: pos, zoom: 14);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));



  }

  void getCurrentDriverInfo() async {

    currentFirebaseUser = await FirebaseAuth.instance.currentUser;
    DatabaseReference driverRef = FirebaseDatabase.instance.reference().child('drivers/${currentFirebaseUser.uid}');
    driverRef.once().then((DataSnapshot snapshot) {

      if(snapshot.value != null){
        currentDriverInfo = Driver.fromSnapshot(snapshot);
      }

    });
    PushNotificationService pushNotificationService = PushNotificationService();

    pushNotificationService.initialize(context);
    pushNotificationService.getToken();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentDriverInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GoogleMap(
          myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
          initialCameraPosition: googlePlex,
            onMapCreated: (GoogleMapController controller){
            _controller.complete(controller);
            mapController = controller;

            getCurrentPosition();
            },
        ),

        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget> [
              AvailabilityButton(
                title: availabilityTitle,
                color: availabilityColor,
                onPressed: (){

                  //
                showModalBottomSheet(
                    isDismissible: false,
                    context: context,
                    builder: (BuildContext context) => ConfirmSheet(
                      title: (!isAvailable) ? 'ПРИСТУПИТЬ' : 'ЗАВЕРШИТЬ',
                      subtitle: (!isAvailable) ? 'Вам станет доступно принимать заказы' : 'Вы не сможете принимать новые заказы',
                      onPressed: (){
                        if(!isAvailable){
                          goOnline();
                          getLocationUpdates();
                          Navigator.pop(context);

                          setState(() {
                            availabilityColor = BrandColors.colorBlue;
                            availabilityTitle = 'ЗАВЕРШИТЬ';
                            isAvailable =true;
                          });
                        }
                        else{
                          goOffline();
                          Navigator.pop(context);
                          setState(() {
                            availabilityColor = BrandColors.colorOrange;
                            availabilityTitle = 'ПРИСТУПИТЬ';
                            isAvailable =false;
                          });
                        }
                      },

                    ),
                );

                },
              ),
            ],
          ),
        )
      ],
    );
  }

  void goOnline(){

    Geofire.initialize('driverAvailable');
    Geofire.setLocation(currentFirebaseUser.uid, currentPosition.latitude, currentPosition.longitude);

    tripRequestRef = FirebaseDatabase.instance.reference().child('drivers/${currentFirebaseUser.uid}/newtrip');
    tripRequestRef.set('waiting');

    tripRequestRef.onValue.listen((event) {

    });

  }

  void goOffline(){

    Geofire.removeLocation(currentFirebaseUser.uid);
    tripRequestRef.onDisconnect();
    tripRequestRef.remove();
    tripRequestRef = null;

  }

  void getLocationUpdates(){

    homeTabPositionStream = Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 4).listen((Position position) {

          currentPosition = position;
          if(isAvailable) {
            Geofire.setLocation(
                currentFirebaseUser.uid, position.latitude, position.longitude);
          }

          LatLng pos = LatLng(position.latitude, position.longitude);
          CameraPosition cp = new CameraPosition(target: pos, zoom: 14);
          mapController.animateCamera(CameraUpdate.newCameraPosition(cp));

    });

  }


}

