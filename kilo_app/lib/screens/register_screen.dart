import 'package:flutter/material.dart';
import 'password_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. CREAMOS EL CONTROLADOR
  final TextEditingController _emailController = TextEditingController();

  // Es buena práctica limpiar los controladores al cerrar la pantalla
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          // 2. CAPA OSCURA
          Container(color: Colors.black.withOpacity(0.7)),

          // 3. CONTENIDO
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Image.asset('assets/images/logo_kilo.png', height: 90),
                    const SizedBox(height: 10),
                    const Text(
                      'KI-LO',
                      style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      'Crear una cuenta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Introduce tu correo electrónico para registrarte',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 40),

                    // 2. PASAMOS EL CONTROLADOR AL MÉTODO
                    _buildTextField('email@domain.com', _emailController),

                    const SizedBox(height: 25),

                    _buildMainButton(
                      'Continuar',
                      Colors.white,
                      Colors.black,
                      () {
                        // Ahora sí, extraemos el texto del controlador
                        String userEmail = _emailController.text;

                        if (userEmail.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PasswordScreen(email: userEmail),
                            ),
                          );
                        } else {
                          // Un pequeño aviso por si está vacío
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor, introduce un correo'),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 30),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white30)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            'o',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white30)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildSocialButton('Continuar con Google'),
                    const SizedBox(height: 15),
                    _buildSocialButton('Continuar con Apple'),
                    const SizedBox(height: 40),
                    const Text(
                      'Al hacer clic en continuar, aceptas nuestros Términos de Servicio y nuestra Política de Privacidad',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          // 4. FLECHA DE VOLVER
          Positioned(
            top: 50,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ACTUALIZADOS ---

  // Ahora recibe el controller como parámetro
  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType:
          TextInputType.emailAddress, // Mejoramos la experiencia del teclado
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
