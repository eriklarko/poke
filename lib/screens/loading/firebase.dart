import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:poke/firebase_options.dart';

class PokeFirebase {
  const PokeFirebase();

  Future<void> initializeApp() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  FirebaseAuth auth() {
    return FirebaseAuth.instance;
  }

  FirebaseCrashlytics crashlytics() {
    return FirebaseCrashlytics.instance;
  }

  FirebaseFirestore firestore() {
    return FirebaseFirestore.instance;
  }

  FirebaseDatabase realtimedb() {
    return FirebaseDatabase.instance;
  }

  FirebaseAppCheck appCheck() {
    return FirebaseAppCheck.instance;
  }
}
