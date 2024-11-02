import 'dart:async';

import 'package:baktrax/BacktrackClient.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeoLoc {
  late LocationSettings locationSettings;
  late Stream<Position> posStream;
  late StreamSubscription<Position> posSub;
  bool isLocActive = false;
  int logCounter = 0;
  List<Position> locs = [];
  late LocationPermission permission;
  bool trackingEnabled = false;
  BacktrackClient client = BacktrackClient();

  Future<void> checkGps() async {
    isLocActive = await Geolocator.isLocationServiceEnabled();
    if (!isLocActive) {
      LocationSettings quickSettings =
          LocationSettings(accuracy: LocationAccuracy.low);
      await Geolocator.getCurrentPosition(locationSettings: quickSettings);
    }
  }

  Future<bool> hasLocationPermission() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied by $permission');
      }
    }

    return true;
  }

  Future<void> init() async {
    await hasLocationPermission().onError((e, _) {
      print(e);
      return false;
    });
    await checkGps();
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 1),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "Example app will continue to receive your location even when you aren't using it",
            notificationTitle: "Running in Background",
            enableWakeLock: true,
          ));
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else if (kIsWeb) {
      locationSettings = WebSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
        maximumAge: Duration(minutes: 5),
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }
  }

  Position eachPos(String trackId, Position p) {
    // print("position: ${p.timestamp.toIso8601String()}");
    logCounter++;
    locs.add(p);
    client.logPoint(trackId, p);
    return p;
  }

  // Stream<Position> startTracking() {
  //   logCounter = 0;
  //   posStream = Geolocator.getPositionStream(locationSettings: locationSettings).map((p) => eachPos(p));
  //   return posStream;
  // }

  void startTrackingSub(String trackId, Function(Position) onListen) {
    logCounter = 0;
    posSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((p) => eachPos(trackId, p))
        .listen(onListen);
    trackingEnabled = true;
  }

  void cancelTrackingSub() {
    posSub.cancel();
    trackingEnabled = false;
    print("Stopping Tracking");
  }

  Future<void> toggleTracking(
      String trackId, Function(Position) onListen) async {
    if (trackingEnabled) {
      cancelTrackingSub();
    } else {
      startTrackingSub(trackId, onListen);
    }
  }
}
