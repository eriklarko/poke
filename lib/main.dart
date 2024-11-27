import 'package:flutter/material.dart';
import 'package:poke/components/app_lifecycle_listener.dart';
import 'package:poke/components/year_view/year_view.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/screens/action_details_screen/event_history.dart';
import 'package:poke/screens/dev_screen.dart';
import 'package:poke/screens/loading/initialize_app.dart';
import 'package:poke/screens/loading/loading_screen.dart';
import 'package:poke/utils/nav_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),

      // Register the navKey belonging to the global navigator
      navigatorKey: NavService.internal.key,

      // Render the LoadingScreen. It will take care of loading any resources
      // needed by the rest of the app, such as Firebase registration and
      // reading images from disk.
      //
      // There's a Firebase.auth listener registered as part of initalization
      // that will kick in and navigate to the login or home screens as
      // appropriate.
      home: LoadingScreen(
        loadingFuture: initializeApp(),
      ),
      /*home: DevScreen(
        widget: YearView(
          eventTimes: [
            DateTime.now(),
            DateTime.now().subtract(Duration(days: 1)),
            DateTime.now().subtract(Duration(days: 8)),
            DateTime.now().subtract(Duration(days: 31)),
            DateTime.now().subtract(Duration(days: 39)),
            DateTime.now().subtract(Duration(days: 62)),
            DateTime.now().subtract(Duration(days: 70)),
          ],
          onCellTap: (events, start, end) {
            print('events: $events, start: $start, end: $end');
          },
        ),
      ),*/
    );
  }
}

class AnimatedButton extends StatefulWidget {
  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  String buttonText =
      'hello000000000000000000000000000000000000000000000000000000000000';
  //final Tween<double> opacity = Tween<double>();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSize(
        //decoration: BoxDecoration(color: Colors.red),
        duration: Duration(milliseconds: 5000),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              if (buttonText == 'hello') {
                buttonText = '';
              } else {
                buttonText = 'hello';
              }
            });
          },
          child: Text(buttonText),
        ),
      ),
    );
  }
}
