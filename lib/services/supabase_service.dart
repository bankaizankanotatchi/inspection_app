import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/verificateur.dart';
import '../models/mission.dart';

class SupabaseService {
  // ⚠️ REMPLACE PAR TES VRAIES VALEURS
  static const String _supabaseUrl = 'https://zsnkzjneqczcaksoskft.supabase.co';
  static const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpzbmt6am5lcWN6Y2Frc29za2Z0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwMzA4NjQsImV4cCI6MjA3OTYwNjg2NH0.W6mE76fHPiB5f2Yk4Y6MPp8neJbZ3QyCoSnAYtaLUlE';

  static const String _verificateursEndpoint = '/rest/v1/verificateurs';
  static const String _missionsEndpoint = '/rest/v1/missions';

  // Headers communs
  static Map<String, String> get _headers => {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
        'Content-Type': 'application/json',
      };

  // ========== VÉRIFICATION UTILISATEUR ==========

  // Vérifier si un vérificateur existe (pour login)
  static Future<Verificateur?> verifyUser(
      String nom, String matricule) async {
    try {
      final url = Uri.parse(
          '$_supabaseUrl$_verificateursEndpoint?matricule=eq.$matricule&nom=eq.$nom');

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          return Verificateur.fromJson(data[0]);
        }
      }

      return null;
    } catch (e) {
      print('Erreur vérification utilisateur: $e');
      return null;
    }
  }

  // ========== SYNCHRONISATION MISSIONS ==========

  // Récupérer les missions d'un vérificateur
  static Future<List<Mission>> getMissionsByMatricule(String matricule) async {
  try {
    // Récupérer TOUTES les missions d'abord
    final url = Uri.parse('$_supabaseUrl$_missionsEndpoint');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final allMissions = data.map((json) => Mission.fromJson(json)).toList();
      
      // Filtrer manuellement par matricule
      return allMissions.where((mission) {
        if (mission.verificateurs == null) return false;
        
        // Vérifier si le matricule est dans la liste des vérificateurs
        return mission.verificateurs!.any((v) {
          // v est un Map<String, dynamic>, on vérifie directement la clé 'matricule'
          return v['matricule'] == matricule;
        });
      }).toList();
    } else {
      print('Erreur API: ${response.statusCode} - ${response.body}');
      return [];
    }
  } catch (e) {
    print('Erreur récupération missions: $e');
    return [];
  }
}
  // Test de connexion
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$_supabaseUrl$_verificateursEndpoint?limit=1');
      final response =
          await http.get(url, headers: _headers).timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Pas de connexion internet: $e');
      return false;
    }
  }
}