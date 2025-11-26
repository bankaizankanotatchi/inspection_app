import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
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

  const MissionDetailScreen({
    super.key,
    required this.mission,
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
      _currentMission = Mission(
        id: _currentMission.id,
        nomClient: _currentMission.nomClient,
        activiteClient: _currentMission.activiteClient,
        adresseClient: _currentMission.adresseClient,
        logoClient: _currentMission.logoClient,
        accompagnateurs: _currentMission.accompagnateurs,
        verificateurs: _currentMission.verificateurs,
        dgResponsable: _currentMission.dgResponsable,
        dateIntervention: _currentMission.dateIntervention,
        dateRapport: _currentMission.dateRapport,
        natureMission: _currentMission.natureMission,
        periodicite: _currentMission.periodicite,
        dureeMissionJours: _currentMission.dureeMissionJours,
        docCahierPrescriptions: _currentMission.docCahierPrescriptions,
        docNotesCalculs: _currentMission.docNotesCalculs,
        docSchemasUnifilaires: _currentMission.docSchemasUnifilaires,
        docPlanMasse: _currentMission.docPlanMasse,
        docPlansArchitecturaux: _currentMission.docPlansArchitecturaux,
        docDeclarationsCe: _currentMission.docDeclarationsCe,
        docListeInstallations: _currentMission.docListeInstallations,
        docPlanLocauxRisques: _currentMission.docPlanLocauxRisques,
        docRapportAnalyseFoudre: _currentMission.docRapportAnalyseFoudre,
        docRapportEtudeFoudre: _currentMission.docRapportEtudeFoudre,
        docRegistreSecurite: _currentMission.docRegistreSecurite,
        docRapportDerniereVerif: _currentMission.docRapportDerniereVerif,
        createdAt: _currentMission.createdAt,
        updatedAt: DateTime.now(),
        status: newStatus,
      );
    });
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
            MissionTeamSection(mission: _currentMission),

            SizedBox(height: 16),
            
            // Documents
            MissionDocumentsSection(mission: _currentMission),
            
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