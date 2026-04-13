import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    if (_currentStep == 0 && _gender == null) {
      return _mostrarAviso("Selecciona tu género");
    }
    if (_currentStep == 1 && _goal == null) {
      return _mostrarAviso("Selecciona tu objetivo");
    }
    if (_currentStep == 2) {
      if (_ageController.text.isEmpty ||
          _weightController.text.isEmpty ||
          _heightController.text.isEmpty) {
        return _mostrarAviso("Rellena todas tus medidas");
      }
    }
    if (_currentStep == 3 && _frequency == null) {
      return _mostrarAviso("Selecciona una frecuencia");
    }
    if (_currentStep == 4) {
      if (_injury == null && _injuryDetailController.text.isEmpty) {
        return _mostrarAviso("Indica si tienes alguna lesión");
      }
    }

    if (_currentStep == 4) {
      _generarRutinaYGuardar();
    } else if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: Colors.red),
    );
  }

  // --- LÓGICA DE IA Y PERSISTENCIA (Sustituido y Corregido) ---
  Future<void> _generarRutinaYGuardar() async {
    setState(() {
      _isGenerating = true;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      double peso =
          double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
      int altura = int.tryParse(_heightController.text) ?? 0;
      int edad = int.tryParse(_ageController.text) ?? 0;
      String lesionFinal =
          _injury == 'none' ? 'Ninguna' : _injuryDetailController.text;

      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) throw Exception('API Key no encontrada');

      // Endpoint estable v1
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey');

      final prompt = '''
      Actúa como un entrenador personal experto. Genera una rutina de gimnasio basada en estos datos:
      Género: $_gender, Edad: $edad, Peso: $peso kg, Altura: $altura cm, Objetivo: $_goal, Frecuencia: $_frequency, Lesiones: $lesionFinal.

      IMPORTANTE: Responde ÚNICAMENTE con un objeto JSON válido. No incluyas texto explicativo, ni introducciones, ni etiquetas markdown de código.
      
      Estructura requerida:
      {
        "nombre": "Nombre de la rutina",
        "descripcion": "Breve descripción",
        "planificacion": [
          {
            "dia": "Día 1",
            "musculo": "Grupo muscular",
            "ejercicios": [{"nombre": "Nombre ej", "series": 4, "repeticiones": "12"}]
          }
        ]
      }
      ''';

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
        }
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('La IA no devolvió candidatos');
        }

        String rawJson = data['candidates'][0]['content']['parts'][0]['text'];

        // Limpieza de seguridad por si la IA usa bloques de código
        rawJson =
            rawJson.replaceAll('```json', '').replaceAll('```', '').trim();

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('rutinas')
            .add({
          'rutina_json': rawJson,
          'fecha_creacion': FieldValue.serverTimestamp(),
          'activa': true,
        });

        if (mounted) {
          setState(() => _isGenerating = false);
        }
      } else {
        print("Error de Google (Cuerpo): ${response.body}");
        throw Exception('Error API: ${response.statusCode}');
      }
    } catch (e) {
      print("ERROR DETALLADO: $e");
      _mostrarAviso("Error al generar rutina. Revisa tu conexión.");
      if (mounted) {
        setState(() => _isGenerating = false);
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.8)),
          if (_currentStep < 5 && !_isGenerating)
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: _previousStep,
              ),
            ),
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

  // --- WIDGETS DE SOPORTE ---
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(_currentStep == 5 ? 'Ir a mi Home' : 'Continuar',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- PASOS DEL CUESTIONARIO ---
  Widget _stepGender() => _buildStepLayout(
      title: 'Selecciona tu género',
      content: Column(children: [
        _buildSelectionCard('Hombre', _gender == 'Hombre',
            () => setState(() => _gender = 'Hombre')),
        const SizedBox(height: 15),
        _buildSelectionCard('Mujer', _gender == 'Mujer',
            () => setState(() => _gender = 'Mujer'))
      ]));
  Widget _stepGoal() => _buildStepLayout(
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
  Widget _stepPhysical() => _buildStepLayout(
      title: 'Tus parámetros físicos',
      content: Column(children: [
        _buildInputField('Edad (años)', _ageController, TextInputType.number),
        const SizedBox(height: 15),
        _buildInputField('Peso (kg)', _weightController,
            const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 15),
        _buildInputField('Altura (cm)', _heightController, TextInputType.number)
      ]));
  Widget _stepFrequency() => _buildStepLayout(
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
  Widget _stepInjury() => _buildStepLayout(
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
  Widget _stepFinal() => _buildStepLayout(
      title:
          _isGenerating ? 'KI-LO está creando tu plan...' : '¡Rutina Generada!',
      content: Column(children: [
        if (_isGenerating) ...[
          const CircularProgressIndicator(color: Colors.red, strokeWidth: 4),
          const SizedBox(height: 30),
          const Text('Analizando tus métricas con IA...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16))
        ] else ...[
          const Icon(Icons.check_circle_outline,
              color: Colors.green, size: 100),
          const SizedBox(height: 20),
          const Text('Tu plan personalizado está listo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16))
        ]
      ]));

  Widget _buildStepLayout({required String title, required Widget content}) =>
      Padding(
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
  Widget _buildSelectionCard(
          String text, bool isSelected, VoidCallback onTap) =>
      InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: Colors.red, width: 3)
                      : null),
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16))));
  Widget _buildInputField(
          String hint, TextEditingController controller, TextInputType type) =>
      TextField(
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
                  borderSide: BorderSide.none)));
}
