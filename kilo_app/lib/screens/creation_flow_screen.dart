import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class CreationFlowScreen extends StatefulWidget {
  const CreationFlowScreen({super.key});

  @override
  State<CreationFlowScreen> createState() => _CreationFlowScreenState();
}

class _CreationFlowScreenState extends State<CreationFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isGenerating = false;

  // --- VARIABLES PARA GUARDAR LA INFO ---
  String? _gender;
  String? _goal;
  String? _frequency;
  String? _injury;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _injuryDetailController = TextEditingController();

  void _nextStep() {
    if (_currentStep == 0 && _gender == null)
      return _mostrarAviso("Selecciona tu género");
    if (_currentStep == 1 && _goal == null)
      return _mostrarAviso("Selecciona tu objetivo");
    if (_currentStep == 2) {
      if (_ageController.text.isEmpty ||
          _weightController.text.isEmpty ||
          _heightController.text.isEmpty) {
        return _mostrarAviso("Rellena todas tus medidas");
      }
    }
    if (_currentStep == 3 && _frequency == null)
      return _mostrarAviso("Selecciona una frecuencia");
    if (_currentStep == 4) {
      if (_injury == null && _injuryDetailController.text.isEmpty) {
        return _mostrarAviso("Indica si tienes alguna lesión");
      }
    }

    if (_currentStep == 4) {
      _generarRutinaYGuardar();
    } else if (_currentStep < 5) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texto), backgroundColor: Colors.redAccent));
  }

  // --- MAGIA DE LA IA (CON REINTENTO AUTOMÁTICO PARA ERRORES 503) ---
  Future<void> _generarRutinaYGuardar() async {
    setState(() {
      _isGenerating = true;
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      double peso =
          double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
      int altura = int.tryParse(_heightController.text) ?? 0;
      int edad = int.tryParse(_ageController.text) ?? 0;
      String lesionFinal =
          _injury == 'none' ? 'Ninguna' : _injuryDetailController.text;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({
        'genero': _gender,
        'objetivo': _goal,
        'peso': peso,
        'altura': altura,
        'edad': edad,
        'frecuencia': _frequency,
        'lesiones': lesionFinal,
      });

      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty)
        throw Exception('API Key no encontrada en el archivo .env');

      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
      );

      final prompt = '''
      Eres un entrenador personal de élite. Crea una rutina de gimnasio dividida por días.
      Responde ÚNICAMENTE con un ARRAY (lista) en formato JSON estricto, donde cada elemento del array sea una rutina independiente para un día de entrenamiento.
      NO escribas texto fuera del JSON. NO uses markdown de código.
      
      Datos del usuario:
      - Género: $_gender, Edad: $edad, Peso: $peso kg, Altura: $altura cm, Objetivo: $_goal.
      - Frecuencia: $_frequency días/semana. Lesiones: $lesionFinal.

      Estructura obligatoria del JSON (devuelve un ARRAY de objetos como este):
      [
        {
          "nombre": "DÍA 1: Pecho y Tríceps (IA)",
          "descripcion": "Rutina adaptada a tus datos",
          "planificacion": [
            {
              "dia": "Ejercicios de la sesión",
              "musculo": "Pecho y Tríceps",
              "ejercicios": [
                {"nombre": "Press de Banca", "series": 4, "repeticiones": "10"}
              ]
            }
          ]
        },
        {
          "nombre": "DÍA 2: Espalda y Bíceps (IA)",
          "descripcion": "Rutina adaptada a tus datos",
          "planificacion": [
            {
              "dia": "Ejercicios de la sesión",
              "musculo": "Espalda y Bíceps",
              "ejercicios": [
                {"nombre": "Dominadas", "series": 4, "repeticiones": "8"}
              ]
            }
          ]
        }
      ]
      
      Genera exactamente tantas rutinas independientes en el array como indique la Frecuencia ($_frequency días/semana).
      ''';

      // --- SISTEMA DE REINTENTOS PARA EVITAR EL ERROR 503 DE GOOGLE ---
      int maxReintentos = 3;
      int intentoActual = 0;
      String rawJson = '';
      bool exito = false;

      while (intentoActual < maxReintentos && !exito) {
        try {
          final response = await model.generateContent([Content.text(prompt)]);
          rawJson = response.text ?? '';
          exito = true; // Si llega aquí, no hubo error 503
        } catch (e) {
          intentoActual++;
          if (e.toString().contains('503') && intentoActual < maxReintentos) {
            print(
                "Google está saturado (Error 503). Reintentando en 3 segundos... (Intento $intentoActual)");
            await Future.delayed(const Duration(
                seconds: 3)); // Espera 3 segundos y vuelve a probar
          } else {
            rethrow; // Si es otro error distinto al 503, lo lanza normalmente
          }
        }
      }
      // ----------------------------------------------------------------

      rawJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();
      if (rawJson.isEmpty) throw Exception("La respuesta de la IA está vacía.");

      List<dynamic> rutinasGeneradas = jsonDecode(rawJson);

      for (var rutina in rutinasGeneradas) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('rutinas')
            .add({
          'rutina_json': jsonEncode(rutina),
          'fecha_creacion': FieldValue.serverTimestamp(),
          'activa': true,
          'es_ia': true, //
        });
      }

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("ERROR IA DETALLADO: $e");

      if (mounted) {
        if (e.toString().contains('503')) {
          _mostrarAviso(
              "Los servidores de IA están muy ocupados. Por favor, inténtalo de nuevo en unos minutos.");
        } else {
          _mostrarAviso("Error conectando con la IA. Por favor, reintenta.");
        }
        setState(() => _isGenerating = false);
        _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _injuryDetailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/images/gym_bg_registro.jpg'),
                      fit: BoxFit.cover))),
          Container(color: Colors.black.withOpacity(0.8)),
          if (_currentStep < 5)
            Positioned(
                top: 50,
                left: 20,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: _previousStep)),
          SafeArea(
            child: Column(
              children: [
                if (_currentStep < 5) _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int page) =>
                        setState(() => _currentStep = page),
                    children: [
                      _stepGender(),
                      _stepGoal(),
                      _stepPhysical(),
                      _stepFrequency(),
                      _stepInjury(),
                      _stepFinal(),
                    ],
                  ),
                ),
                if (!_isGenerating) _buildBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Image.asset('assets/images/logo_kilo.png', height: 60),
          const SizedBox(height: 5),
          const Text('KI-LO',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, bottom: 40),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          child: Text(_currentStep == 5 ? 'Ir a mi Home' : 'Continuar',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _stepGender() {
    return _buildStepLayout(
        title: 'Selecciona tu género',
        content: Column(children: [
          _buildSelectionCard('Hombre', _gender == 'Hombre',
              () => setState(() => _gender = 'Hombre')),
          const SizedBox(height: 15),
          _buildSelectionCard('Mujer', _gender == 'Mujer',
              () => setState(() => _gender = 'Mujer'))
        ]));
  }

  Widget _stepGoal() {
    return _buildStepLayout(
        title: '¿Cuál es tu objetivo?',
        content: Column(children: [
          _buildSelectionCard('Perder grasa', _goal == 'Perder grasa',
              () => setState(() => _goal = 'Perder grasa')),
          const SizedBox(height: 10),
          _buildSelectionCard(
              'Ganar masa muscular',
              _goal == 'Ganar masa muscular',
              () => setState(() => _goal = 'Ganar masa muscular')),
          const SizedBox(height: 10),
          _buildSelectionCard('Ganar fuerza', _goal == 'Ganar fuerza',
              () => setState(() => _goal = 'Ganar fuerza')),
          const SizedBox(height: 10),
          _buildSelectionCard(
              'Mejorar resistencia',
              _goal == 'Mejorar resistencia',
              () => setState(() => _goal = 'Mejorar resistencia'))
        ]));
  }

  Widget _stepPhysical() {
    return _buildStepLayout(
        title: 'Tus parámetros físicos',
        content: Column(children: [
          _buildInputField('Edad (años)', _ageController, TextInputType.number),
          const SizedBox(height: 15),
          _buildInputField('Peso (kg)', _weightController,
              const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 15),
          _buildInputField(
              'Altura (cm)', _heightController, TextInputType.number)
        ]));
  }

  Widget _stepFrequency() {
    return _buildStepLayout(
        title: '¿Frecuencia de entrenamiento?',
        content: Column(children: [
          _buildSelectionCard('2 - 3 días a la semana', _frequency == '2-3',
              () => setState(() => _frequency = '2-3')),
          const SizedBox(height: 10),
          _buildSelectionCard('3 - 4 días a la semana', _frequency == '3-4',
              () => setState(() => _frequency = '3-4')),
          const SizedBox(height: 10),
          _buildSelectionCard('5 - 6 días a la semana', _frequency == '5-6',
              () => setState(() => _frequency = '5-6'))
        ]));
  }

  Widget _stepInjury() {
    return _buildStepLayout(
        title: '¿Alguna lesión o limitación?',
        content: Column(children: [
          _buildInputField('Escríbelo aquí (ej: rodilla)',
              _injuryDetailController, TextInputType.text),
          const SizedBox(height: 15),
          _buildSelectionCard('No tengo ninguna lesión', _injury == 'none', () {
            setState(() {
              _injury = 'none';
              _injuryDetailController.clear();
            });
          })
        ]));
  }

  Widget _stepFinal() {
    return _buildStepLayout(
        title: _isGenerating
            ? 'KI-LO está creando tu plan...'
            : '¡Aquí está tu rutina!',
        content: Column(children: [
          if (_isGenerating) ...[
            const CircularProgressIndicator(color: Colors.red, strokeWidth: 4),
            const SizedBox(height: 30),
            const Text(
                'Analizando tus métricas y objetivos mediante Inteligencia Artificial...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16))
          ] else ...[
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text('Tu plan personalizado está listo para ser ejecutado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16))
          ]
        ]));
  }

  Widget _buildStepLayout({required String title, required Widget content}) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          content
        ]));
  }

  Widget _buildSelectionCard(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border:
                  isSelected ? Border.all(color: Colors.red, width: 3) : null),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16))),
    );
  }

  Widget _buildInputField(
      String hint, TextEditingController controller, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      onChanged: (val) {
        if (hint.contains('Escríbelo'))
          setState(() => _injury = val.isEmpty ? null : 'custom');
      },
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none)),
    );
  }
}
