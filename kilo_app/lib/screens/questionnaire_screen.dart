import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'creation_flow_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  // Variable para saber qué opción está seleccionada (0 = ninguna, 1 = crear, 2 = ya tengo)
  int _selectedOption = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/register_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Capa oscura para que se lea el texto
          Container(color: Colors.black.withOpacity(0.6)),

          // 2. BOTÓN VOLVER
          Positioned(
            top: 50,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 3. CONTENIDO PRINCIPAL
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // LOGO Y NOMBRE
                  Image.asset('assets/images/logo_kilo.png', height: 80),
                  const Text(
                    'KI-LO',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),

                  const Spacer(), // Empuja el contenido al centro/abajo
                  // PREGUNTA
                  const Text(
                    '¿Tienes ya una rutina de entrenamiento?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // OPCIÓN 1: CREAR RUTINA
                  _buildOptionCard(
                    text: 'Crear una rutina personalizada',
                    index: 1,
                  ),

                  const SizedBox(height: 15),

                  // OPCIÓN 2: YA TENGO RUTINA
                  _buildOptionCard(text: 'Ya tengo una rutina', index: 2),

                  const Spacer(),

                  // BOTÓN CONTINUAR (ROJO)
                  // Busca el botón "Continuar" al final de tu QuestionnaireScreen
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _selectedOption == 0
                          ? null // Si no ha marcado nada, el botón no hace nada
                          : () {
                              // AQUÍ SE DECIDE EL CAMINO:
                              if (_selectedOption == 1) {
                                // Opción 1: Crear rutina -> Vamos al flujo de preguntas de la IA
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreationFlowScreen(),
                                  ),
                                );
                              } else {
                                // Opción 2: Ya tengo rutina -> Vamos directo a la Home
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.red.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para las opciones seleccionables
  Widget _buildOptionCard({required String text, required int index}) {
    bool isSelected = _selectedOption == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedOption = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.transparent,
            width: 3,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
