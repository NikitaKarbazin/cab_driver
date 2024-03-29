import 'dart:async';

import 'package:cab_driver/brand_colors.dart';
import 'package:cab_driver/datamodels/tripdetails.dart';
import 'package:cab_driver/helpers/helpermethods.dart';
import 'package:cab_driver/helpers/mapkithelper.dart';
import 'package:cab_driver/widgets/CollectPaymentDialog.dart';
import 'package:cab_driver/widgets/ProgressDialog.dart';
import 'package:cab_driver/widgets/TaxiButton.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../globalvariables.dart';

class NewTripPage extends StatefulWidget {

  final TripDetails tripDetails;
  NewTripPage({this.tripDetails});
  @override
  _NewTripPageState createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage> {

  GoogleMapController rideMapController;
  Completer<GoogleMapController> _controller = Completer();
  double mapPaddingBottom = 0;

  Set<Marker> _markers = Set<Marker>();
  Set<Circle> _circles = Set<Circle>();
  Set<Polyline> _polyLines = Set<Polyline>();

  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();


  BitmapDescriptor movingMarkerIcon;

  Position myPosition;

  String status = 'accepted';

  String durationString = '';

  bool isRequestingDirection = false;

  String buttonTitle= 'ПРИБЫЛ';

  Color buttonColor = BrandColors.colorBlue;

  Timer timer;

  int durationCounter = 0;

  void createMarker(){
    if(movingMarkerIcon == null){

      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2,2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, 'images/car_android.png').then((icon){
        movingMarkerIcon = icon;
      });
    }
  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    acceptTrip();
  }



