import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';

class MissionDocumentsSection extends StatelessWidget {
  final Mission mission;

  const MissionDocumentsSection({
    super.key,
    required this.mission,
  });

  Widget _buildDocumentItem(BuildContext context, String label, String? docUrl, IconData icon) {
    final hasDocument = docUrl != null && docUrl.isNotEmpty;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: hasDocument ? AppTheme.primaryBlue : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: hasDocument ? AppTheme.darkBlue : Colors.grey,
            fontSize: 14,
            fontWeight: hasDocument ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: hasDocument
            ? Icon(Icons.download_outlined, color: AppTheme.primaryBlue)
            : Icon(Icons.close_outlined, color: Colors.grey),
        onTap: hasDocument
            ? () {
                // TODO: Implémenter le téléchargement du document
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Téléchargement: $label'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDocuments = 
        mission.docCahierPrescriptions != null ||
        mission.docNotesCalculs != null ||
        mission.docSchemasUnifilaires != null ||
        mission.docPlanMasse != null ||
        mission.docPlansArchitecturaux != null ||
        mission.docDeclarationsCe != null ||
        mission.docListeInstallations != null ||
        mission.docPlanLocauxRisques != null ||
        mission.docRapportAnalyseFoudre != null ||
        mission.docRapportEtudeFoudre != null ||
        mission.docRegistreSecurite != null ||
        mission.docRapportDerniereVerif != null;

    if (!hasDocuments) {
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
                  Icons.folder_open_outlined,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Documents Associés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (mission.docCahierPrescriptions != null)
              _buildDocumentItem(
                context,
                'Cahier des prescriptions',
                mission.docCahierPrescriptions,
                Icons.description_outlined,
              ),
            
            if (mission.docNotesCalculs != null)
              _buildDocumentItem(
                context,
                'Notes de calculs',
                mission.docNotesCalculs,
                Icons.calculate_outlined,
              ),
            
            if (mission.docSchemasUnifilaires != null)
              _buildDocumentItem(
                context,
                'Schémas unifilaires',
                mission.docSchemasUnifilaires,
                Icons.bolt_outlined,
              ),
            
            if (mission.docPlanMasse != null)
              _buildDocumentItem(
                context,
                'Plan de masse',
                mission.docPlanMasse,
                Icons.map_outlined,
              ),
            
            if (mission.docPlansArchitecturaux != null)
              _buildDocumentItem(
                context,
                'Plans architecturaux',
                mission.docPlansArchitecturaux,
                Icons.architecture_outlined,
              ),
            
            if (mission.docDeclarationsCe != null)
              _buildDocumentItem(
                context,
                'Déclarations CE',
                mission.docDeclarationsCe,
                Icons.assignment_outlined,
              ),
            
            if (mission.docListeInstallations != null)
              _buildDocumentItem(
                context,
                'Liste des installations',
                mission.docListeInstallations,
                Icons.list_alt_outlined,
              ),
            
            if (mission.docPlanLocauxRisques != null)
              _buildDocumentItem(
                context,
                'Plan locaux à risques',
                mission.docPlanLocauxRisques,
                Icons.warning_outlined,
              ),
            
            if (mission.docRapportAnalyseFoudre != null)
              _buildDocumentItem(
                context,
                'Rapport analyse foudre',
                mission.docRapportAnalyseFoudre,
                Icons.analytics_outlined,
              ),
            
            if (mission.docRapportEtudeFoudre != null)
              _buildDocumentItem(
                context,
                'Rapport étude foudre',
                mission.docRapportEtudeFoudre,
                Icons.analytics_outlined,
              ),
            
            if (mission.docRegistreSecurite != null)
              _buildDocumentItem(
                context,
                'Registre de sécurité',
                mission.docRegistreSecurite,
                Icons.security_outlined,
              ),
            
            if (mission.docRapportDerniereVerif != null)
              _buildDocumentItem(
                context,
                'Rapport dernière vérification',
                mission.docRapportDerniereVerif,
                Icons.history_outlined,
              ),
          ],
        ),
      ),
    );
  }
}