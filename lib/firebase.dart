import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/firestore.dart';

class FirebaseNew extends StatefulWidget {
  const FirebaseNew({Key? key}) : super(key: key);

  @override
  _FirebaseNewState createState() => _FirebaseNewState();
}

class _FirebaseNewState extends State<FirebaseNew> {
  @override
  Widget build(BuildContext context) {
    final usersCollection = FirebaseFirestore.instance.collection('user');
    return Scaffold(
      body: FirestoreListView<Map>(
        query: usersCollection,
        primary: true,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, snapshot) {
          final user = snapshot.data();

          return Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${user['place'] ?? 'place'} ',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  Text(
                    user['hash'] ?? 'place',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}
