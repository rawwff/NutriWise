import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_helper.dart';
import '../services/session_manager.dart';
import '../services/notification_service.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';
  double _calorieTarget = 2000;
  double _consumed = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fats = 0;
  List<Map<String, dynamic>> _todayMeals = [];
  List<Map<String, dynamic>> _recommendations = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await SessionManager.getUserId();
    final userName = await SessionManager.getUserName();

    if (userId == null) return;

    _userId = userId;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final user = await DatabaseHelper.instance.getUserById(userId);
    final meals = await DatabaseHelper.instance.getMealLogs(userId, today);
    final summary =
        await DatabaseHelper.instance.getDailyNutrition(userId, today);

    // Check notifications for inventory
    await NotificationService.checkAndNotify(userId);

    // Generate recommendations from inventory
    final inventory = await DatabaseHelper.instance.getInventory(userId);
    final recs = _generateRecommendations(inventory);

    if (!mounted) return;
    setState(() {
      _userName = userName ?? 'User';
      _calorieTarget =
          (user?['daily_calorie_target'] as num?)?.toDouble() ?? 2000;
      _consumed = summary['calories'] ?? 0;
      _protein = summary['protein'] ?? 0;
      _carbs = summary['carbs'] ?? 0;
      _fats = summary['fats'] ?? 0;
      _todayMeals = meals;
      _recommendations = recs;
    });
  }

  List<Map<String, dynamic>> _generateRecommendations(
      List<Map<String, dynamic>> inventory) {
    if (inventory.isEmpty) return [];

    final items = inventory
        .map((i) => (i['name'] as String).toLowerCase())
        .toList();

    final allRecipes = [
      {
        'name': 'Tumis Sayuran Segar',
        'emoji': '🥬',
        'calories': 150,
        'ingredients': ['brokoli', 'wortel', 'bawang putih', 'minyak'],
        'description': 'Tumis ringan dengan sayuran segar dan bumbu dasar',
      },
      {
        'name': 'Nasi Goreng Sehat',
        'emoji': '🍚',
        'calories': 350,
        'ingredients': ['nasi', 'telur', 'bawang merah', 'kecap'],
        'description': 'Nasi goreng rendah minyak dengan telur dan sayuran',
      },
      {
        'name': 'Smoothie Buah',
        'emoji': '🥤',
        'calories': 180,
        'ingredients': ['pisang', 'susu', 'madu', 'es'],
        'description': 'Smoothie segar dari buah-buahan yang tersedia',
      },
      {
        'name': 'Salad Protein',
        'emoji': '🥗',
        'calories': 280,
        'ingredients': ['ayam', 'selada', 'tomat', 'telur'],
        'description': 'Salad tinggi protein dengan sayuran segar',
      },
      {
        'name': 'Sup Ayam Sayuran',
        'emoji': '🍲',
        'calories': 200,
        'ingredients': ['ayam', 'wortel', 'kentang', 'seledri'],
        'description': 'Sup hangat kaya nutrisi dari bahan dapur',
      },
      {
        'name': 'Omelette Keju',
        'emoji': '🍳',
        'calories': 250,
        'ingredients': ['telur', 'keju', 'susu', 'garam'],
        'description': 'Omelette lembut dengan keju yang meleleh',
      },
      {
        'name': 'Tahu Goreng Crispy',
        'emoji': '🧈',
        'calories': 220,
        'ingredients': ['tahu', 'tepung', 'bawang putih', 'garam'],
        'description': 'Tahu goreng renyah dengan bumbu sederhana',
      },
      {
        'name': 'Bubur Oatmeal',
        'emoji': '🥣',
        'calories': 160,
        'ingredients': ['oat', 'susu', 'madu', 'pisang'],
        'description': 'Sarapan sehat dengan oat dan topping buah',
      },
    ];

    // Score recipes by how many ingredients match inventory
    final scored = <Map<String, dynamic>>[];
    for (final recipe in allRecipes) {
      final ingredients = recipe['ingredients'] as List<String>;
      int matchCount = 0;
      for (final ing in ingredients) {
        if (items.any((item) => item.contains(ing) || ing.contains(item))) {
          matchCount++;
        }
      }
      if (matchCount > 0) {
        scored.add({...recipe, 'match_count': matchCount});
      }
    }

    // Sort by match count
    scored.sort((a, b) =>
        (b['match_count'] as int).compareTo(a['match_count'] as int));

    // If no matches, show generic healthy recipes
    if (scored.isEmpty) {
      return allRecipes.take(3).toList();
    }

    return scored.take(4).toList();
  }

  Future<void> _deleteMeal(int mealId) async {
    await DatabaseHelper.instance.deleteMealLog(mealId);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _calorieTarget - _consumed;
    final proteinGoal = (_calorieTarget * 0.3 / 4); // 30% calories from protein
    final carbsGoal = (_calorieTarget * 0.45 / 4); // 45% calories from carbs
    final fatsGoal = (_calorieTarget * 0.25 / 9); // 25% calories from fat

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            // AppBar Custom
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              snap: true,
              backgroundColor: AppTheme.bgColor,
              elevation: 0,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    child: const Icon(Icons.person,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'NutriWise',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppTheme.textSecondary),
                  onPressed: () {
                    if (_userId != null) {
                      NotificationService.checkAndNotify(_userId!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mengecek notifikasi inventori...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Halo, ${_userName.split(' ').first}! 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pantau nutrisi harianmu',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Kalori Ring Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          CalorieRingWidget(
                              consumed: _consumed, target: _calorieTarget),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                label: 'Target Harian',
                                value: _calorieTarget.toStringAsFixed(0),
                                unit: 'kcal',
                                color: AppTheme.textPrimary,
                              ),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade200),
                              _StatItem(
                                label: 'Sisa',
                                value: remaining.toStringAsFixed(0),
                                unit: 'kcal',
                                color: remaining >= 0
                                    ? AppTheme.primary
                                    : Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nutrisi Progress
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Progres Nutrisi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          NutrientProgressBar(
                            label: 'Protein',
                            current: _protein,
                            goal: proteinGoal,
                            color: AppTheme.primary,
                            icon: Icons.fitness_center,
                          ),
                          const SizedBox(height: 14),
                          NutrientProgressBar(
                            label: 'Karbohidrat',
                            current: _carbs,
                            goal: carbsGoal,
                            color: AppTheme.carbsColor,
                            icon: Icons.grain,
                          ),
                          const SizedBox(height: 14),
                          NutrientProgressBar(
                            label: 'Lemak',
                            current: _fats,
                            goal: fatsGoal,
                            color: AppTheme.tertiary,
                            icon: Icons.water_drop_outlined,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rekomendasi Makanan
                    if (_recommendations.isNotEmpty) ...[
                      const Text(
                        'Rekomendasi Makanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Berdasarkan bahan di inventorimu',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recommendations.length,
                          itemBuilder: (context, index) {
                            final rec = _recommendations[index];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(rec['emoji'] as String,
                                          style:
                                              const TextStyle(fontSize: 24)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.primary.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${rec['calories']} kcal',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    rec['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rec['description'] as String,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Makanan Hari Ini
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Makanan Hari Ini',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${_todayMeals.length} item',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_todayMeals.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Text('🍽️', style: TextStyle(fontSize: 40)),
                            SizedBox(height: 10),
                            Text(
                              'Belum ada makanan tercatat',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap tombol + untuk menambahkan',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._todayMeals.map((meal) => Dismissible(
                            key: Key('meal_${meal['id']}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) =>
                                _deleteMeal(meal['id'] as int),
                            child: MealLogTile(
                              emoji: meal['emoji'] as String? ?? '🍽️',
                              foodName: meal['food_name'] as String,
                              mealType: meal['meal_type'] as String,
                              time: meal['time'] as String? ?? '--:--',
                              calories:
                                  (meal['calories'] as num).toDouble(),
                            ),
                          )),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFamily: 'Manrope',
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
