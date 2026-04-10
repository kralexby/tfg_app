import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'home_screen.dart'; // <--- Asegúrate de tener este archivo creado

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // 1. CREAMOS LOS "CABLES" (Controladores)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // Es buena práctica limpiar los controladores al cerrar la pantalla
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // FONDO
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/gym_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.7)),

          // CONTENIDO
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  Image.asset('assets/images/logo_kilo.png', height: 100),
                  const SizedBox(height: 10), // Espacio entre logo y nombre
                  const Text(
                    'KI-LO',
                    style: TextStyle(
                      fontFamily: 'Ubuntu', // <--- AQUÍ USAMOS LA FUENTE
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4.0, // Para que quede más "premium"
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Bienvenido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Introduce tu correo electrónico o usuario para iniciar tu sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  const SizedBox(height: 40),

                  // 2. PASAMOS LOS CONTROLADORES A LOS TEXTFIELDS
                  _buildTextField('email@domain.com', _emailController),
                  const SizedBox(height: 15),
                  _buildTextField(
                    'password',
                    _passwordController,
                    isPassword: true,
                  ),

                  const SizedBox(height: 25),

                  // 3. BOTÓN INICIAR SESIÓN CON LÓGICA
                  _buildMainButton(
                    'Iniciar sesión',
                    Colors.white,
                    Colors.black,
                    () {
                      // Por ahora, solo comprobamos que no estén vacíos
                      if (_emailController.text.isNotEmpty &&
                          _passwordController.text.isNotEmpty) {
                        print("Email: ${_emailController.text}");
                        print("Pass: ${_passwordController.text}");

                        // NAVEGAMOS AL HOME
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      } else {
                        // Si están vacíos, mostramos un aviso rápido
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor, rellena todos los campos',
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                  // ... (resto de botones sociales y separador igual que antes) ...
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white30)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('o', style: TextStyle(color: Colors.white)),
                      ),
                      Expanded(child: Divider(color: Colors.white30)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSocialButton('Continuar con Google'),
                  const SizedBox(height: 15),
                  _buildSocialButton('Continuar con Apple'),
                  const SizedBox(height: 40),

                  const Text(
                    '¿Aún no eres miembro?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildMainButton(
                    'Registrarme',
                    Colors.white,
                    Colors.black,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGETS AUXILIARES ACTUALIZADOS PARA RECIBIR EL CONTROLADOR
  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller, // <--- Conectamos el controlador
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMainButton(
    String text,
    Color bg,
    Color textCol,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textCol,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }
}
