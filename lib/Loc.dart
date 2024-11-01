import 'dart:async';

import 'package:location/location.dart' as l;
import 'package:permission_handler/permission_handler.dart';

class Loc {
  //https://medium.com/@ozgeekaratas/simple-location-tracking-app-in-flutter-fa8541d01f58

  l.Location location = l.Location();
  List<l.LocationData> locs = [];
  late StreamSubscription subscription;
  bool trackingEnabled = false;
  bool permissionGranted = false;
  int logCounter = 0;

  Future<void> _toggleLocation() async {
    if (trackingEnabled) {
      stopTracking();
    } else {
      var granted = await isPermissionGranted();
      if (!granted) {
        await requestLocationPermission();
      }
      startTracking();
    }
  }

  Future<bool> isPermissionGranted() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  Future<void> requestLocationPermission() async {
    var status = await location.requestPermission();

    if (status == l.PermissionStatus.granted) {
      permissionGranted = true;
    } else {
      permissionGranted = false;
    }
    // PermissionStatus permissionStatus = await Permission.locationWhenInUse.request();
    // if (permissionStatus == PermissionStatus.granted) {
    //   permissionGranted = true;
    // } else {
    //   permissionGranted = false;
    // }
  }

  Future<void> startTracking() async {
    await location.changeSettings(interval: 10000);
    await location.enableBackgroundMode(enable: true);

    trackingEnabled = true;
  }

  void stopTracking() {
    subscription.cancel();
    trackingEnabled = false;
  }
}