// classement_locaux_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_emplacement_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class ClassementLocauxScreen extends StatefulWidget {
  final Mission mission;

  const ClassementLocauxScreen({super.key, required this.mission});

  @override
  State<ClassementLocauxScreen> createState() => _ClassementLocauxScreenState();
}

class _ClassementLocauxScreenState extends State<ClassementLocauxScreen> {
  List<ClassementEmplacement> _emplacements = [];
  bool _isLoading = true;
  bool _hasAuditData = false;

  @override
  void initState() {
    super.initState();
    _checkAuditAndLoadEmplacements();
  }

  void _checkAuditAndLoadEmplacements() async {
    try {
      // Vérifier si des données d'audit existent
      final audit = HiveService.getAuditInstallationsByMissionId(widget.mission.id);
      _hasAuditData = audit != null;
      
      if (_hasAuditData) {
        // Synchroniser depuis l'audit
        _emplacements = await HiveService.syncEmplacementsFromAudit(widget.mission.id);
      } else {
        // Charger les emplacements existants
        _emplacements = HiveService.getEmplacementsByMissionId(widget.mission.id);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement classement: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshList() {
    setState(() {
      _emplacements = HiveService.getEmplacementsByMissionId(widget.mission.id);
    });
  }

  void _navigateToEmplacement(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassementEmplacementScreen(
          mission: widget.mission,
          emplacement: _emplacements[index],
        ),
      ),
    ).then((_) => _refreshList());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Aucun emplacement trouvé',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          if (!_hasAuditData)
            Text(
              'Commencez par créer des locaux/zones dans l\'audit',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            )
          else
            Text(
              'Les emplacements seront synchronisés automatiquement',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 20),
          if (!_hasAuditData)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Retour à l'écran audit
              },
              icon: Icon(Icons.arrow_back),
              label: Text('CRÉER DES LOCAUX DANS L\'AUDIT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  int _getEmplacementsComplets() {
    return _emplacements.where((e) => e.af != null && e.be != null && e.ae != null && e.ad != null && e.ag != null).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Classement des Locaux'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Classement des Locaux'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkAuditAndLoadEmplacements,
            tooltip: 'Synchroniser avec l\'audit',
          ),
        ],
      ),
      body: _emplacements.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // En-tête avec statistiques
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total', _emplacements.length, Icons.location_on, AppTheme.primaryBlue),
                      _buildStatCard('Complets', _getEmplacementsComplets(), Icons.check_circle, Colors.green),
                      _buildStatCard('Incomplets', _emplacements.length - _getEmplacementsComplets(), Icons.info_outline, Colors.orange),
                    ],
                  ),
                ),

                // Liste des emplacements
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _emplacements.length,
                    itemBuilder: (context, index) {
                      final emplacement = _emplacements[index];
                      return _buildEmplacementCard(emplacement, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

Widget _buildEmplacementCard(ClassementEmplacement emplacement, int index) {
  final estComplet = emplacement.af != null && emplacement.be != null && 
                    emplacement.ae != null && emplacement.ad != null && 
                    emplacement.ag != null;
  
  return Card(
    margin: EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    child: InkWell(
      onTap: () => _navigateToEmplacement(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1: Nom et zone
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: estComplet ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    estComplet ? Icons.check_circle_outline : Icons.info_outline,
                    color: estComplet ? Colors.green : AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emplacement.localisation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (emplacement.zone != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Zone: ${emplacement.zone}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estComplet ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estComplet ? 'Complet' : 'À compléter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: estComplet ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Ligne 2: Origine classement
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Origine: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    emplacement.origineClassement,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Ligne 3: Influences et indices
            if (estComplet)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Influences externes:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfluenceChip('AF', emplacement.af!),
                        _buildInfluenceChip('BE', emplacement.be!),
                        _buildInfluenceChip('AE', emplacement.ae!),
                        _buildInfluenceChip('AD', emplacement.ad!),
                        _buildInfluenceChip('AG', emplacement.ag!),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'IP: ${emplacement.ip ?? "N/A"}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          Text(
                            'IK: ${emplacement.ik ?? "N/A"}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Center(
                  child: Text(
                    'Cliquez pour renseigner les influences externes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildInfluenceChip(String type, String code) {
  final Map<String, Color> colorMap = {
    'AF': Colors.blue,
    'BE': Colors.purple,
    'AE': Colors.orange,
    'AD': Colors.teal,
    'AG': Colors.red,
  };
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: colorMap[type]!.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: colorMap[type]!.withOpacity(0.3)),
    ),
    child: Text(
      '$type: $code',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorMap[type]!,
      ),
    ),
  );
}
}