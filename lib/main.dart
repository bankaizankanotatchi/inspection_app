import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/hive_service.dart';
import 'constants/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'models/verificateur.dart';

void main() async {
  // S'assurer que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive
  await HiveService.init();

  // Définir l'orientation en portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspection App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthWrapper(),
    );
  }
}

// Widget qui décide directement entre Login et Home
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Vérifier immédiatement si un utilisateur est connecté
    final List<Verificateur> allUsers = HiveService.getAllUsers();

    if (allUsers.isNotEmpty) {
      // Utilisateur connecté - aller directement au Home
      final Verificateur user = allUsers.first;
      return HomeScreen(user: user);
    } else {
      // Aucun utilisateur - aller au Login
      return const LoginScreen();
    }
  }
}