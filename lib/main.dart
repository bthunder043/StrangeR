import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stranger/screens/auth_screen.dart';
import 'firebase_options.dart';
// import 'auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Inter',
        brightness: Brightness.dark,

        // elevatedButtonTheme: ElevatedButtonThemeData(
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Color(0xff1b1b1b),
        //     foregroundColor: Colors.white.withValues(alpha: 0.8),
        //     elevation: 0,
        //     minimumSize: Size(double.infinity, 52),
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(999),
        //     ),
        //     side: BorderSide(
        //       color: Colors.white.withValues(alpha: 0.06)
        //     ),
        //     textStyle: TextStyle(
        //       fontSize: 16,
        //       fontWeight: FontWeight.w600,
        //       fontFamily: 'Inter'
        //     )
        //   )
        // ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),

          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),

          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      debugShowCheckedModeBanner: false,
      title: 'StrangeR',
      home: AuthScreen(),
      );
  }
}

