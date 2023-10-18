import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:poke/firebase_options.dart';

class PokeFirebase {
  const PokeFirebase();

  Future<FirebaseApp> initializeApp() {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  FirebaseAuth auth() {
    return FirebaseAuth.instance;
  }

  FirebaseCrashlytics crashlytics() {
    return FirebaseCrashlytics.instance;
  }
}
