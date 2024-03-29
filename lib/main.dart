import 'package:flutter/material.dart';

import 'connectionStatusSingleton.dart';
import 'homepage.dart';

void main() {
  ConnectionStatusSingleton connectionStatus = ConnectionStatusSingleton.getInstance();
  connectionStatus.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Urban Match',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          color: Color(0xFF181825),
          titleTextStyle:
          TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25)
        )
      ),
      home: const HomePage(),
    );
  }
}

