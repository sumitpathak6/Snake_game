import 'package:flutter/material.dart';
import 'package:snake_game/home_page.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCpE0h-s8kSuCHc958kdKSkAKJRxJcIs7o",
      authDomain: "snakegame-22ae5.firebaseapp.com",
      projectId: "snakegame-22ae5",
      storageBucket: "snakegame-22ae5.appspot.com",
      messagingSenderId: "1096550134710",
      appId: "1:1096550134710:web:198ced7ba204a929c58717",
      measurementId: "G-BSTV99DSMM"
    )
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snake Game',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

