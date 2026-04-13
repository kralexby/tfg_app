import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'welcome_screen.dart';
import 'creation_flow_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- NAVEGACIÓN ---
  int _selectedTab = 0;

  // --- ESTADO DINÁMICO ---
  bool _isEditingProfile = false;
  String _userName = 'Cargando...';
  int _racha = 0;
  Color _accentColor = const Color(0xFF00FF66);

  // --- DATOS FÍSICOS ---
  double _peso = 0;
  int _altura = 0;
  int _edad = 0;

  // --- ESTADO DE RUTINAS E HISTORIAL ---
  List<Map<String, dynamic>> _misRutinas = [];
  Map<int, String> _historialMes = {};
  bool _cargandoRutina = true;

  // --- COLORES Y ESTILOS FIJOS ---
  static const Color backgroundColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF2C2C2E);
  static const Color inactiveDayColor = Color(0xFF4A4A4C);
  static const Color bottomNavColor = Color(0xFF141414);

  static const BorderRadius appCardRadius = BorderRadius.only(
    topLeft: Radius.circular(20.0),
    topRight: Radius.circular(4.0),
    bottomRight: Radius.circular(20.0),
    bottomLeft: Radius.circular(4.0),
  );

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarDatosDeEntrenamiento();
  }

  Future<void> _cargarDatosDeEntrenamiento() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot rutinasQuery = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('rutinas')
            .orderBy('fecha_creacion', descending: true)
            .get();

        List<Map<String, dynamic>> rutinasTemp = [];
        for (var doc in rutinasQuery.docs) {
          String jsonString = doc['rutina_json'];
          jsonString =
              jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
          Map<String, dynamic> rutinaDecoded = jsonDecode(jsonString);
          rutinaDecoded['id'] = doc.id;
          rutinasTemp.add(rutinaDecoded);
        }

        QuerySnapshot historialQuery = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('historial_entrenamientos')
            .get();

        Map<int, String> historialTemp = {};
        for (var doc in historialQuery.docs) {
          DateTime fecha = (doc['fecha'] as Timestamp).toDate();
          if (fecha.month == DateTime.now().month) {
            historialTemp[fecha.day] =
                doc['nombre_rutina'] ?? 'Rutina completada';
          }
        }

        if (mounted) {
          setState(() {
            _misRutinas = rutinasTemp;
            _historialMes = historialTemp;
            _cargandoRutina = false;
          });
        }
      } catch (e) {
        print("Error al cargar datos de entrenamiento: $e");
        if (mounted) setState(() => _cargandoRutina = false);
      }
    }
  }

  Future<void> _cargarDatosUsuario() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            if (data.containsKey('nombre') && data['nombre'] != null) {
              _userName = data['nombre'];
            } else {
              String email = data['email'] ?? 'Atleta';
              _userName = email.split('@').first;
            }
            _racha = data['racha'] ?? 0;
            if (data.containsKey('color_avatar') &&
                data['color_avatar'] != null) {
              _accentColor = Color(data['color_avatar']);
            }
            _peso = (data['peso'] ?? 0).toDouble();
            _altura = data['altura'] ?? 0;
            _edad = data['edad'] ?? 0;
          });
        }
      } catch (e) {
        print("Error al cargar datos: $e");
        if (mounted) setState(() => _userName = 'Atleta');
      }
    }
  }

  Future<void> _eliminarRutina(String id) async {
    bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: cardColor,
                title: const Text("Eliminar rutina",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                content: const Text(
                    "¿Estás seguro de que deseas eliminar esta rutina de forma permanente?",
                    style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar",
                          style: TextStyle(color: Colors.white54))),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Eliminar",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold))),
                ]));

    if (confirmar == true) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('rutinas')
            .doc(id)
            .delete();
        _cargarDatosDeEntrenamiento();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rutina eliminada correctamente')));
      }
    }
  }

  void _editarRutina(Map<String, dynamic> rutina) {
    List<Map<String, dynamic>> exercisesToEdit = [];
    List dias = rutina['planificacion'] ?? [];
    for (var dia in dias) {
      for (var ej in (dia['ejercicios'] ?? [])) {
        exercisesToEdit.add({
          "nombre": ej['nombre'],
          "series": ej['series'],
          "repeticiones": ej['repeticiones']
        });
      }
    }

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RoutineReviewScreen(
                  exercises: exercisesToEdit,
                  accentColor: _accentColor,
                  routineId: rutina['id'],
                  initialName: rutina['nombre'],
                ))).then((_) => _cargarDatosDeEntrenamiento());
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado'
    ];
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  double _calcularTMB() {
    if (_peso == 0 || _altura == 0 || _edad == 0) return 0;
    return 88.362 + (13.397 * _peso) + (4.799 * _altura) - (5.677 * _edad);
  }

  void _changeName() {
    TextEditingController controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title:
            const Text('Cambiar nombre', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _accentColor)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _accentColor, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                String nuevoNombre = controller.text.trim();
                setState(() => _userName = nuevoNombre);
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(user.uid)
                      .update({'nombre': nuevoNombre});
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text('GUARDAR',
                style: TextStyle(
                    color: _accentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _changeColor() {
    final colors = [
      const Color(0xFF00FF66),
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.cyan,
      Colors.white,
      Colors.yellow,
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Color de Perfil',
            style: TextStyle(color: Colors.white)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: colors
              .map((c) => GestureDetector(
                    onTap: () async {
                      setState(() => _accentColor = c);
                      Navigator.pop(context);
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(user.uid)
                            .update({'color_avatar': c.value});
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: c,
                      radius: 22,
                      child: _accentColor == c
                          ? const Icon(Icons.check, color: Colors.black)
                          : null,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _editarDatosFisicos() {
    TextEditingController pesoCtrl =
        TextEditingController(text: _peso > 0 ? _peso.toString() : '');
    TextEditingController alturaCtrl =
        TextEditingController(text: _altura > 0 ? _altura.toString() : '');
    TextEditingController edadCtrl =
        TextEditingController(text: _edad > 0 ? _edad.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Tus Medidas",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: pesoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Peso (kg)",
                    labelStyle: const TextStyle(color: Colors.white54),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _accentColor)),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: alturaCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Altura (cm)",
                    labelStyle: const TextStyle(color: Colors.white54),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _accentColor)),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: edadCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Edad (años)",
                    labelStyle: const TextStyle(color: Colors.white54),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _accentColor)),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      double p =
                          double.tryParse(pesoCtrl.text.replaceAll(',', '.')) ??
                              0;
                      int a = int.tryParse(alturaCtrl.text) ?? 0;
                      int e = int.tryParse(edadCtrl.text) ?? 0;
                      if (p > 0 && a > 0 && e > 0) {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(user.uid)
                              .update({'peso': p, 'altura': a, 'edad': e});
                        }
                        setState(() {
                          _peso = p;
                          _altura = a;
                          _edad = e;
                        });
                        if (mounted) Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Por favor, introduce todos los valores correctamente')));
                      }
                    },
                    child: const Text("GUARDAR CAMBIOS",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Función de $feature próximamente'),
          behavior: SnackBarBehavior.floating),
    );
  }

  // --- NUEVAS VENTANAS LEGALES Y DE INFORMACIÓN ---
  void _showAboutUs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_kilo.png', height: 80),
            const SizedBox(height: 20),
            const Text("KI-LO",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "KI-LO es tu compañero de entrenamiento definitivo. Combina la Inteligencia Artificial con tu esfuerzo diario para crear rutinas personalizadas, hacer seguimiento de tus marcas y llevar tu físico al siguiente nivel.\n\n¡No hay excusas, solo resultados!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text("Cerrar",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showLegal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Legal y Privacidad",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            "Términos y Condiciones de Uso\n\n"
            "1. Privacidad de Datos:\n"
            "En KI-LO tu privacidad es primordial. Los datos físicos y métricas que introduces se usan exclusivamente para personalizar tus rutinas mediante nuestra IA y mostrar tu progreso. No vendemos ni compartimos tu información personal con terceros.\n\n"
            "2. Responsabilidad Física:\n"
            "Las rutinas generadas son recomendaciones. Consulta a un médico o especialista antes de comenzar cualquier actividad física de alta intensidad para evitar lesiones. KI-LO no se hace responsable por lesiones derivadas del mal uso de los ejercicios.\n\n"
            "3. Almacenamiento y Cuenta:\n"
            "Tus progresos e historial se almacenan de forma segura en la nube. Eres responsable de mantener la seguridad de tu contraseña. Puedes solicitar la eliminación de tu cuenta y datos en cualquier momento.\n\n"
            "Al usar la aplicación KI-LO, aceptas estas políticas.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cerrar",
                style: TextStyle(
                    color: _accentColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      IndexedStack(
                        index: _selectedTab,
                        children: [
                          _buildHomeTab(),
                          _buildTrainingTab(),
                          _buildProfileTab(),
                          _buildStatsTab(),
                        ],
                      ),
                      _buildProfileShutter(constraints.maxHeight),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.only(right: 20, top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.only(
          topRight: const Radius.circular(4.0),
          bottomRight: Radius.circular(_isEditingProfile ? 0.0 : 20.0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
              radius: 24,
              backgroundColor: _accentColor,
              child: const Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $_userName',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(_getFormattedDate(),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isEditingProfile ? Icons.close : Icons.edit_square,
                color: Colors.white),
            onPressed: () =>
                setState(() => _isEditingProfile = !_isEditingProfile),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileShutter(double maxHeight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 20),
      height: _isEditingProfile ? 320 : 0.0,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileMenuItem('Cambiar color Avatar', true, _changeColor),
            _buildProfileMenuItem('Cambiar Nombre', true, _changeName),
            _buildProfileMenuItem(
                'Cambiar correo', true, () => _showSoon('correo')),
            _buildProfileMenuItem(
                'Cambiar contraseña', false, () => _showSoon('contraseña')),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(String title, bool divider, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.black,
            border: divider
                ? const Border(bottom: BorderSide(color: cardColor, width: 2))
                : null),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildHomeTab() {
    String tituloRutina = _misRutinas.isNotEmpty
        ? _misRutinas.first['nombre']
        : 'Entrenamiento de hoy';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          _buildSectionTitle('¡Empieza tu rutina de hoy!'),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 1),
            child: _buildRoutineCard(tituloRutina,
                'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop'),
          ),
          const SizedBox(height: 30),
          _buildSectionTitle('Racha actual: 🔥 $_racha días'),
          _buildStreakCalendar(),
          const SizedBox(height: 30),
          _buildSectionTitle('Recomendaciones de IA'),
          GestureDetector(
            onTap: () {
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreationFlowScreen()))
                  .then((_) => _cargarDatosDeEntrenamiento());
            },
            child: _buildRoutineCard('Crear rutina con ayuda de la IA',
                'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=1470&auto=format&fit=crop',
                isAI: true),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildTrainingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Mis Rutinas",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.add_circle, color: _accentColor, size: 36),
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ExerciseBankScreen(
                                  accentColor: _accentColor)))
                      .then((_) => _cargarDatosDeEntrenamiento());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _cargandoRutina
              ? const Center(child: CircularProgressIndicator())
              : _misRutinas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center,
                              color: _accentColor, size: 80),
                          const SizedBox(height: 20),
                          const Text("AÚN NO TIENES RUTINAS",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                                "Toca el botón '+' arriba para añadir ejercicios.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _misRutinas.length,
                      itemBuilder: (context, index) {
                        final rutina = _misRutinas[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: _accentColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                          rutina['nombre'] ?? "Mi Rutina",
                                          style: TextStyle(
                                              color: _accentColor,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          color: Colors.white),
                                      color: const Color(0xFF1E1E1E),
                                      onSelected: (value) {
                                        if (value == 'edit')
                                          _editarRutina(rutina);
                                        if (value == 'delete')
                                          _eliminarRutina(rutina['id']);
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                            value: 'edit',
                                            child: Text("Editar",
                                                style: TextStyle(
                                                    color: Colors.white))),
                                        const PopupMenuItem(
                                            value: 'delete',
                                            child: Text("Eliminar",
                                                style: TextStyle(
                                                    color: Colors.redAccent))),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              ...(rutina['planificacion'] as List? ?? [])
                                  .map((dia) {
                                bool esUnSoloDia =
                                    (rutina['planificacion'] as List).length ==
                                        1;
                                String titulo = esUnSoloDia
                                    ? "Ejercicios de la sesión"
                                    : (dia['dia'] ?? '');

                                return ExpansionTile(
                                  title: Text(titulo,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  subtitle: esUnSoloDia
                                      ? null
                                      : Text(
                                          "Músculo: ${dia['musculo'] ?? 'Varios'}",
                                          style:
                                              TextStyle(color: _accentColor)),
                                  iconColor: _accentColor,
                                  collapsedIconColor: Colors.white,
                                  initiallyExpanded: esUnSoloDia,
                                  children: (dia['ejercicios'] as List? ?? [])
                                      .map(
                                        (ej) => ListTile(
                                          title: Text(ej['nombre'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                          trailing: Text(
                                              "${ej['series']} x ${ej['repeticiones']}",
                                              style: const TextStyle(
                                                  color: Colors.white70)),
                                        ),
                                      )
                                      .toList(),
                                );
                              }).toList(),
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  ActiveWorkoutScreen(
                                                      rutina: rutina,
                                                      accentColor:
                                                          _accentColor))).then(
                                          (_) => _cargarDatosDeEntrenamiento());
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: _accentColor,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                    child: const Text("¡ENTRENAR!",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2)),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    double tmb = _calcularTMB();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildSectionTitle('Tus Datos Físicos'),
          _buildHealthDataCard("Peso Actual", _peso > 0 ? "$_peso kg" : "-- kg",
              Icons.monitor_weight),
          const SizedBox(height: 15),
          _buildHealthDataCard(
              "Altura", _altura > 0 ? "$_altura cm" : "-- cm", Icons.height),
          const SizedBox(height: 15),
          _buildHealthDataCard(
              "Tasa Metabólica Basal",
              tmb > 0 ? "${tmb.toStringAsFixed(0)} kcal" : "-- kcal",
              Icons.local_fire_department),
          const SizedBox(height: 30),
          Center(
            child: TextButton.icon(
              onPressed: _editarDatosFisicos,
              icon: Icon(Icons.edit, color: _accentColor),
              label: Text("Editar mis medidas",
                  style: TextStyle(color: _accentColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDataCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.black26, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _accentColor, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 5),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph, color: _accentColor, size: 80),
          const SizedBox(height: 20),
          const Text("PROGRESO",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          Container(
            margin: const EdgeInsets.all(20),
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
                color: cardColor, borderRadius: BorderRadius.circular(15)),
            child: const Center(
                child: Text("Gráfica de evolución próximamente\n(Ej: fl_chart)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54))),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: _accentColor),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(String title, String url, {bool isAI = false}) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: appCardRadius,
        image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4), BlendMode.darken)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: () {
              if (isAI) {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CreationFlowScreen()))
                    .then((_) => _cargarDatosDeEntrenamiento());
              } else {
                setState(() => _selectedTab = 1);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 2),
            child: Text(isAI ? 'Crear ahora' : 'Empezar',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration:
          const BoxDecoration(color: cardColor, borderRadius: appCardRadius),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayHeader('Su'),
              _DayHeader('Mo'),
              _DayHeader('Tu'),
              _DayHeader('We'),
              _DayHeader('Th'),
              _DayHeader('Fr'),
              _DayHeader('Sa')
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarWeek(['', '1', '2', '3', '4', '5', '6']),
          const SizedBox(height: 12),
          _buildCalendarWeek(['7', '8', '9', '10', '11', '12', '13']),
          const SizedBox(height: 12),
          _buildCalendarWeek(['14', '15', '16', '17', '18', '19', '20']),
        ],
      ),
    );
  }

  Widget _buildCalendarWeek(List<String> days) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        if (d.isEmpty) return const SizedBox(width: 36);
        int dayNum = int.tryParse(d) ?? 0;
        bool isTrained = _historialMes.containsKey(dayNum);
        bool isToday = dayNum == DateTime.now().day;

        return GestureDetector(
          onTap: () {
            if (isTrained) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Día $d: ${_historialMes[dayNum]}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: _accentColor,
                duration: const Duration(seconds: 2),
              ));
            }
          },
          child: _buildDay(d,
              bg: isTrained ? _accentColor : null,
              txt: isTrained ? Colors.black : Colors.white,
              border: isToday),
        );
      }).toList(),
    );
  }

  Widget _buildDay(String d, {Color? bg, Color? txt, bool border = false}) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg ?? Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: _accentColor, width: 1.5) : null,
      ),
      child: Text(d,
          style: TextStyle(
              color: txt ?? Colors.white,
              fontWeight: bg != null ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
          color: bottomNavColor,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavIcon(Icons.home_outlined, 0),
            _buildNavIcon(Icons.person_outline, 2),
            GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color:
                        _selectedTab == 1 ? Colors.white10 : Colors.transparent,
                    borderRadius: BorderRadius.circular(15)),
                child: Image.asset('assets/images/logo_kilo.png',
                    height: 35, color: _selectedTab == 1 ? _accentColor : null),
              ),
            ),
            _buildNavIcon(Icons.bar_chart, 3),
            IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                onPressed: () => _showSettingsMenu()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _selectedTab == index;
    return IconButton(
        icon: Icon(icon,
            color: isSelected ? _accentColor : Colors.white, size: 30),
        onPressed: () => setState(() => _selectedTab = index));
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
                alignment: Alignment.topRight,
                child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context))),
            _buildSettingsItem('Conócenos', () {
              Navigator.pop(context); // Cierra el menú inferior
              _showAboutUs();
            }),
            _buildSettingsItem('Legal y Privacidad', () {
              Navigator.pop(context); // Cierra el menú inferior
              _showLegal();
            }),
            _buildSettingsItem('Cerrar sesión', () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (c) => const WelcomeScreen()),
                    (r) => false);
              }
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String t, VoidCallback o,
      {bool isDestructive = false}) {
    return InkWell(
      onTap: o,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(8)),
        child: Text(t,
            style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;
  const _DayHeader(this.day);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 36,
        child: Text(day,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12)));
  }
}

