import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importa el motor de Firebase
import 'firebase_options.dart'; // Importa el archivo que generamos antes
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- NUEVO: Para leer el archivo .env
import 'screens/welcome_screen.dart';

void main() async {
  // 1. Aseguramos que Flutter esté listo para ejecutar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Cargamos las variables secretas del archivo .env <-- NUEVO
  await dotenv.load(fileName: ".env");

  // 3. Arrancamos Firebase con la configuración específica de tu proyecto
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KI-LO App',
      debugShowCheckedModeBanner: false,

      // El tema global que ya tenías configurado
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Ubuntu',

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),

      home: const WelcomeScreen(),
    );
  }
}
