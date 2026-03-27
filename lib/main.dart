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
      debugShowCheckedModeBanner: false,
      title: 'StrangeR',
      home: AuthScreen(),
      );
  }
}

