import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ESTADO ---
  bool _isEditingProfile = false;
  String _userName = 'Alex';

  // El color elegido aquí cambiará automáticamente la racha y detalles de la web
  Color _avatarColor = const Color(0xFF00FF66);

  // --- CONFIGURACIÓN DE ACTIVIDAD (IA) ---
  final int _objetivoSemanal = 3;
  final List<int> _diasAsistidos = [
    10,
    11,
    12,
  ]; // Días que el usuario fue al gym
  final int _diaHoy = 15;

  // --- COLORES FIJOS ---
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

  // --- LÓGICA DE FECHA Y MENSAJES ---
  String _getCurrentDate() {
    final now = DateTime.now();
    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
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
      'Diciembre',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  void _showSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('La función de $feature estará disponible próximamente'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  // --- DIÁLOGOS DE EDICIÓN ---
  void _changeName() {
    final TextEditingController nameController = TextEditingController(
      text: _userName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Cambiar nombre',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _avatarColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _userName = nameController.text);
              Navigator.pop(context);
            },
            child: Text('GUARDAR', style: TextStyle(color: _avatarColor)),
          ),
        ],
      ),
    );
  }

  void _changeAvatarColor() {
    final colors = [
      const Color(0xFF00FF66),
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.cyan,
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Color del Perfil y Racha',
          style: TextStyle(color: Colors.white),
        ),
        content: Wrap(
          spacing: 10,
          children: colors
              .map(
                (color) => GestureDetector(
                  onTap: () {
                    setState(() => _avatarColor = color);
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(backgroundColor: color, radius: 20),
                ),
              )
              .toList(),
        ),
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
              child: Stack(
                children: [_buildHomeContent(), _buildProfileDrawer()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  // --- HEADER ---
  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.only(right: 20, top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF464646), Color(0xFF272727)],
        ),
        borderRadius: BorderRadius.only(
          topRight: const Radius.circular(4.0),
          bottomRight: Radius.circular(_isEditingProfile ? 0.0 : 20.0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _avatarColor,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $_userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getCurrentDate(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isEditingProfile ? Icons.close : Icons.edit_square,
              color: Colors.white,
            ),
            onPressed: () =>
                setState(() => _isEditingProfile = !_isEditingProfile),
          ),
        ],
      ),
    );
  }

  // --- PERSIANA DE PERFIL ---
  Widget _buildProfileDrawer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 20),
      height: _isEditingProfile ? 320 : 0,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileMenuItem(
              'Cambiar color Perfil/Racha',
              true,
              _changeAvatarColor,
            ),
            _buildProfileMenuItem('Cambiar Nombre', true, _changeName),
            _buildProfileMenuItem(
              'Cambiar correo',
              true,
              () => _showSoonMessage('correo'),
            ),
            _buildProfileMenuItem(
              'Cambiar contraseña',
              false,
              () => _showSoonMessage('contraseña'),
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          border: divider
              ? const Border(bottom: BorderSide(color: cardColor, width: 2))
              : null,
        ),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  // --- CONTENIDO PRINCIPAL ---
  Widget _buildHomeContent() {
    bool necesitaAviso =
        _diaHoy >= 15 && _diasAsistidos.length < _objetivoSemanal;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          if (necesitaAviso) _buildReminderCard(),
          _buildSectionTitle('¡Empieza tu rutina!'),
          _buildRoutineCard(),
          const SizedBox(height: 30),
          _buildSectionTitle('Actividad Semanal'),
          _buildStreakCalendar(),
          const SizedBox(height: 30),
          _buildSectionTitle('Recomendaciones IA'),
          _buildAICard(),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '¡Atención! Aún no has cumplido tu objetivo semanal. ¡Tú puedes!',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // --- CALENDARIO SINCRONIZADO ---
  Widget _buildStreakCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: cardColor,
        borderRadius: appCardRadius,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _CalLabel('Su'),
              _CalLabel('Mo'),
              _CalLabel('Tu'),
              _CalLabel('We'),
              _CalLabel('Th'),
              _CalLabel('Fr'),
              _CalLabel('Sa'),
            ],
          ),
          const SizedBox(height: 16),
          // Semana fallida (en rojo tenue)
          _buildCalendarWeek([
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
          ], esSemanaFallida: true),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDay('8'),
              _buildDay('9'),
              _buildDay('10', asistio: true),
              _buildDay('11', asistio: true),
              _buildDay('12', asistio: true),
              _buildDay('13', border: true),
              _buildDay('14'),
            ],
          ),
          const SizedBox(height: 12),
          _buildCalendarWeek(['15', '16', '17', '18', '19', '20', '21']),
        ],
      ),
    );
  }

  Widget _buildCalendarWeek(List<String> days, {bool esSemanaFallida = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map((d) => _buildDay(d, esSemanaFallida: esSemanaFallida))
          .toList(),
    );
  }

  Widget _buildDay(
    String d, {
    bool asistio = false,
    bool esSemanaFallida = false,
    bool border = false,
  }) {
    if (d.isEmpty) return const SizedBox(width: 36);
    Color textColor = Colors.white;
    Color? bgColor;
    if (asistio) {
      bgColor = _avatarColor;
      textColor = Colors.black;
    } else if (esSemanaFallida) {
      textColor = Colors.redAccent.withOpacity(0.5);
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: _avatarColor, width: 1.5) : null,
      ),
      child: Text(
        d,
        style: TextStyle(
          color: textColor,
          fontWeight: (asistio || border) ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // --- BARRA INFERIOR ---
  Widget _buildCustomBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: bottomNavColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.home_outlined, color: Colors.white, size: 32),
            const Icon(Icons.person_outline, color: Colors.white, size: 32),
            Image.asset('assets/images/logo_kilo.png', height: 35),
            const Icon(Icons.bar_chart, color: Colors.white, size: 32),
            GestureDetector(
              onTap: () => _showSettingsMenu(),
              child: const Icon(Icons.menu, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  // --- MENÚ DE AJUSTES RESTAURADO ---
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        decoration: const BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            _buildOldMenuBtn(
              'Cambiar icono de la App',
              Colors.white,
              () => _showSoonMessage('iconos'),
            ),
            _buildOldMenuBtn(
              'Conócenos',
              Colors.white,
              () => _showSoonMessage('nosotros'),
            ),
            _buildOldMenuBtn(
              'Legal',
              Colors.white,
              () => _showSoonMessage('legal'),
            ),
            _buildOldMenuBtn(
              'Términos y Privacidad',
              Colors.white,
              () => _showSoonMessage('privacidad'),
            ),
            _buildOldMenuBtn('Cerrar sesión', Colors.red, () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const WelcomeScreen()),
                (r) => false,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOldMenuBtn(String t, Color c, VoidCallback o) {
    return InkWell(
      onTap: o,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          t,
          style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Text(
            t,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(Icons.chevron_right, color: _avatarColor),
        ],
      ),
    );
  }

  Widget _buildRoutineCard() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: appCardRadius,
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: const Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          'Pecho & Tríceps',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAICard() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: appCardRadius,
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=1470&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: const Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          'Análisis IA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CalLabel extends StatelessWidget {
  final String l;
  const _CalLabel(this.l);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        l,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}
