// moyenne_tension_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_locaux_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_local_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_zone_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/detail_local_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/detail_zone_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class MoyenneTensionScreen extends StatefulWidget {
  final Mission mission;

  const MoyenneTensionScreen({super.key, required this.mission});

  @override
  State<MoyenneTensionScreen> createState() => _MoyenneTensionScreenState();
}

class _MoyenneTensionScreenState extends State<MoyenneTensionScreen> {
  AuditInstallationsElectriques? _audit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudit();
  }

  void _loadAudit() async {
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      setState(() {
        _audit = audit;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement audit: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _ajouterLocal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: true,
        ),
      ),
    );

    if (result == true) {
      _loadAudit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local ajouté avec succès')),
      );
    }
  }

  void _editerLocal(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          local: _audit!.moyenneTensionLocaux[index],
          localIndex: index,
        ),
      ),
    );

    if (result == true) {
      _loadAudit();
    }
  }

  void _ajouterZone() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterZoneScreen(
          mission: widget.mission,
          isMoyenneTension: true,
        ),
      ),
    );

    if (result == true) {
      _loadAudit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zone ajoutée avec succès')),
      );
    }
  }

  void _editerZone(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterZoneScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          zone: _audit!.moyenneTensionZones[index],
          zoneIndex: index,
        ),
      ),
    );

    if (result == true) {
      _loadAudit();
    }
  }

  void _voirLocal(int index) {
    if (_audit == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLocalScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          localIndex: index,
          local: _audit!.moyenneTensionLocaux[index],
        ),
      ),
    ).then((_) => _loadAudit());
  }

  void _voirZone(int index) {
    if (_audit == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailZoneScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          zoneIndex: index,
          zone: _audit!.moyenneTensionZones[index],
        ),
      ),
    ).then((_) => _loadAudit());
  }

