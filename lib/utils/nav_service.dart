import 'package:flutter/material.dart';

// NavSerice is designed to offer a way to navigate to different screens from
// code that is not a Widget. Flutter's Navigator depends on a BuildContext only
// available from within a widget. This class can be used to allow navigation
// based on business logic not part of the widget tree.
//
// It's designed to be used with the MaterialApp widget and its navigatorKey prop.
//
// Example:
//   in main.dart
//
//     void main() {
//       runApp(const MyApp());
//     }
//
//     class MyApp extends StatelessWidget {
//       const MyApp({super.key});
//
//       // This widget is the root of your application.
//       @override
//       Widget build(BuildContext context) {
//         return MaterialApp(
//           // Register the navKey belonging to the global navigator
//           navigatorKey: NavService.internal.key,
//           home: Scaffold(...),
//         );
//       }
//     }
class NavService {
  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  NavService._();

  NavigatorState get navigator {
    return key.currentState!;
  }

  static final NavService internal = NavService._();

  static final NavigatorState instance = internal.navigator;

  static void push(Widget w) {
    instance.push(
      MaterialPageRoute(builder: (_) => w),
    );
  }
}
