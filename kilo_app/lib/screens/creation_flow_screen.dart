import 'package:flutter/material.dart';
import 'home_screen.dart';

class CreationFlowScreen extends StatefulWidget {
  const CreationFlowScreen({super.key});

  @override
  State<CreationFlowScreen> createState() => _CreationFlowScreenState();
}

class _CreationFlowScreenState extends State<CreationFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // --- VARIABLES PARA GUARDAR LA INFO ---
  String? _gender;
  String? _goal;
  String? _frequency;
  String? _injury;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _injuryDetailController = TextEditingController();

  // Función para avanzar
  void _nextStep() {
    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Al finalizar los 6 pasos, vamos a la Home y limpiamos el historial
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  // Función para retroceder
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Si estamos en el primer paso, cerramos este flujo y volvemos al cuestionario
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
          // 1. IMAGEN DE FONDO
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/gym_bg_registro.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Capa oscura para resaltar el texto
          Container(color: Colors.black.withOpacity(0.8)),

          // 2. FLECHA PARA VOLVER ATRÁS
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: _previousStep,
            ),
          ),

          // 3. CONTENIDO DEL FLUJO
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Evita deslizar con el dedo
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
                _buildBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE LA ESTRUCTURA ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Image.asset('assets/images/logo_kilo.png', height: 60),
          const SizedBox(height: 5),
          const Text(
            'KI-LO',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
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
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            _currentStep == 5 ? 'Empezar a entrenar' : 'Continuar',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --- PASOS DEL CUESTIONARIO ---

  Widget _stepGender() {
    return _buildStepLayout(
      title: 'Selecciona tu género',
      content: Column(
        children: [
          _buildSelectionCard(
            'Hombre',
            _gender == 'Hombre',
            () => setState(() => _gender = 'Hombre'),
          ),
          const SizedBox(height: 15),
          _buildSelectionCard(
            'Mujer',
            _gender == 'Mujer',
            () => setState(() => _gender = 'Mujer'),
          ),
        ],
      ),
    );
  }

  Widget _stepGoal() {
    return _buildStepLayout(
      title: '¿Cuál es tu objetivo?',
      content: Column(
        children: [
          _buildSelectionCard(
            'Perder grasa',
            _goal == 'Perder grasa',
            () => setState(() => _goal = 'Perder grasa'),
          ),
          const SizedBox(height: 10),
          _buildSelectionCard(
            'Ganar masa muscular',
            _goal == 'Ganar masa muscular',
            () => setState(() => _goal = 'Ganar masa muscular'),
          ),
          const SizedBox(height: 10),
          _buildSelectionCard(
            'Ganar fuerza',
            _goal == 'Ganar fuerza',
            () => setState(() => _goal = 'Ganar fuerza'),
          ),
          const SizedBox(height: 10),
          _buildSelectionCard(
            'Mejorar mi resistencia cardiovascular',
            _goal == 'Mejorar resistencia',
            () => setState(() => _goal = 'Mejorar resistencia'),
          ),
        ],
      ),
    );
  }

  Widget _stepPhysical() {
    return _buildStepLayout(
      title: 'Rellena con tus parámetros físicos',
      content: Column(
        children: [
          _buildInputField(
            'Introduce tu edad',
            _ageController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildInputField(
            'Introduce tu peso en kg',
            _weightController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildInputField(
            'Introduce tu altura en cm',
            _heightController,
            TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _stepFrequency() {
    return _buildStepLayout(
      title: '¿Con qué frecuencia quieres entrenar?',
      content: Column(
        children: [
          _buildSelectionCard(
            '2 - 3 días a la semana',
            _frequency == '2-3',
            () => setState(() => _frequency = '2-3'),
          ),
          const SizedBox(height: 10),
          _buildSelectionCard(
            '3 - 4 días a la semana',
            _frequency == '3-4',
            () => setState(() => _frequency = '3-4'),
          ),
          const SizedBox(height: 10),
          _buildSelectionCard(
            '5 - 6 días a la semana',
            _frequency == '5-6',
            () => setState(() => _frequency = '5-6'),
          ),
        ],
      ),
    );
  }

  Widget _stepInjury() {
    return _buildStepLayout(
      title: '¿Tienes alguna lesión, dolor crónico o limitación física?',
      content: Column(
        children: [
          _buildInputField(
            'Escríbelo aquí (ej: dolor de rodilla, lesión de hombro, etc.)',
            _injuryDetailController,
            TextInputType.text,
          ),
          const SizedBox(height: 15),
          _buildSelectionCard(
            'No tengo ninguna lesión',
            _injury == 'none',
            () => setState(() => _injury = 'none'),
          ),
        ],
      ),
    );
  }

  Widget _stepFinal() {
    return _buildStepLayout(
      title: '¡Aquí está tu rutina!',
      content: const Column(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
          SizedBox(height: 20),
          Text(
            'Tu plan personalizado está listo para ser ejecutado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- COMPONENTES REUTILIZABLES ---

  Widget _buildStepLayout({required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          content,
        ],
      ),
    );
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
          border: isSelected ? Border.all(color: Colors.red, width: 3) : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller,
    TextInputType type,
  ) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