  @override
  Widget build(BuildContext context) {

    createMarker();

    return Scaffold(
      body: Stack(
        children: <Widget>[
        GoogleMap(
          padding: EdgeInsets.only(bottom: mapPaddingBottom),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        mapToolbarEnabled: true,
        mapType: MapType.normal,
        circles: _circles,
        markers: _markers,
        polylines: _polyLines,
        initialCameraPosition: googlePlex,
        onMapCreated: (GoogleMapController controller) async {
          _controller.complete(controller);
          rideMapController = controller;

          setState(() {
            mapPaddingBottom = 260;
          });

          var currentLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);
          var pickupLatLng = widget.tripDetails.pickup;

          await getDirection(currentLatLng, pickupLatLng);

          getLocationUpdates();



        },
      ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    )
                  )
                ],
              ),
              height: 255,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    Text(
                      durationString,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Brand-Bold',
                        color: BrandColors.colorAccentPurple
                      ),
                    ),

                    SizedBox(height: 5,),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(widget.tripDetails.riderName, style: TextStyle(fontSize: 22, fontFamily: 'Brand-Bold'),),

                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(Icons.call),
                        ),
                      ],
                    ),

                    SizedBox(height: 25,),

                    Row(
                      children: <Widget>[
                        Image.asset('images/pickicon.png', height: 16, width: 16,),
                        SizedBox(width: 18,),

                        Expanded(
                          child: Container(
                            child: Text(
                              widget.tripDetails.pickupAddress,
                              style: TextStyle(fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 15,),

                    Row(
                      children: <Widget>[
                        Image.asset('images/desticon.png', height: 16, width: 16,),
                        SizedBox(width: 18,),

                        Expanded(
                          child: Container(
                            child: Text(
                              widget.tripDetails.destinationAddress,
                              style: TextStyle(fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 25,),

                    TaxiButton(
                      title: buttonTitle,
                      color: buttonColor,
                      onPressed: () async{

                        if(status == 'accepted') {
                          status = 'arrived';
                          rideRef.child('status').set(('arrived'));

                          setState(() {
                            buttonTitle = 'СТАРТ ПОЕЗДКИ';
                            buttonColor = BrandColors.colorOrange;
                          });

                          HelperMethods.showProgressDialog(context);

                          await getDirection(widget.tripDetails.pickup, widget.tripDetails.destination);

                          Navigator.pop(context);
                        }
                        else if(status == 'arrived'){
                          status = 'ontrip';
                          rideRef.child('status').set('ontrip');

                          setState(() {
                            buttonTitle = 'Завершить поездку';
                            buttonColor = Colors.red[900];
                          });

                          startTimer();
                        }
                        else if(status == 'ontrip'){
                          endTrip();
                        }

                      },
                    )

                  ],
                ),
              ),
            ),
          )
        ],
      ),

      );
  }

  void acceptTrip(){
    String rideID = widget.tripDetails.rideID;
    rideRef = FirebaseDatabase.instance.reference().child('rideRequest/$rideID');

    rideRef.child('status').set('accepted');
    rideRef.child('driver_name').set(currentDriverInfo.fullName);
    rideRef.child('car_details').set('${currentDriverInfo.carColor} - ${currentDriverInfo.carModel}');
    rideRef.child('driver_phone').set(currentDriverInfo.phone);
    rideRef.child('driver_id').set(currentDriverInfo.id);

    Map locationMap = {
      'latitude': currentPosition.latitude.toString(),
      'longitude': currentPosition.longitude.toString(),
    };

    rideRef.child('driver_location').set(locationMap);

    DatabaseReference historyRef = FirebaseDatabase.instance.reference().child('drivers/${currentFirebaseUser.uid}/history/$rideID');
    historyRef.set(true);


  }

  void getLocationUpdates(){

    LatLng oldPosition = LatLng(0, 0);


    ridePositionStream = Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.bestForNavigation).listen((Position position) {
      myPosition = position;
      currentPosition = position;
      LatLng pos = LatLng(position.latitude, position.longitude);

      var rotation = MapKitHelper.getMarkerRotation(oldPosition.latitude, oldPosition.longitude, pos.latitude, pos.longitude);

      Marker movingMarker = Marker(
      markerId: MarkerId('Айсберг'),
        position: pos,
        icon: movingMarkerIcon,
      rotation: rotation,
      infoWindow: InfoWindow(title: 'Мое местоположение')
      );

      setState(() {

        CameraPosition cp = new CameraPosition(target: pos, zoom: 17);
        rideMapController.animateCamera(CameraUpdate.newCameraPosition(cp));

        _markers.removeWhere((marker) => marker.markerId.value == 'Айсберг');
        _markers.add(movingMarker);
      });

      oldPosition = pos;

      updateTripDetails();

      Map locationMap = {
        'latitude' : myPosition.latitude.toString(),
        'longitude' : myPosition.longitude.toString(),
      };

      rideRef.child('driver_location').set(locationMap);

    });

  }

  Future<void> updateTripDetails() async {

    if(!isRequestingDirection){

      isRequestingDirection = true;

      if(myPosition == null){
        return;
      }

      var positionLatLng = LatLng(myPosition.latitude, myPosition.longitude);

      LatLng destinationLatLng;

      if(status == 'accepted'){
        destinationLatLng = widget.tripDetails.pickup;
      }
      else{
        destinationLatLng = widget.tripDetails.destination;
      }

      var directionDetails = await HelperMethods.getDirectionDetails(positionLatLng, destinationLatLng);

      if(directionDetails != null){

        setState(() {
          durationString = directionDetails.durationText;
        });

      }
      isRequestingDirection = false;
    }

  }

  Future<void> getDirection(LatLng pickupLatLng, LatLng destinationLatLng) async {

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(
          status: 'Пожалуйста, подождите...',
        ));

    var thisDetails =
    await HelperMethods.getDirectionDetails(pickupLatLng, destinationLatLng);


    Navigator.pop(context);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> results =
    polylinePoints.decodePolyline(thisDetails.encodedPoints);

    polylineCoordinates.clear();
    if (results.isNotEmpty) {
      //loop through all PointLatLng points and convert them
      // to a list of LatLng, required by the Polyline
      results.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _polyLines.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId('polyid'),
        color: Color.fromARGB(255, 95, 109, 237),
        points: polylineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      _polyLines.add(polyline);
    });

    //make polyline to fit into the map

    LatLngBounds bounds;

    if (pickupLatLng.latitude > destinationLatLng.latitude &&
        pickupLatLng.longitude > destinationLatLng.longitude) {
      bounds =
          LatLngBounds(southwest: destinationLatLng, northeast: pickupLatLng);
    } else if (pickupLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(pickupLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, pickupLatLng.longitude));
    } else if (pickupLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, pickupLatLng.longitude),
        northeast: LatLng(pickupLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      bounds =
          LatLngBounds(southwest: pickupLatLng, northeast: destinationLatLng);
    }

    rideMapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

    Marker pickupMarker = Marker(
      markerId: MarkerId('pickup'),
      position: pickupLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    Marker destinationMarker = Marker(
      markerId: MarkerId('destination'),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markers.add(pickupMarker);
      _markers.add(destinationMarker);
    });

    Circle pickupCircle = Circle(
      circleId: CircleId('pickup'),
      strokeColor: Colors.blue,
      strokeWidth: 3,
      radius: 12,
      center: pickupLatLng,
      fillColor: BrandColors.colorBlue,
    );

    Circle destinationCircle = Circle(
      circleId: CircleId('pickup'),
      strokeColor: BrandColors.colorAccentPurple,
      strokeWidth: 3,
      radius: 12,
      center: destinationLatLng,
      fillColor: BrandColors.colorAccentPurple,
    );

    setState(() {
      _circles.add(pickupCircle);
      _circles.add(destinationCircle);
    });
  }

  void startTimer(){
    const interval = Duration(seconds: 1);
    timer = Timer.periodic(interval, (timer) {
      durationCounter++;
    });

  }

  void endTrip() async{
    timer.cancel();

    HelperMethods.showProgressDialog(context);

    var currentLatLng = LatLng(myPosition.latitude, myPosition.longitude);

    var directionDetails = await HelperMethods.getDirectionDetails(widget.tripDetails.pickup, currentLatLng);

    Navigator.pop(context);

    int fares = HelperMethods.estimateFares(directionDetails, durationCounter);

    rideRef.child('fares').set(fares.toString());

    rideRef.child('status').set('ended');

    ridePositionStream.cancel();

    showDialog(
        context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => CollectPayment(
        paymentMethod: widget.tripDetails.paymentMethod,
        fares: fares,
      )
    );
    toUpEarnings(fares);
  }

  void toUpEarnings(int fares){
    DatabaseReference earningsRef = FirebaseDatabase.instance.reference().child('drivers/${currentFirebaseUser.uid}/earnings');
    earningsRef.once().then((DataSnapshot snapshot) {

      if(snapshot.value != null){
        double oldEarnings =double.parse(snapshot.value.toString());

        double adjustedEarnings = fares.toDouble() + oldEarnings;

        earningsRef.set(adjustedEarnings.toStringAsFixed(2));
      }
      else{
        double adjustedEarnings = fares.toDouble();
        earningsRef.set(adjustedEarnings.toStringAsFixed(2));
      }
    });
  }
}
