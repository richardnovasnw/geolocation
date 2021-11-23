import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
      home: const MyHomePage(),
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
  late Position locat;

  @override
  void initState() {
    super.initState();
    getUserLocation();
  }

  getUserLocation() async {
    final Position pos = await GeolocatorPlatform.instance
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      locat = pos;
      print(locat);
    });
  }

  final TextEditingController _controller = TextEditingController();
  String gHash = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('user').snapshots(),
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView(
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data =
                      document.data()! as Map<String, dynamic>;

                  Geolocator.getPositionStream().listen((Position position) {
                    print(position == null
                        ? 'Unknown'
                        : position.latitude.toString() +
                            ', ' +
                            position.longitude.toString());

                    setState(() {
                      gHash = GeoHash.fromDecimalDegrees(
                              position.longitude, position.latitude)
                          .geohash;
                    });
                  });
                  print('hhh $gHash');
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color:
                          gHash == data['hash'] ? Colors.green : Colors.white,
                      child: ListTile(
                        title: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
              : Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              builder: (context) {
                return BottomSheet(
                  builder: (context) {
                    return Container(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextFormField(
                          validator: (t) {
                            if (t == null) {
                              print('object');
                            }
                          },
                          controller: _controller,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              _controller.text.isEmpty
                                  ? ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Add Place')))
                                  : FirebaseFirestore.instance
                                      .collection('user')
                                      .doc()
                                      .set({
                                      'place': _controller.text,
                                      'geoLocation': GeoPoint(
                                          locat.latitude, locat.longitude),
                                      'hash': GeoHash.fromDecimalDegrees(
                                              locat.longitude, locat.latitude)
                                          .geohash
                                    }).then((value) => Navigator.pop(context));
                              _controller.clear();
                            },
                            child: Text('Post'))
                      ],
                    ));
                  },
                  onClosing: () {},
                );
              });
        },
        tooltip: 'Current Position',
        child: const Icon(Icons.location_on),
      ),
    );
  }
}
