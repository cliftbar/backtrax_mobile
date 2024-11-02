import 'package:baktrax/BacktrackClient.dart';
import 'package:baktrax/GeoLoc.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backtrack',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Backtrack Logger'),
    );
  }
}

// https://medium.com/@ozgeekaratas/simple-location-tracking-app-in-flutter-fa8541d01f58
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _logCounter = 0;

  // Loc loc = Loc();
  GeoLoc gLoc = GeoLoc();
  BacktrackClient client = BacktrackClient();
  bool _permissionsEnabled = false;
  String _posString = "";
  String _trackingText = "Start Tracking";

  TextEditingController textEdit = TextEditingController();

  List<String> _trackIds = [];

  final String _backtrackKey = "user";

  String _newTrackId = "track";

  String _backTrackUrl = "";

  @override
  void initState() {
    _backTrackUrl =
        "https://backtrack.cliftbar.site/map.html?key=$_backtrackKey&track=$_newTrackId";
    textEdit.text = _newTrackId;
    super.initState();
    gLoc
        .init()
        .whenComplete(() =>
            DisableBatteryOptimization.showDisableBatteryOptimizationSettings())
        .whenComplete(() => DisableBatteryOptimization
            .showDisableManufacturerBatteryOptimizationSettings(
                "Your device has additional battery optimization",
                "Follow the steps and disable the optimizations to allow smooth functioning of this app"))
        .whenComplete(() => setState(() {
              _permissionsEnabled = gLoc.isLocActive;
            }));
  }

  Future<void> _getTracks() async {
    var ts = await client.getTrackNames(key: _backtrackKey);
    setState(() {
      _trackIds = ts;
    });
  }

  Future<void> _updateBacktrackLink(text) async {
    _newTrackId = text;
    _backTrackUrl = client.makeBacktrackShareUrl(_backtrackKey, _newTrackId);
  }

  Future<void> _openBacktrackShareUrl() async {
    var backtrackUri = Uri.parse(_backTrackUrl);
    await launchUrl(backtrackUri);
  }

  Future<void> _openBacktrackMapUrl() async {
    var backtrackMapUri = Uri.parse(client.makeBacktrackMapUrl(_backtrackKey));
    await launchUrl(backtrackMapUri);
  }

  Future<void> toggleTracking() async {
    gLoc.toggleTracking(
        textEdit.text,
        (d) => setState(() {
              _posString =
                  '${d.timestamp.toIso8601String()}: ${d.latitude}, ${d.longitude}';
              _logCounter = gLoc.logCounter;
            }));

    setState(() {
      if (gLoc.trackingEnabled) {
        _trackingText = "Stop Tracking";
      } else {
        _trackingText = "Start Tracking";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FilledButton(
                    onPressed: _getTracks,
                    child: const Text("Refresh Tracks"),
                  ),
                  Expanded(
                    child: ListView.builder(
                        // scrollDirection: Axis.vertical,
                        // shrinkWrap: true,
                        itemCount: _trackIds.length,
                        itemBuilder: (BuildContext ctxt, int index) {
                          return Text(_trackIds[index]);
                        }),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Permissions Ok: $_permissionsEnabled',
                ),
                TextField(
                  controller: textEdit,
                  onChanged: _updateBacktrackLink,
                  decoration: const InputDecoration(
                    labelText: 'New Track Name',
                  ),
                ),
                const Text(
                  'Status: ',
                ),
                FilledButton(
                  onPressed: toggleTracking,
                  child: Text("$_trackingText"),
                ),
                Text(
                  'GPS Log Counter: $_logCounter\n$_posString',
                ),
                FilledButton(
                  onPressed: _openBacktrackShareUrl,
                  child: const Text("Open Track"),
                ),
                FilledButton(
                  onPressed: _openBacktrackMapUrl,
                  child: const Text("Open Map"),
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
