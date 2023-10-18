import 'package:firebase_analytics/firebase_analytics.dart';

abstract interface class PokeLogger {
  Future logAppForegrounded();

  Future logEvent({required String event, Map<String, dynamic>? data});
}

class FirebaseLogger implements PokeLogger {
  @override
  Future logAppForegrounded() {
    return FirebaseAnalytics.instance.logAppOpen();
  }

  @override
  Future logEvent({required String event, Map<String, dynamic>? data}) async {
    await FirebaseAnalytics.instance.logEvent(name: event, parameters: data);
  }
}
