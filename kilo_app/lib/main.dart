import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart'; // Tu pantalla inicial

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KI-LO App',
      debugShowCheckedModeBanner: false,

      // AQUÍ ESTÁ EL SECRETO: El tema global
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Como tu app es oscura
        // ESTA LÍNEA cambia la fuente en TODA la app automáticamente
        fontFamily: 'Ubuntu',

        // Opcional: Esto ayuda a que los textos se vean bien en fondo oscuro
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),

      home: const WelcomeScreen(),
    );
  }
}
