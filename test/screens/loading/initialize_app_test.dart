import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:poke/screens/loading/firebase.dart';

@GenerateMocks([PokeFirebase])
void main() {
  test('initializes firebase', () {});
  test('auth listener navigates to login screen when logged out', () {});
  test('auth listener navigates to home screen when logged in', () {});

  test('error listener catches render error and reports it', () {});
  test('error listener catches uncaught error and reports it', () {});
}
