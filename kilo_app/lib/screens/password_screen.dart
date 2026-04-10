import 'package:flutter/material.dart';
import 'questionnaire_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordScreen extends StatefulWidget {
  final String email;
  const PasswordScreen({super.key, required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN DE REGISTRO ESTRICTO ---
  Future<void> _registrarEstricto() async {
    String p1 = _passController.text.trim();
    String p2 = _confirmPassController.text.trim();

    if (p1.isEmpty || p2.isEmpty) return _avisar("Rellena ambos campos");
    if (p1 != p2) return _avisar("Las contraseñas no coinciden");
    if (p1.length < 8) return _avisar("Mínimo 8 caracteres");

    setState(() => _isLoading = true);

    try {
      print("--- INICIANDO REGISTRO ---");
      print("Email a registrar: ${widget.email.trim()}");

      // PASO 1: CREAR CUENTA
      print("Paso 1: Llamando a Firebase Auth...");
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: widget.email.trim(),
            password: p1,
          );
      print("¡Éxito Paso 1! Cuenta creada. UID: ${userCred.user!.uid}");

      // PASO 2: GUARDAR EN FIRESTORE
      print("Paso 2: Guardando datos en Firestore...");
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCred.user!.uid)
          .set({
            'email': widget.email.trim(),
            'racha': 0,
            'fecha': DateTime.now(),
          });
      print("¡Éxito Paso 2! Datos guardados en Firestore.");

      // PASO 3: NAVEGAR
      print("Paso 3: Navegando al cuestionario...");
      if (mounted) {
        Navigator.pushReplacement(
          // Usamos pushReplacement para que no pueda volver atrás
          context,
          MaterialPageRoute(builder: (context) => const QuestionnaireScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print(">>> ERROR DE FIREBASE AUTH: ${e.code}");
      if (e.code == 'email-already-in-use') {
        _avisar("ESTE CORREO YA EXISTE. NO PUEDES REGISTRARTE OTRA VEZ.");
      } else if (e.code == 'invalid-email') {
        _avisar("Formato de correo no válido.");
      } else {
        _avisar("Error de registro: ${e.message}");
      }
    } catch (e) {
      print(">>> ERROR GENERAL: $e");
      _avisar("Falló la conexión o la base de datos.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
      print("--- FIN DEL INTENTO DE REGISTRO ---");
    }
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. IMAGEN DE FONDO
          Positioned.fill(
            child: Image.asset(
              'assets/images/gym_bg.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.6),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // 2. CONTENIDO FORMULARIO
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Image.asset('assets/images/logo_kilo.png', height: 80),
                  const Text(
                    'KI-LO',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    'Registro de cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 30),

                  _campoTexto("Contraseña", _passController),
                  const SizedBox(height: 15),
                  _campoTexto("Confirmar contraseña", _confirmPassController),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registrarEstricto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Finalizar Registro",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. BOTÓN VOLVER
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoTexto(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: _isObscured,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility_off : Icons.visibility,
            color: Colors.black54,
          ),
          onPressed: () => setState(() => _isObscured = !_isObscured),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
