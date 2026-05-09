import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseHelper {
  // Singleton pattern for consistency with old code
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  static final _supabase = Supabase.instance.client;

  // Placeholder for the old initFfi function so main.dart doesn't break
  static void initFfi() {}

  // --- User operations ---
  Future<String> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    
    if (res.user != null) {
      // Create profile record
      await _supabase.from('profiles').insert({
        'id': res.user!.id,
        'name': name,
        'daily_calorie_target': 2000,
        'activity_level': 'Cukup Aktif',
      });
      return res.user!.id;
    }
    throw Exception('Gagal membuat akun');
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final AuthResponse res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user != null) {
      final data = await _supabase.from('profiles').select().eq('id', res.user!.id).single();
      return data; // returns map with 'id', 'name', etc.
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      return await _supabase.from('profiles').select().eq('id', userId).single();
    } catch (e) {
      print('DEBUG Supabase getUserById Error: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      print('DEBUG Supabase updateUserProfile Error: $e');
      rethrow;
    }
  }

  Future<void> updateCalorieTarget(String userId, double target) async {
    await _supabase.from('profiles').update({'daily_calorie_target': target.toInt()}).eq('id', userId);
  }

  // --- Meal Logs operations ---
  Future<int> addMealLog({
    required String userId,
    required String foodName,
    required String mealType,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String? emoji,
    required String time,
    required String date,
  }) async {
    final response = await _supabase.from('meal_logs').insert({
      'user_id': userId,
      'food_name': foodName,
      'meal_type': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'emoji': emoji ?? '🍽️',
      'time': time,
      'date': date,
    }).select('id').single();
    
    return response['id'] as int;
  }

  Future<List<Map<String, dynamic>>> getMealLogs(String userId, String date) async {
    return await _supabase
        .from('meal_logs')
        .select()
        .eq('user_id', userId)
        .eq('date', date)
        .order('created_at', ascending: false);
  }

  Future<Map<String, double>> getDailyNutrition(String userId, String date) async {
    final logs = await getMealLogs(userId, date);
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    
    for (var log in logs) {
      calories += (log['calories'] as num).toDouble();
      protein += (log['protein'] as num).toDouble();
      carbs += (log['carbs'] as num).toDouble();
      fat += (log['fat'] as num).toDouble();
    }
    
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  Future<void> deleteMealLog(int id) async {
    await _supabase.from('meal_logs').delete().eq('id', id);
  }

  // --- Inventory operations ---
  Future<int> addInventoryItem({
    required String userId,
    required String name,
    required double quantity,
    required String unit,
    required String category,
    required String emoji,
    String? expiryDate,
    required double lowThreshold,
  }) async {
    final response = await _supabase.from('inventory').insert({
      'user_id': userId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'emoji': emoji,
      'expiry_date': expiryDate,
      'low_threshold': lowThreshold,
    }).select('id').single();
    
    return response['id'] as int;
  }

  Future<List<Map<String, dynamic>>> getInventory(String userId) async {
    return await _supabase
        .from('inventory')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> updateInventoryQuantity(int id, double quantity) async {
    await _supabase.from('inventory').update({'quantity': quantity}).eq('id', id);
  }

  Future<void> deleteInventoryItem(int id) async {
    await _supabase.from('inventory').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getLowStockItems(String userId) async {
    // In Supabase we can use postgrest filters, but simpler to filter in Dart for now or use complex eq
    // Actually we can do .lte on quantity vs low_threshold. PostgREST allows joining or comparing columns but only with RPC.
    // Let's just fetch and filter in Dart for simplicity.
    final items = await getInventory(userId);
    return items.where((item) => (item['quantity'] as num) <= (item['low_threshold'] as num)).toList();
  }

  Future<List<Map<String, dynamic>>> getExpiringItems(String userId, int daysAhead) async {
    final items = await getInventory(userId);
    final today = DateTime.now();
    final futureDate = today.add(Duration(days: daysAhead));
    
    return items.where((item) {
      if (item['expiry_date'] == null || item['expiry_date'].toString().isEmpty) return false;
      try {
        final expDate = DateTime.parse(item['expiry_date']);
        return expDate.isAfter(today.subtract(const Duration(days: 1))) && 
               expDate.isBefore(futureDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }
}
