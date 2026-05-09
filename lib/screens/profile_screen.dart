import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/database_helper.dart';
import '../services/session_manager.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isOnboarding = false;
  String _selectedActivity = 'Sedentary';
  bool _hydrationReminder = true;
  bool _mealLogging = false;
  bool _fastingWindow = true;
  double _calorieTarget = 2000;

  String _name = 'User';
  int _age = 25;
  String _gender = 'Laki-laki';
  double _weight = 70;
  double _height = 170;
  double _targetWeight = 65;
  String? _userId;

  final List<Map<String, String>> _activityOptions = [
    {'value': 'Sedentary', 'label': 'Jarang', 'desc': 'Olahraga 0-30 menit/hari'},
    {'value': 'Moderately Active', 'label': 'Cukup Aktif', 'desc': 'Olahraga 30-60 menit/hari'},
    {'value': 'Very Active', 'label': 'Sangat Aktif', 'desc': 'Olahraga 60-120 menit/hari'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) return;
    _userId = userId;
    final user = await DatabaseHelper.instance.getUserById(userId);
    if (user == null || !mounted) return;
    setState(() {
      _name = user['name'] as String? ?? 'User';
      _age = user['age'] as int? ?? 25;
      _gender = user['gender'] as String? ?? 'Laki-laki';
      _weight = (user['weight'] as num?)?.toDouble() ?? 70;
      _height = (user['height'] as num?)?.toDouble() ?? 170;
      _selectedActivity = user['activity_level'] as String? ?? 'Sedentary';
      _calorieTarget = (user['daily_calorie_target'] as num?)?.toDouble() ?? 2000;
      _targetWeight = (user['target_weight'] as num?)?.toDouble() ?? 65;
    });
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;
    await DatabaseHelper.instance.updateUserProfile(_userId!, {
      'age': _age,
      'gender': _gender,
      'weight': _weight,
      'height': _height,
      'activity_level': _selectedActivity,
      'daily_calorie_target': _calorieTarget.toInt(),
      'target_weight': _targetWeight,
    });
    if (!mounted) return;
    setState(() => _isOnboarding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profil berhasil disimpan!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _updateCalorieTarget(double val) async {
    setState(() => _calorieTarget = val);
    if (_userId != null) {
      await DatabaseHelper.instance.updateCalorieTarget(_userId!, val);
    }
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isOnboarding ? _buildOnboardingView() : _buildProfileDashboard();
  }

  Widget _buildOnboardingView() {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: AppTheme.primary.withOpacity(0.15),
            child: const Icon(Icons.person, color: AppTheme.primary, size: 18)),
          const SizedBox(width: 8),
          const Text('NutriWise'),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text('EDIT PROFIL', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          const Text('Lengkapi Profilmu', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          // Usia & Gender
          Row(children: [
            Expanded(child: _EditableCard(label: 'USIA', value: '$_age', unit: 'tahun', onTap: () => _editNumber('Usia', _age.toDouble(), (v) => setState(() => _age = v.toInt())))),
            const SizedBox(width: 12),
            Expanded(child: _InfoCard(label: 'GENDER', value: _gender, isDropdown: true, onTap: _editGender)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _EditableCard(label: 'BERAT BADAN', value: _weight.toStringAsFixed(1), unit: 'kg', onTap: () => _editNumber('Berat Badan', _weight, (v) => setState(() => _weight = v)))),
            const SizedBox(width: 12),
            Expanded(child: _EditableCard(label: 'TINGGI BADAN', value: _height.toStringAsFixed(0), unit: 'cm', onTap: () => _editNumber('Tinggi Badan', _height, (v) => setState(() => _height = v)))),
          ]),
          const SizedBox(height: 16),
          // Aktivitas per hari
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TINGKAT AKTIVITAS HARIAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1)),
              const SizedBox(height: 12),
              ..._activityOptions.map((opt) {
                final isSelected = _selectedActivity == opt['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedActivity = opt['value']!),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: AppTheme.primary, width: 1.5) : null,
                    ),
                    child: Row(children: [
                      Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade400, width: 2)),
                        child: isSelected ? const Center(child: CircleAvatar(radius: 5, backgroundColor: AppTheme.primary)) : null),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(opt['label']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
                        Text(opt['desc']!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ]),
                    ]),
                  ),
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: _saveProfile, child: const Text('SIMPAN PROFIL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _editNumber(String title, double current, ValueChanged<double> onSave) {
    final controller = TextEditingController(text: current.toStringAsFixed(current == current.roundToDouble() ? 0 : 1));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(onPressed: () { onSave(double.tryParse(controller.text) ?? current); Navigator.pop(ctx); },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary), child: const Text('Simpan')),
      ],
    ));
  }

  void _editGender() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pilih Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Laki-laki', 'Perempuan'].map((g) => ListTile(
          title: Text(g),
          onTap: () {
            setState(() => _gender = g);
            Navigator.pop(ctx);
          },
        )).toList(),
      ),
    ));
  }

  Widget _buildProfileDashboard() {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: AppTheme.primary.withOpacity(0.15),
            child: const Icon(Icons.person, color: AppTheme.primary, size: 18)),
          const SizedBox(width: 8), const Text('NutriWise'),
        ]),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Header
          Container(width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: const Text('DASHBOARD PRIBADI', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1))),
              const SizedBox(height: 8),
              Text(_name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
              const Text('Menjaga vitalitas setiap hari', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ])),
          const SizedBox(height: 12),

          // Kalori Slider (FUNCTIONAL)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ANGGARAN ENERGI HARIAN', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, letterSpacing: 1, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(_calorieTarget.toStringAsFixed(0), style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                const SizedBox(width: 6),
                const Text('kcal', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
              ]),
              const SizedBox(height: 10),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(thumbColor: AppTheme.primary, activeTrackColor: AppTheme.primary, inactiveTrackColor: Colors.grey.shade200,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), trackHeight: 4, overlayShape: SliderComponentShape.noOverlay),
                child: Slider(value: _calorieTarget, min: 1200, max: 3000, divisions: 36,
                  onChanged: (v) => _updateCalorieTarget(v)),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('1200 KCAL', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                Text('3000 KCAL', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Berat & Target
          Row(children: [
            Expanded(child: Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('BERAT SEKARANG', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, letterSpacing: 0.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('${_weight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
              ]))),
            const SizedBox(width: 12),
            Expanded(child: Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TARGET BERAT', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, letterSpacing: 0.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('${_targetWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.carbsColor)),
              ]))),
          ]),
          const SizedBox(height: 16),

          // Mindful Toggles
          const Align(alignment: Alignment.centerLeft, child: Text('Mindful Toggles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary))),
          const SizedBox(height: 10),
          _ToggleTile(icon: '💧', title: 'Pengingat Hidrasi', subtitle: 'Pengingat lembut setiap 2 jam', value: _hydrationReminder, onChanged: (v) => setState(() => _hydrationReminder = v)),
          _ToggleTile(icon: '🍽️', title: 'Pencatatan Makanan', subtitle: 'Ringkasan harian jam 20:00', value: _mealLogging, onChanged: (v) => setState(() => _mealLogging = v)),
          _ToggleTile(icon: '🌙', title: 'Jendela Puasa', subtitle: 'Notif saat jendela buka/tutup', value: _fastingWindow, onChanged: (v) => setState(() => _fastingWindow = v)),
          const SizedBox(height: 16),

          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => setState(() => _isOnboarding = true),
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
            label: const Text('Edit Profil', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)))),
          const SizedBox(height: 10),
          Center(child: TextButton.icon(onPressed: _logout,
            icon: const Icon(Icons.logout, size: 14, color: Colors.red),
            label: const Text('KELUAR DARI AKUN', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w700, letterSpacing: 0.5)))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _EditableCard extends StatelessWidget {
  final String label, value;
  final String? unit;
  final VoidCallback onTap;
  const _EditableCard({required this.label, required this.value, this.unit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Row(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          if (unit != null) ...[const SizedBox(width: 4), Text(unit!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))],
          const Spacer(),
          const Icon(Icons.edit, size: 14, color: AppTheme.textMuted),
        ]),
      ])));
  }
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final bool isDropdown;
  final VoidCallback? onTap;
  const _InfoCard({required this.label, required this.value, this.isDropdown = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            if (isDropdown) const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
          ]),
        ])),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String icon, title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.bgColor, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primary),
      ]));
  }
}
