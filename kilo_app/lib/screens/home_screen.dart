import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ESTADO DINÁMICO ---
  bool _isEditingProfile = false;
  String _userName = 'Usuario';
  Color _accentColor = const Color(0xFF00FF66);

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

  // --- LÓGICA DE FECHA ---
  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
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
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  // --- FUNCIONES DE EDICIÓN ---

  void _changeName() {
    TextEditingController controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Cambiar nombre',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _accentColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _accentColor, width: 2),
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
              if (controller.text.isNotEmpty)
                setState(() => _userName = controller.text);
              Navigator.pop(context);
            },
            child: Text(
              'GUARDAR',
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        title: const Text(
          'Color de Perfil y Racha',
          style: TextStyle(color: Colors.white),
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: colors
              .map(
                (c) => GestureDetector(
                  onTap: () {
                    setState(() => _accentColor = c);
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    backgroundColor: c,
                    radius: 22,
                    child: _accentColor == c
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Función de $feature próximamente'),
        behavior: SnackBarBehavior.floating,
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
                      _buildHomeContent(),
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

  // --- WIDGETS DE LA UI ---

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
            backgroundColor: _accentColor,
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
                  _getFormattedDate(),
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
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileMenuItem('Cambiar color Avatar', true, _changeColor),
            _buildProfileMenuItem('Cambiar Nombre', true, _changeName),
            _buildProfileMenuItem(
              'Cambiar correo',
              true,
              () => _showSoon('correo'),
            ),
            _buildProfileMenuItem(
              'Cambiar contraseña',
              false,
              () => _showSoon('contraseña'),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black,
          border: divider
              ? const Border(bottom: BorderSide(color: cardColor, width: 2))
              : null,
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          _buildSectionTitle('¡Empieza tu rutina de hoy!'),
          _buildRoutineCard(
            'Entrenamiento de pecho',
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop',
          ),
          const SizedBox(height: 30),
          _buildSectionTitle('Racha actual'),
          _buildStreakCalendar(),
          const SizedBox(height: 30),
          _buildSectionTitle('Recomendaciones de IA'),
          _buildRoutineCard(
            'Ver análisis de IA',
            'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=1470&auto=format&fit=crop',
            isAI: true,
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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
        borderRadius: appCardRadius,
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: Text(isAI ? 'Ver análisis' : 'Empezar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: cardColor,
        borderRadius: appCardRadius,
      ),
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
              _DayHeader('Sa'),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarWeek(['', '1', '2', '3', '4', '5', '6']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDay('7'),
              _buildDay('8'),
              _buildDay('9', bg: inactiveDayColor, txt: _accentColor),
              _buildDay('10', bg: _accentColor, txt: Colors.black),
              _buildDay('11', bg: _accentColor, txt: Colors.black),
              _buildDay('12', bg: _accentColor, txt: Colors.black),
              _buildDay(
                '13',
                bg: inactiveDayColor,
                txt: _accentColor,
                border: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCalendarWeek(['14', '15', '16', '17', '18', '19', '20']),
        ],
      ),
    );
  }

  Widget _buildCalendarWeek(List<String> days) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) => _buildDay(d)).toList(),
    );
  }

  Widget _buildDay(String d, {Color? bg, Color? txt, bool border = false}) {
    if (d.isEmpty) return const SizedBox(width: 36);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg ?? Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: _accentColor, width: 1.5) : null,
      ),
      child: Text(
        d,
        style: TextStyle(
          color: txt ?? Colors.white,
          fontWeight: bg != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: bottomNavColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.home_outlined, color: Colors.white, size: 30),
            const Icon(Icons.person_outline, color: Colors.white, size: 30),
            Image.asset('assets/images/logo_kilo.png', height: 35),
            const Icon(Icons.bar_chart, color: Colors.white, size: 30),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 30),
              onPressed: () => _showSettingsMenu(),
            ),
          ],
        ),
      ),
    );
  }

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
            _buildSettingsItem('Conócenos', () {}),
            _buildSettingsItem('Legal y Privacidad', () {}),
            _buildSettingsItem('Cerrar sesión', () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const WelcomeScreen()),
                (r) => false,
              );
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    String t,
    VoidCallback o, {
    bool isDestructive = false,
  }) {
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
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