void _showAddModal() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20.0),
      ),
    ),
    builder: (context) => Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton pour ajouter un local
          Container(
            margin: EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                      Navigator.pop(context);
                      _ajouterZone();
                    },
              icon: Icon(Icons.domain, size: 24),
              label: Text(
                'Ajouter une zone',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          
          // Bouton pour ajouter un coffret
          Container(
            margin: EdgeInsets.only(bottom: 20),
            child: ElevatedButton.icon(
               onPressed: () {
                      Navigator.pop(context);
                      _ajouterLocal();
                    },
              icon: Icon(Icons.domain, size: 24),
              label: Text(
                'Ajouter un local',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          
          // Bouton pour annuler
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    ),
  );
}

  void _supprimerLocal(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ce local ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _audit!.moyenneTensionLocaux.removeAt(index);
              });
              await HiveService.saveAuditInstallations(_audit!);
              _loadAudit();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Local supprimé')),
              );
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _supprimerZone(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cette zone ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _audit!.moyenneTensionZones.removeAt(index);
              });
              await HiveService.saveAuditInstallations(_audit!);
              _loadAudit();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Zone supprimée')),
              );
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  int _getTotalLocaux() {
    if (_audit == null) return 0;
    
    int total = _audit!.moyenneTensionLocaux.length;
    for (var zone in _audit!.moyenneTensionZones) {
      total += zone.locaux.length;
    }
    return total;
  }

  int _getTotalCoffrets() {
    if (_audit == null) return 0;
    
    int total = 0;
    for (var local in _audit!.moyenneTensionLocaux) {
      total += local.coffrets.length;
    }
    for (var zone in _audit!.moyenneTensionZones) {
      total += zone.coffrets.length;
      for (var local in zone.locaux) {
        total += local.coffrets.length;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_audit == null) {
      return Center(child: Text('Erreur de chargement'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Moyenne Tension'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'local') _ajouterLocal();
              if (value == 'zone') _ajouterZone();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'local', child: Text('Ajouter un local')),
              PopupMenuItem(value: 'zone', child: Text('Ajouter une zone')),
            ],
          ),
        ],
      ),
      body: Column(
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
                _buildStatCard('Locaux', _getTotalLocaux(), Icons.domain),
                _buildStatCard('Zones', _audit!.moyenneTensionZones.length, Icons.map_outlined),
                _buildStatCard('Coffrets', _getTotalCoffrets(), Icons.electrical_services),
              ],
            ),
          ),

          // Contenu principal
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppTheme.primaryBlue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryBlue,
                    tabs: [
                      Tab(text: 'ZONES (${_audit!.moyenneTensionZones.length})'),
                      Tab(text: 'LOCAUX (${_audit!.moyenneTensionLocaux.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [

                        // Onglet ZONES
                        _audit!.moyenneTensionZones.isEmpty
                            ? _buildEmptyState('zones', _ajouterZone)
                            : ListView.builder(
                                padding: EdgeInsets.only(top:16,left: 16,right: 16,bottom: 72),
                                itemCount: _audit!.moyenneTensionZones.length,
                                itemBuilder: (context, index) {
                                  final zone = _audit!.moyenneTensionZones[index];
                                  return _buildZoneCard(zone, index);
                                },
                              ),
                        // Onglet LOCAUX
                        _audit!.moyenneTensionLocaux.isEmpty
                            ? _buildEmptyState('locaux', _ajouterLocal)
                            : ListView.builder(
                                padding: EdgeInsets.only(top:16,left: 16,right: 16,bottom: 72),
                                itemCount: _audit!.moyenneTensionLocaux.length,
                                itemBuilder: (context, index) {
                                  final local = _audit!.moyenneTensionLocaux[index];
                                  return _buildLocalCard(local, index);
                                },
                              ),

                              

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: AppTheme.primaryBlue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 24, color: AppTheme.primaryBlue),
        ),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
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

  Widget _buildEmptyState(String type, Function onTap) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'locaux' ? Icons.domain : Icons.map_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Aucun $type ajouté',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Text(
            'Commencez par ajouter un $type',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => onTap(),
            icon: Icon(Icons.add),
            label: Text('AJOUTER UN $type'.toUpperCase()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalCard(MoyenneTensionLocal local, int index) {
    final conformiteCount = local.dispositionsConstructives.where((e) => e.conforme).length;
    final totalCount = local.dispositionsConstructives.length;
    final pourcentage = totalCount > 0 ? (conformiteCount / totalCount * 100).round() : 0;

    return  Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.domain, color: AppTheme.primaryBlue),
        ),
        title: Text(
          local.nom,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('${local.coffrets.length} coffret(s)'),
            SizedBox(height: 4),
            if (totalCount > 0) ...[
              LinearProgressIndicator(
                value: conformiteCount / totalCount,
                backgroundColor: Colors.grey.shade200,
                color: _getProgressColor(pourcentage),
              ),
              SizedBox(height: 4),
              Text('$pourcentage% conforme'),
            ] else ...[
              Text('Aucune vérification', style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') _voirLocal(index);
            if (value == 'edit') _editerLocal(index);
            if (value == 'delete') _supprimerLocal(index);
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'view', child: Text('Voir détails')),
            PopupMenuItem(value: 'edit', child: Text('Éditer')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
        ),
        onTap: () => _voirLocal(index),
      ),
    );
  }

  Widget _buildZoneCard(MoyenneTensionZone zone, int index) {
    final totalLocaux = zone.locaux.length;
    final totalCoffrets = zone.coffrets.length + 
                         zone.locaux.fold(0, (sum, local) => sum + local.coffrets.length);

    return  Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade400,
        ),
      ),
      child: InkWell(
        onTap: () => _voirZone(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.map_outlined, color: AppTheme.primaryBlue),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.nom,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (zone.description != null) ...[
                          SizedBox(height: 4),
                          Text(
                            zone.description!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') _voirZone(index);
                      if (value == 'edit') _editerZone(index);
                      if (value == 'delete') _supprimerZone(index);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'view', child: Text('Voir détails')),
                      PopupMenuItem(value: 'edit', child: Text('Éditer')),
                      PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildZoneStat('Locaux', totalLocaux, Icons.domain),
                    _buildZoneStat('Coffrets directs', zone.coffrets.length, Icons.electrical_services),
                    _buildZoneStat('Total coffrets', totalCoffrets.toInt(), Icons.assessment),
                  ],
                ),
              ),
              if (zone.observationsLibres.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Observations: ${zone.observationsLibres.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneStat(String title, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getProgressColor(int pourcentage) {
    if (pourcentage >= 80) return Colors.green;
    if (pourcentage >= 50) return Colors.orange;
    return Colors.red;
  }
}