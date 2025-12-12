import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/arret_urgence_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/avis_mesures_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/conditions_mesure_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/continuite_resistance_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/demarrage_auto_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/essais_declenchement_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/prises_terre_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class MesuresEssaisScreen extends StatefulWidget {
  final Mission mission;

  const MesuresEssaisScreen({super.key, required this.mission});

  @override
  State<MesuresEssaisScreen> createState() => _MesuresEssaisScreenState();
}

class _MesuresEssaisScreenState extends State<MesuresEssaisScreen> {
  bool _isLoading = true;
  bool _hasData = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      _hasData = true;
      _stats = mesures.calculerStatistiques();
    } catch (e) {
      print('❌ Erreur chargement mesures et essais: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTile(String title, IconData icon, String subtitle, Function onTap, {required Color color}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 24, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minVerticalPadding: 0,
      dense: true,
      onTap: () => onTap(),
    );
  }

  void _navigateToConditionsMesure() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConditionsMesureScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToDemarrageAuto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DemarrageAutoScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToArretUrgence() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArretUrgenceScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToPrisesTerre() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrisesTerreScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToAvisMesures() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvisMesuresScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToEssaisDeclenchement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EssaisDeclenchementScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToContinuiteResistance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContinuiteResistanceScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mesures et Essais'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Section 1: Conditions de mesure
                  _buildSectionTile(
                    'Conditions de mesure',
                    Icons.thermostat_outlined,
                    'Paramètres environnementaux de mesure',
                    _navigateToConditionsMesure,
                    color: AppTheme.primaryBlue,
                  ),
                  Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
                  
                  // Section 2: Essais de démarrage automatique
                  _buildSectionTile(
                    'Essais démarrage auto',
                    Icons.power_settings_new_outlined,
                    'Groupe électrogène - démarrage automatique',
                    _navigateToDemarrageAuto,
                    color: AppTheme.primaryBlue,
                  ),
                  Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
                  
                  // Section 3: Test d'arrêt d'urgence
                  _buildSectionTile(
                    'Test arrêt urgence',
                    Icons.emergency_outlined,
                    'Fonctionnement arrêt d\'urgence',
                    _navigateToArretUrgence,
                    color: AppTheme.primaryBlue,
                  ),
                  Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
                  
                  // Section 4: Prises de terre
                  _buildSectionTile(
                    'Prises de terre',
                    Icons.bolt_outlined,
                    'Mesures des prises de terre',
                    _navigateToPrisesTerre,
                    color: AppTheme.primaryBlue,
                  ),
                  Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
                  
                  // Section 5: Avis sur les mesures
                  _buildSectionTile(
                    'Avis sur les mesures',
                    Icons.assessment_outlined,
                    'Analyse et recommandations',
                    _navigateToAvisMesures,
                    color: AppTheme.primaryBlue,
                  ),
                  Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
                  
                  // Section 6: Essais déclenchement
                  _buildSectionTile(
                    'Essais déclenchement',
                    Icons.flash_on_outlined,
                    'Dispositifs différentiels',
                    _navigateToEssaisDeclenchement,
                    color: AppTheme.primaryBlue,
                  ),
                  Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
                  
                  // Section 7: Continuité et résistance
                  _buildSectionTile(
                    'Continuité et résistance',
                    Icons.cable_outlined,
                    'Conducteurs de protection',
                    _navigateToContinuiteResistance,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
    );
  }
}