import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocation/firebase.dart';
import 'package:geolocator/geolocator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FirebaseNew(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Position latlng;
  String gHash = '';
  String ll = '';

  @override
  void initState() {
    super.initState();
    getUserLocation();
    _hash();
  }

  getUserLocation() async {
    final Position pos = await GeolocatorPlatform.instance
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latlng = pos;
    });
  }

  TextEditingController _controller = TextEditingController();

  _hash() {
    Geolocator.getPositionStream(
            desiredAccuracy: LocationAccuracy.high,
            forceAndroidLocationManager: true)
        .listen((Position position) {
      setState(() {
        gHash = GeoHash.fromDecimalDegrees(
                position.longitude, position.latitude,
                precision: 9)
            .geohash;
        ll = '${position.latitude},${position.longitude}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Location'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text('Current GeoHash : $gHash'),
            Text('Current LatLng : $ll'),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('user')
                  .snapshots(),
              builder: (context, snapshot) {
                return snapshot.hasData
                    ? ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: snapshot.data!.docs
                            .map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data()! as Map<String, dynamic>;

                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              color: gHash == data['hash']
                                  ? Colors.green
                                  : Colors.white,
                              child: ListTile(
                                title: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(data['place']),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'latitude : ${data['geoLocation'].latitude}, longitude : ${data['geoLocation'].longitude}'),
                                    Text('hash : ${data['hash']}')
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList())
                    : const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                    actions: [
                      ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.black)),
                          onPressed: () {
                            _controller.value.text.isNotEmpty
                                ? FirebaseFirestore.instance
                                    .collection('user')
                                    .doc()
                                    .set({
                                    'place': _controller.value.text,
                                    'geoLocation': GeoPoint(
                                        latlng.latitude, latlng.longitude),
                                    'hash': GeoHash.fromDecimalDegrees(
                                            latlng.longitude, latlng.latitude,
                                            precision: 9)
                                        .geohash
                                  }).then((value) {
                                    _controller.clear();
                                    Navigator.pop(context);
                                  })
                                : _error();
                          },
                          child: const Text('Post'))
                    ],
                    content: TextFormField(
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                      controller: _controller,
                    ));
              });
        },
        tooltip: 'Current Position',
        child: const Icon(Icons.add),
      ),
    );
  }

  _error() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Enter a valid data')));
  }
}
