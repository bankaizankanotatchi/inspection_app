import 'package:hive_flutter/hive_flutter.dart';
import '../models/verificateur.dart';
import '../models/mission.dart';

class HiveService {
  static const String _verificateurBox = 'verificateurs';
  static const String _missionBox = 'missions';
  static const String _currentUserKey = 'current_user';

  // Initialiser Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    // Enregistrer les adaptateurs
    Hive.registerAdapter(VerificateurAdapter());
    Hive.registerAdapter(MissionAdapter());

    // Ouvrir les boxes
    await Hive.openBox<Verificateur>(_verificateurBox);
    await Hive.openBox<Mission>(_missionBox);
    await Hive.openBox(_currentUserKey);
  }

  // ============================================================
  //                      GESTION UTILISATEUR
  // ============================================================

  /// Sauvegarder l’utilisateur connecté et marquer comme connecté
  static Future<void> saveCurrentUser(Verificateur user) async {
    final box = Hive.box<Verificateur>(_verificateurBox);
    await box.put(user.matricule, user);

    final currentBox = Hive.box(_currentUserKey);
    await currentBox.put('matricule', user.matricule);
    await currentBox.put('isLoggedIn', true);

    print("🔵 Utilisateur sauvegardé et connecté : ${user.matricule}");
  }

  /// Récupérer l’utilisateur ACTUELLEMENT connecté
  static Verificateur? getCurrentUser() {
    try {
      final currentBox = Hive.box(_currentUserKey);
      final matricule = currentBox.get('matricule');
      final isLoggedIn = currentBox.get('isLoggedIn', defaultValue: false);

      if (matricule == null || !isLoggedIn) return null;

      final box = Hive.box<Verificateur>(_verificateurBox);
      final user = box.get(matricule);

      if (user == null) {
        currentBox.delete('matricule');
        currentBox.delete('isLoggedIn');
      }

      return user;
    } catch (e) {
      print('❌ Erreur getCurrentUser: $e');
      return null;
    }
  }

  /// Récupérer UN utilisateur à partir du matricule (connexion locale)
  static Verificateur? getUserByMatricule(String matricule) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.get(matricule);
  }

  /// Vérifie si un utilisateur existe localement
  static bool userExists(String matricule) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.containsKey(matricule);
  }

  /// Vérifie si un utilisateur est connecté
  static bool isUserLoggedIn() {
    final currentBox = Hive.box(_currentUserKey);
    return currentBox.get('isLoggedIn', defaultValue: false);
  }

  /// Déconnecter l’utilisateur mais conserver ses données
  static Future<void> logout() async {
    try {
      final currentBox = Hive.box(_currentUserKey);
      await currentBox.put('isLoggedIn', false);
      print('🟡 Utilisateur déconnecté proprement.');
    } catch (e) {
      print('❌ Erreur lors de logout: $e');
      throw Exception('Erreur lors de la déconnexion');
    }
  }

  /// Effacer toute la session utilisateur
  static Future<void> logoutCompletely() async {
    try {
      final currentBox = Hive.box(_currentUserKey);
      await currentBox.clear();
      print('🔴 Déconnexion complète : session effacée.');
    } catch (e) {
      print('❌ Erreur logoutCompletely: $e');
      throw Exception('Erreur lors de la déconnexion complète');
    }
  }

  /// Debug de l’état des utilisateurs
  static void debugUserState() {
    final currentBox = Hive.box(_currentUserKey);
    final matricule = currentBox.get('matricule');
    final isLoggedIn = currentBox.get('isLoggedIn', defaultValue: false);
    final userBox = Hive.box<Verificateur>(_verificateurBox);

    print('====== DEBUG USER STATE ======');
    print('Matricule current_user : $matricule');
    print('isLoggedIn : $isLoggedIn');
    print('Liste users locaux : ${userBox.keys.toList()}');

    if (matricule != null) {
      final user = userBox.get(matricule);
      print('User actuel : ${user?.nom}');
    }
    print('==============================');
  }

  // ============================================================
  //                      GESTION MISSIONS
  // ============================================================

  static Future<void> saveMission(Mission mission) async {
    final box = Hive.box<Mission>(_missionBox);
    await box.put(mission.id, mission);
  }

  static Future<void> saveMissions(List<Mission> missions) async {
    final box = Hive.box<Mission>(_missionBox);
    for (var m in missions) {
      await box.put(m.id, m);
    }
  }

  static List<Mission> getAllMissions() {
    final box = Hive.box<Mission>(_missionBox);
    return box.values.toList();
  }

  static List<Mission> getMissionsByMatricule(String matricule) {
    final box = Hive.box<Mission>(_missionBox);
    return box.values.where((mission) {
      if (mission.verificateurs == null) return false;
      return mission.verificateurs!.any((v) => v['matricule'] == matricule);
    }).toList();
  }

  static bool missionExists(String id) {
    final box = Hive.box<Mission>(_missionBox);
    return box.containsKey(id);
  }

  static Future<void> clearMissions() async {
    final box = Hive.box<Mission>(_missionBox);
    await box.clear();
  }

  static int getMissionsCount() {
    final box = Hive.box<Mission>(_missionBox);
    return box.length;
  }

  static List<Verificateur> getAllUsers() {
    try {
      final box = Hive.box<Verificateur>(_verificateurBox);
      return box.values.toList();
    } catch (e) {
      print('❌ Erreur getAllUsers: $e');
      return [];
    }
  }
}
