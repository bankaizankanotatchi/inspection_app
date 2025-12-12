import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/home_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/widgets/mission_dates_section.dart';
import 'package:inspec_app/pages/missions/mission_detail/widgets/mission_documents_section.dart';
import 'package:inspec_app/pages/missions/mission_detail/widgets/mission_header.dart';
import 'package:inspec_app/pages/missions/mission_detail/widgets/mission_info_section.dart';
import 'package:inspec_app/pages/missions/mission_detail/widgets/mission_status_badge.dart';
import 'package:inspec_app/pages/missions/mission_detail/widgets/mission_team_section.dart';
import 'package:inspec_app/pages/missions/mission_detail/widgets/status_action_button.dart';
import 'package:inspec_app/pages/missions/mission_detail/widgets/status_selector_modal.dart';
import 'package:inspec_app/services/hive_service.dart';

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;
  final Verificateur user;


  const MissionDetailScreen({
    super.key,
    required this.mission,
    required this.user,
  });

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  late Mission _currentMission;
  late Verificateur? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentMission = widget.mission;
    _currentUser = HiveService.getCurrentUser();
  }

  void _handleStatusChanged(String newStatus) {
    setState(() {
      _currentMission.status = newStatus;
      _currentMission.updatedAt = DateTime.now();
    });
    
    // Optionnel: Sauvegarder dans Hive
    HiveService.updateMissionStatus(
      missionId: _currentMission.id,
      newStatus: newStatus,
    );
  }

  // Nouvelle méthode pour gérer les changements de documents
  void _handleDocumentChanged(String documentField, bool value) {
    setState(() {
      switch (documentField) {
        case 'doc_cahier_prescriptions':
          _currentMission.docCahierPrescriptions = value;
          break;
        case 'doc_notes_calculs':
          _currentMission.docNotesCalculs = value;
          break;
        case 'doc_schemas_unifilaires':
          _currentMission.docSchemasUnifilaires = value;
          break;
        case 'doc_plan_masse':
          _currentMission.docPlanMasse = value;
          break;
        case 'doc_plans_architecturaux':
          _currentMission.docPlansArchitecturaux = value;
          break;
        case 'doc_declarations_ce':
          _currentMission.docDeclarationsCe = value;
          break;
        case 'doc_liste_installations':
          _currentMission.docListeInstallations = value;
          break;
        case 'doc_plan_locaux_risques':
          _currentMission.docPlanLocauxRisques = value;
          break;
        case 'doc_rapport_analyse_foudre':
          _currentMission.docRapportAnalyseFoudre = value;
          break;
        case 'doc_rapport_etude_foudre':
          _currentMission.docRapportEtudeFoudre = value;
          break;
        case 'doc_registre_securite':
          _currentMission.docRegistreSecurite = value;
          break;
        case 'doc_rapport_derniere_verif':
          _currentMission.docRapportDerniereVerif = value;
          break;
      }
      _currentMission.updatedAt = DateTime.now();
    });
    
    // Sauvegarder dans Hive
    HiveService.updateDocumentStatus(
      missionId: _currentMission.id,
      documentField: documentField,
      value: value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Détails Mission',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
           onPressed: () { 
                Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomeScreen(user: widget.user),
              ),
            );
           },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec logo et nom client
            MissionHeader(mission: _currentMission),
            
            SizedBox(height: 16),
            
            // Row avec badge de statut et bouton d'action
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => StatusSelectorModal(
                          mission: _currentMission,
                          onStatusChanged: _handleStatusChanged,
                        ),
                      );
                    },
                    child: MissionStatusBadge(status: _currentMission.status),
                  ),
                ),
                SizedBox(width: 12),
                StatusActionButton(
                  mission: _currentMission,
                  onStatusChanged: _handleStatusChanged,
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Informations générales
            MissionInfoSection(mission: _currentMission),

            SizedBox(height: 16),
            
            // Équipe (vérificateurs et accompagnateurs)
            MissionTeamSection(mission: _currentMission,editable: true, ),

            SizedBox(height: 16),
            
            // Documents - AJOUT DE LA CALLBACK
            MissionDocumentsSection(
              mission: _currentMission,
              onDocumentChanged: _handleDocumentChanged,
            ),
            
            SizedBox(height: 16),
            
            // Dates importantes
            MissionDatesSection(mission: _currentMission),
            
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}