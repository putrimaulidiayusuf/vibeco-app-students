import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:vibeco_app/views/splash_screen.dart';
import 'core/services/service_locator.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'views/login_screen.dart';
import 'views/student/student_dashboard.dart';
import 'views/teacher/teacher_dashboard.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Ensure the service locator is configured
  locator.reset(); 
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZieClean',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),//AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // Show a loading indicator while the auth state is being initialized from SharedPreferences
    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If not authenticated, show the beautiful Login Screen
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    final user = auth.user!;

    // Navigate to the appropriate dashboard depending on the user's role
    if (user.isStudent) {
      return const StudentDashboard();
    } else {
      return const TeacherDashboard();
    }
  }
}