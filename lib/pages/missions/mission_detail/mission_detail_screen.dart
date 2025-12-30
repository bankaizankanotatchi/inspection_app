import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
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
import 'package:inspec_app/services/word_report_service.dart';
import 'package:inspec_app/services/pdf_report_service.dart'; // Importez le service PDF
import 'package:share_plus/share_plus.dart';

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
    
    HiveService.updateMissionStatus(
      missionId: _currentMission.id,
      newStatus: newStatus,
    );
  }

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
    
    HiveService.updateDocumentStatus(
      missionId: _currentMission.id,
      documentField: documentField,
      value: value,
    );
  }

  Future<void> _showReportGenerationDialog(BuildContext context, String reportType) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Génération du rapport $reportType en cours...'),
          ],
        ),
      ),
    );

    try {
      File? file;
      if (reportType == 'Word') {
        file = await WordReportService.generateMissionReport(widget.mission.id);
      } else if (reportType == 'PDF') {
        file = await PdfReportService.generateMissionReport(widget.mission.id);
      }

      // Fermer le dialogue de chargement
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (file != null && file.existsSync()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Rapport d\'audit électrique - ${widget.mission.nomClient}',
          text: 'Voici le rapport d\'audit électrique pour ${widget.mission.nomClient}',
        );
      } else {
        _showError(context, 'Erreur lors de la génération du rapport $reportType');
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError(context, 'Erreur lors de la génération: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () { 
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomeScreen(user: widget.user),
              ),
            );
          },
        ),
        actions: [
          // Dropdown dans l'AppBar pour générer les rapports
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'word') {
                _showReportGenerationDialog(context, 'Word');
              } else if (value == 'pdf') {
                _showReportGenerationDialog(context, 'PDF');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'word',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Générer Word'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Générer PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec logo et nom client
            MissionHeader(mission: _currentMission),
            
            const SizedBox(height: 16),
            
            // Row avec badge de statut et bouton d'action
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
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
                  const SizedBox(width: 8),
                  StatusActionButton(
                    mission: _currentMission,
                    onStatusChanged: _handleStatusChanged,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Documents
            MissionDocumentsSection(
              mission: _currentMission,
              onDocumentChanged: _handleDocumentChanged,
            ),
            
            const SizedBox(height: 16),
            
            // Informations générales
            MissionInfoSection(mission: _currentMission),

            const SizedBox(height: 16),
            
            // Équipe (vérificateurs et accompagnateurs)
            MissionTeamSection(mission: _currentMission, editable: true),

            const SizedBox(height: 16),
            
            // Dates importantes
            MissionDatesSection(mission: _currentMission),
            
            const SizedBox(height: 16),
            
            // BOUTON GÉNÉRER RAPPORT WORD
            Container(
              padding: const EdgeInsets.only(left: 4, right: 4),
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReportGenerationDialog(context, 'Word'),
                icon: const Icon(Icons.description_outlined, size: 20),
                label: const Text('Générer rapport Word'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // NOUVEAU BOUTON POUR GÉNÉRER RAPPORT PDF
            Container(
              padding: const EdgeInsets.only(left: 4, right: 4),
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReportGenerationDialog(context, 'PDF'),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Colors.red),
                label: const Text('Générer rapport PDF', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}