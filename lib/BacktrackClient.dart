import 'dart:convert';

import 'package:geojson_vi/geojson_vi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:battery_plus/battery_plus.dart' as batt;

class BacktrackClient {
  String baseUrl = 'https://backtrack.cliftbar.site';
  batt.Battery battery = batt.Battery();

  Future<List<String>> getTrackNames({String key = 'user'}) async {
    var response = await http.get(
      Uri.parse('$baseUrl/tracks?key=$key'),
    );

    List<String> ids = List.from(jsonDecode(response.body));

    return ids;
  }

  Future<GeoJSONFeatureCollection> _getTrack(
      {required String key, required String trackId}) async {
    var response = await http.get(
      Uri.parse('$baseUrl/track?key=$key&track_id=$trackId'),
    );

    // var body = jsonDecode(response.body) as Map<String, dynamic>;
    var track = GeoJSONFeatureCollection.fromJSON(response.body);
    return track;
  }

  Future<void> logPoint(String trackId, Position p) async {
    var battLevel = await battery.batteryLevel;
    Map<String, dynamic> body = {
      "key": "user",
      "track_id": trackId,
      "ts": p.timestamp.toIso8601String(),
      "lat": p.latitude,
      "lon": p.longitude,
      // "description": "%DESC",
      "altitude": p.altitude,
      "direction": p.heading,
      "speed_kph": p.speed,
      // "distance": p,
      "battery": battLevel,
      "accuracy": p.accuracy,
      // "android_id": "%AID",
      // "start_time": %STARTTIMESTAMP,
      // "profile": "%PROFILE"
    };
    http.post(Uri.parse('$baseUrl/track'),
        body: jsonEncode(body),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        });
  }
}
