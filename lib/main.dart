import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/session_manager.dart';
import 'services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://uliglbhpxlysinagrhlv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVsaWdsYmhweGx5c2luYWdyaGx2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxODcwMzIsImV4cCI6MjA5Mjc2MzAzMn0.QZh_Q_7wLEGt_GSGt7c5o9tlVUsR-X2RMlW4BScDkbg',
  );

  // Inisialisasi FFI untuk database di desktop (Bisa dihapus nanti jika full pindah)
  DatabaseHelper.initFfi();

  // Initialize notification service
  await NotificationService.initialize();

  // Check if user is already logged in
  final isLoggedIn = await SessionManager.isLoggedIn();

  runApp(VitalOrganicistApp(isLoggedIn: isLoggedIn));
}

class VitalOrganicistApp extends StatelessWidget {
  final bool isLoggedIn;
  const VitalOrganicistApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isLoggedIn ? const MainNavigation() : const LoginScreen(),
    );
  }
}
