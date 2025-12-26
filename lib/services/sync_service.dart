import 'dart:async';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/supabase_service.dart';
import 'package:workmanager/workmanager.dart';

class SyncService {
  static const String syncTaskName = 'missions_sync_task';
  static const Duration syncInterval = Duration(hours: 24);
  static DateTime? _lastSyncTime;
  static bool _isInitialized = false;

  // Initialiser le service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialiser WorkManager pour le background sync
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    _isInitialized = true;
    print('✅ SyncService initialisé');
  }

  // Callback pour le background sync
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      print('🔄 Synchronisation en arrière-plan démarrée');
      
      try {
        // Récupérer tous les matricules des vérificateurs
        final verificateurs = HiveService.getAllVerificateurs();
        
        for (final verificateur in verificateurs) {
          await _performSync(verificateur.matricule);
        }
        
        print('✅ Synchronisation en arrière-plan terminée');
        return Future.value(true);
      } catch (e) {
        print('❌ Erreur lors de la synchronisation en arrière-plan: $e');
        return Future.value(false);
      }
    });
  }

  // Programmer la synchronisation périodique
  static Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: syncInterval,
      initialDelay: Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresCharging: false,
        requiresDeviceIdle: false,
      ),
    );
    print('⏰ Synchronisation périodique programmée toutes les 24h');
  }

  // Annuler la synchronisation
  static Future<void> cancelSync() async {
    await Workmanager().cancelByUniqueName(syncTaskName);
    print('❌ Synchronisation automatique annulée');
  }

  // Synchronisation manuelle (depuis l'interface)
  static Future<int> manualSync(String matricule) async {
    return await _performSync(matricule);
  }

  // Logique de synchronisation
  static Future<int> _performSync(String matricule) async {
    try {
      final hasConnection = await SupabaseService.testConnection();
      
      if (!hasConnection) {
        print('📵 Pas de connexion Internet pour la synchronisation');
        return 0;
      }

      final onlineMissions = await SupabaseService.getMissionsByMatricule(matricule);
      int newMissionsCount = 0;

      for (var mission in onlineMissions) {
        if (!HiveService.missionExists(mission.id)) {
          await HiveService.saveMission(mission);
          newMissionsCount++;
          print('➕ Nouvelle mission synchronisée: ${mission.id}');
        }
      }

      _lastSyncTime = DateTime.now();
      
      if (newMissionsCount > 0) {
        print('✅ $newMissionsCount nouvelle(s) mission(s) synchronisée(s)');
      } else {
        print('ℹ️ Aucune nouvelle mission à synchroniser');
      }

      return newMissionsCount;
    } catch (e) {
      print('❌ Erreur lors de la synchronisation: $e');
      return 0;
    }
  }

  // Vérifier si une synchronisation est nécessaire
  static bool shouldSync() {
    if (_lastSyncTime == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    return difference >= syncInterval;
  }

  // Récupérer la dernière date de synchronisation
  static DateTime? get lastSyncTime => _lastSyncTime;

  // Sauvegarder la dernière date de synchronisation
  static void setLastSyncTime(DateTime time) {
    _lastSyncTime = time;
  }
}