// =========================================================================
// BANCO DE EJERCICIOS CON FILTROS AVANZADOS Y SETS/REPS
// =========================================================================
class ExerciseBankScreen extends StatefulWidget {
  final Color accentColor;
  const ExerciseBankScreen({super.key, required this.accentColor});

  @override
  State<ExerciseBankScreen> createState() => _ExerciseBankScreenState();
}

class _ExerciseBankScreenState extends State<ExerciseBankScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedMusculo = "Todos";
  String _selectedMaterial = "Todos";

  List<Map<String, dynamic>> _selectedExercises = [];

  final List<Map<String, String>> _allExercises = [
    {"nombre": "Press de Banca", "musculo": "Pecho", "material": "Barra"},
    {
      "nombre": "Aperturas Inclinadas",
      "musculo": "Pecho",
      "material": "Mancuernas"
    },
    {"nombre": "Flexiones", "musculo": "Pecho", "material": "Peso Corporal"},
    {"nombre": "Cruce de Poleas", "musculo": "Pecho", "material": "Polea"},
    {"nombre": "Sentadilla Libre", "musculo": "Piernas", "material": "Barra"},
    {"nombre": "Prensa", "musculo": "Piernas", "material": "Máquina"},
    {
      "nombre": "Sentadilla Búlgara",
      "musculo": "Piernas",
      "material": "Mancuernas"
    },
    {
      "nombre": "Kettlebell Swing",
      "musculo": "Piernas",
      "material": "Kettlebell"
    },
    {
      "nombre": "Extensiones con Goma",
      "musculo": "Piernas",
      "material": "Gomas Elásticas"
    },
    {"nombre": "Dominadas", "musculo": "Espalda", "material": "Peso Corporal"},
    {"nombre": "Remo con Barra", "musculo": "Espalda", "material": "Barra"},
    {"nombre": "Jalón al Pecho", "musculo": "Espalda", "material": "Polea"},
    {"nombre": "Remo Gironda", "musculo": "Espalda", "material": "Polea"},
    {
      "nombre": "Curl de Bíceps Alterno",
      "musculo": "Brazos",
      "material": "Mancuernas"
    },
    {"nombre": "Curl Martillo", "musculo": "Brazos", "material": "Mancuernas"},
    {
      "nombre": "Extensión de Tríceps",
      "musculo": "Brazos",
      "material": "Polea"
    },
    {"nombre": "Press Militar", "musculo": "Hombros", "material": "Barra"},
    {
      "nombre": "Elevaciones Laterales",
      "musculo": "Hombros",
      "material": "Mancuernas"
    },
    {"nombre": "Face Pull", "musculo": "Hombros", "material": "Polea"},
    {
      "nombre": "Crunch Abdominal",
      "musculo": "Core",
      "material": "Peso Corporal"
    },
    {"nombre": "Plancha", "musculo": "Core", "material": "Peso Corporal"},
    {
      "nombre": "Elevación de Piernas Colgado",
      "musculo": "Core",
      "material": "Peso Corporal"
    },
  ];

  final List<String> _musculos = [
    "Todos",
    "Pecho",
    "Espalda",
    "Piernas",
    "Hombros",
    "Brazos",
    "Core"
  ];
  final List<String> _materiales = [
    "Todos",
    "Peso Corporal",
    "Barra",
    "Mancuernas",
    "Polea",
    "Máquina",
    "Kettlebell",
    "Gomas Elásticas"
  ];

  List<Map<String, String>> get _filteredExercises {
    return _allExercises.where((ej) {
      final matchesSearch =
          ej['nombre']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMusculo =
          _selectedMusculo == "Todos" || ej['musculo'] == _selectedMusculo;
      final matchesMaterial =
          _selectedMaterial == "Todos" || ej['material'] == _selectedMaterial;
      return matchesSearch && matchesMusculo && matchesMaterial;
    }).toList();
  }

  void _addExercise(Map<String, String> exercise) {
    TextEditingController setsCtrl = TextEditingController(text: "3");
    TextEditingController repsCtrl = TextEditingController(text: "10");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(exercise['nombre']!,
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: setsCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    labelText: "Series",
                    labelStyle: TextStyle(color: widget.accentColor))),
            const SizedBox(height: 10),
            TextField(
                controller: repsCtrl,
                keyboardType: TextInputType.text,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    labelText: "Repeticiones (Ej: 10-12)",
                    labelStyle: TextStyle(color: widget.accentColor))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar",
                  style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedExercises.add({
                  "nombre": exercise['nombre'],
                  "series": int.tryParse(setsCtrl.text) ?? 3,
                  "repeticiones": repsCtrl.text
                });
              });
              Navigator.pop(ctx);
            },
            child: Text("AÑADIR",
                style: TextStyle(
                    color: widget.accentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Banco de Ejercicios",
              style: TextStyle(color: Colors.white))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: "Buscar...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none)),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _musculos.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedMusculo == _musculos[index];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedMusculo = _musculos[index]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                        color: isSelected
                            ? widget.accentColor
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(20)),
                    child: Center(
                        child: Text(_musculos[index],
                            style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _materiales.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedMaterial == _materiales[index];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedMaterial = _materiales[index]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.white : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(20)),
                    child: Center(
                        child: Text(_materiales[index],
                            style: TextStyle(
                                color:
                                    isSelected ? Colors.black : Colors.white54,
                                fontWeight: FontWeight.bold))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final ej = _filteredExercises[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    title: Text(ej['nombre']!,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("${ej['musculo']} • ${ej['material']}",
                        style: const TextStyle(color: Colors.white54)),
                    trailing: Icon(Icons.add_circle,
                        color: widget.accentColor, size: 30),
                    onTap: () => _addExercise(ej),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedExercises.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: widget.accentColor,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RoutineReviewScreen(
                            exercises: _selectedExercises,
                            accentColor: widget.accentColor)));
              },
              icon: const Icon(Icons.check, color: Colors.black),
              label: Text("Revisar Rutina (${_selectedExercises.length})",
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

// =========================================================================
// REVISAR, REORDENAR Y GUARDAR
// =========================================================================
class RoutineReviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final Color accentColor;
  final String? routineId;
  final String? initialName;

  const RoutineReviewScreen(
      {super.key,
      required this.exercises,
      required this.accentColor,
      this.routineId,
      this.initialName});

  @override
  State<RoutineReviewScreen> createState() => _RoutineReviewScreenState();
}

class _RoutineReviewScreenState extends State<RoutineReviewScreen> {
  late List<Map<String, dynamic>> _myExercises;
  bool _isSaving = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _myExercises = List.from(widget.exercises);
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
  }

  Future<void> _saveFinalRoutine() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ponle un nombre a tu rutina',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSaving = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Map<String, dynamic> newRoutine = {
          "nombre": _nameController.text.trim(),
          "descripcion": "Rutina creada/editada manualmente",
          "planificacion": [
            {
              "dia": "Ejercicios de la sesión",
              "musculo": "Varios",
              "ejercicios": _myExercises
            }
          ]
        };
        String rawJson = jsonEncode(newRoutine);

        if (widget.routineId != null) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .collection('rutinas')
              .doc(widget.routineId)
              .update({
            'rutina_json': rawJson,
          });
        } else {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .collection('rutinas')
              .add({
            'rutina_json': rawJson,
            'fecha_creacion': FieldValue.serverTimestamp(),
            'activa': true,
          });
        }

        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
          title: Text(
              widget.routineId != null ? "Editar Rutina" : "Revisar Rutina",
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                  hintText: "Nombre de la rutina...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: widget.accentColor))),
            ),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Mantén pulsado un ejercicio para moverlo",
                      style: TextStyle(color: Colors.white54)))),
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.all(20),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _myExercises.removeAt(oldIndex);
                  _myExercises.insert(newIndex, item);
                });
              },
              children: [
                for (int i = 0; i < _myExercises.length; i++)
                  Container(
                    key: ValueKey(_myExercises[i]['nombre']! + i.toString()),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(_myExercises[i]['nombre'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "${_myExercises[i]['series']} sets x ${_myExercises[i]['repeticiones']} reps",
                          style: TextStyle(color: widget.accentColor)),
                      trailing: IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () =>
                              setState(() => _myExercises.removeAt(i))),
                    ),
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveFinalRoutine,
                style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("GUARDAR RUTINA",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// =========================================================================
// PANTALLA ACTIVA DE ENTRENAMIENTO
// =========================================================================
class ActiveWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> rutina;
  final Color accentColor;
  const ActiveWorkoutScreen(
      {super.key, required this.rutina, required this.accentColor});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  bool _isFinishing = false;
  List<dynamic> _flatExercises = [];

  @override
  void initState() {
    super.initState();
    List dias = widget.rutina['planificacion'] ?? [];
    for (var dia in dias) {
      for (var ej in (dia['ejercicios'] ?? [])) {
        _flatExercises.add({
          "nombre": ej['nombre'],
          "series": ej['series'],
          "objetivo_reps": ej['repeticiones'].toString(),
        });
      }
    }
  }

  Future<void> _terminarEntrenamiento() async {
    setState(() => _isFinishing = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('historial_entrenamientos')
            .add({
          'fecha': FieldValue.serverTimestamp(),
          'nombre_rutina': widget.rutina['nombre'],
        });

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({'racha': FieldValue.increment(1)});

        if (mounted) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF2C2C2E),
                    title: const Text("¡Entrenamiento Completado!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 80),
                        const SizedBox(height: 10),
                        Text("¡Has sumado 1 día a tu racha!",
                            style: TextStyle(
                                color: widget.accentColor, fontSize: 16)),
                      ],
                    ),
                    actions: [
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: widget.accentColor),
                          child: const Text("VOLVER AL HOME",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
          title: Text(widget.rutina['nombre'] ?? "Entrenando",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _flatExercises.length,
              itemBuilder: (context, index) {
                final ej = _flatExercises[index];
                int series = int.tryParse(ej['series'].toString()) ?? 3;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ej['nombre'],
                          style: TextStyle(
                              color: widget.accentColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text("Objetivo: $series x ${ej['objetivo_reps']}",
                          style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 15),
                      for (int s = 1; s <= series; s++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(5)),
                                  child: Text("$s",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(width: 15),
                              Expanded(
                                  child: TextField(
                                      keyboardType: TextInputType.number,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                          hintText: "kg",
                                          hintStyle:
                                              TextStyle(color: Colors.white30),
                                          isDense: true))),
                              const SizedBox(width: 15),
                              Expanded(
                                  child: TextField(
                                      keyboardType: TextInputType.number,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                          hintText: "reps",
                                          hintStyle:
                                              TextStyle(color: Colors.white30),
                                          isDense: true))),
                              const SizedBox(width: 15),
                              const Icon(Icons.check_circle_outline,
                                  color: Colors.white24, size: 28),
                            ],
                          ),
                        )
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isFinishing ? null : _terminarEntrenamiento,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                child: _isFinishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("TERMINAR RUTINA",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
