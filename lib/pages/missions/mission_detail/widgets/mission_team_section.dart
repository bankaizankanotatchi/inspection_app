import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class MissionTeamSection extends StatefulWidget {
  final Mission mission;
  final bool editable;

  const MissionTeamSection({
    super.key,
    required this.mission,
    this.editable = false,
  });

  @override
  State<MissionTeamSection> createState() => _MissionTeamSectionState();
}

class _MissionTeamSectionState extends State<MissionTeamSection> {
  List<String> _accompagnateurs = [];
  
  @override
  void initState() {
    super.initState();
    // Synchroniser avec la mission actuelle
    _loadAccompagnateurs();
  }

  @override
  void didUpdateWidget(covariant MissionTeamSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger si la mission change
    if (oldWidget.mission.id != widget.mission.id) {
      _loadAccompagnateurs();
    }
  }

  void _loadAccompagnateurs() {
    // Recharger depuis Hive pour être sûr d'avoir les données à jour
    final mission = HiveService.getMissionById(widget.mission.id);
    setState(() {
      _accompagnateurs = mission?.accompagnateurs ?? [];
    });
  }

  Future<void> _showAddAccompagnateurModal() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrez le nom de l\'accompagnateur :',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Ex: Jean Dupont',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Ajouter'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _addAccompagnateur(result);
    }
  }

  Future<void> _addAccompagnateur(String name) async {
    final success = await HiveService.addAccompagnateur(
      missionId: widget.mission.id,
      accompagnateur: name,
    );

    if (success) {
      // Recharger depuis Hive pour éviter les doublons
      _loadAccompagnateurs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Accompagnateur "$name" ajouté'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: cet accompagnateur existe déjà'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editAccompagnateur(int index, String oldName) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: oldName);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: AppTheme.primaryBlue, size: 20),
              SizedBox(width: 8),
              Text('Modifier'),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nouveau nom',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      final success = await HiveService.updateAccompagnateur(
        missionId: widget.mission.id,
        oldAccompagnateur: oldName,
        newAccompagnateur: newName,
      );

      if (success) {
        // Recharger depuis Hive
        _loadAccompagnateurs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accompagnateur modifié'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccompagnateur(int index, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmer'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await HiveService.removeAccompagnateur(
        missionId: widget.mission.id,
        accompagnateur: name,
      );

      if (success) {
        // Recharger depuis Hive
        _loadAccompagnateurs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accompagnateur supprimé'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildAccompagnateursList() {
    final hasAccompagnateurs = _accompagnateurs.isNotEmpty;

    if (!hasAccompagnateurs && !widget.editable) {
      return SizedBox();
    }

    if (!hasAccompagnateurs) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Text(
              'Aucun accompagnateur',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddAccompagnateurModal,
              icon: Icon(Icons.person_add, size: 18),
              label: Text('Ajouter un accompagnateur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Accompagnateurs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            if (widget.editable)
              TextButton.icon(
                onPressed: _showAddAccompagnateurModal,
                icon: Icon(Icons.person_add, size: 18),
                label: Text('Ajouter'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        ..._accompagnateurs.asMap().entries.map((entry) {
          final index = entry.key;
          final accompagnateur = entry.value;

          return Container(
            key: ValueKey('accompagnateur_${index}_${accompagnateur}'), // Clé unique pour l'animation
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.person, size: 16, color: AppTheme.primaryBlue),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    accompagnateur,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
                if (widget.editable) ...[
                  IconButton(
                    icon: Icon(Icons.edit, size: 18),
                    color: AppTheme.primaryBlue,
                    onPressed: () => _editAccompagnateur(index, accompagnateur),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 18),
                    color: Colors.red.shade400,
                    onPressed: () => _deleteAccompagnateur(index, accompagnateur),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        if (widget.editable && _accompagnateurs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: TextButton.icon(
                onPressed: _showAddAccompagnateurModal,
                icon: Icon(Icons.person_add, size: 16),
                label: Text('Ajouter un autre accompagnateur'),
                style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVerificateursList() {
    final mission = HiveService.getMissionById(widget.mission.id);
    final verificateurs = mission?.verificateurs ?? widget.mission.verificateurs;
    
    if (verificateurs == null || verificateurs.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vérificateurs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkBlue,
          ),
        ),
        SizedBox(height: 8),
        ...verificateurs.map((verificateur) {
          final name = verificateur['nom'] ?? 'Inconnu';
          final matricule = verificateur['matricule'] ?? '';

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.verified_user, size: 16, color: Colors.green),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mission = HiveService.getMissionById(widget.mission.id);
    final hasVerificateurs = mission?.verificateurs != null && mission!.verificateurs!.isNotEmpty;
    final hasAccompagnateurs = _accompagnateurs.isNotEmpty;

    if (!hasVerificateurs && !hasAccompagnateurs && !widget.editable) {
      return SizedBox();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_outlined,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Équipe de Mission',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (hasVerificateurs) _buildVerificateursList(),
            
            _buildAccompagnateursList(),
          ],
        ),
      ),
    );
  }
}