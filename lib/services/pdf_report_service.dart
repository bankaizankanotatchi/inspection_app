import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class PdfReportService {
  static final PdfColor lightGrey = PdfColor.fromInt(0xFFE0E0E0);
  static final PdfColor headerColor = PdfColor.fromInt(0xFF2C3E50);
  static final PdfColor primaryColor = PdfColor.fromInt(0xFF3498DB);
  static final PdfColor tableHeaderBg = PdfColor.fromInt(0xFFF5F5F5);
  
  // Marges réduites pour plus d'espace
  static const double pageMargin = 25.0;
  static const double smallMargin = 5.0;
  static const double mediumMargin = 10.0;
  static const double largeMargin = 20.0;
  
  static Future<File?> generateMissionReport(String missionId) async {
    try {
      // Récupérer toutes les données de la mission
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) return null;

      final description = HiveService.getDescriptionInstallationsByMissionId(missionId);
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      final classements = HiveService.getEmplacementsByMissionId(missionId);
      final mesures = HiveService.getMesuresEssaisByMissionId(missionId);
      final foudres = HiveService.getFoudreObservationsByMissionId(missionId);

      // Créer le document PDF
      final pdf = pw.Document(
        title: 'Rapport d\'Audit Électrique - ${mission.nomClient}',
        author: 'Application Inspection Électrique',
        compress: true,
      );

      // ==================== PAGE DE COUVERTURE ====================
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(pageMargin),
          build: (pw.Context context) {
            return _buildCoverPage(mission);
          },
        ),
      );

      // ==================== 1. IDENTIFICATION DE LA MISSION ====================
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(pageMargin),
          build: (pw.Context context) => _buildMissionIdentification(mission),
          footer: (pw.Context context) => _buildFooter(context),
        ),
      );

      // ==================== 2. DESCRIPTION DES INSTALLATIONS ====================
      if (description != null) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(pageMargin),
            build: (pw.Context context) => _buildDescriptionInstallations(description, missionId),
            footer: (pw.Context context) => _buildFooter(context),
          ),
        );
      } else {
        _addSectionPage(pdf, '2. DESCRIPTION DES INSTALLATIONS', pw.Text('Aucune donnée disponible.'));
      }

      // ==================== 3. AUDIT DES INSTALLATIONS ÉLECTRIQUES ====================
      if (audit != null && (audit.moyenneTensionLocaux.isNotEmpty || audit.moyenneTensionZones.isNotEmpty || audit.basseTensionZones.isNotEmpty)) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(pageMargin),
            build: (pw.Context context) => _buildAuditInstallations(audit, missionId),
            footer: (pw.Context context) => _buildFooter(context),
          ),
        );
      } else {
        _addSectionPage(pdf, '3. AUDIT DES INSTALLATIONS ÉLECTRIQUES', pw.Text('Aucune donnée disponible.'));
      }

      // ==================== 4. CLASSEMENT DES EMPLACEMENTS ====================
      if (classements.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(pageMargin),
            build: (pw.Context context) => _buildClassementEmplacements(classements),
            footer: (pw.Context context) => _buildFooter(context),
          ),
        );
      } else {
        _addSectionPage(pdf, '4. CLASSEMENT DES EMPLACEMENTS', pw.Text('Aucun classement disponible.'));
      }

      // ==================== 5. MESURES ET ESSAIS ====================
      if (mesures != null && _hasMesuresData(mesures)) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(pageMargin),
            build: (pw.Context context) => _buildMesuresEssais(mesures, missionId),
            footer: (pw.Context context) => _buildFooter(context),
          ),
        );
      } else {
        _addSectionPage(pdf, '5. MESURES ET ESSAIS', pw.Text('Aucune donnée disponible.'));
      }

      // ==================== 6. OBSERVATIONS FOUDRES ====================
      if (foudres.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(pageMargin),
            build: (pw.Context context) => _buildObservationsFoudre(foudres),
            footer: (pw.Context context) => _buildFooter(context),
          ),
        );
      } else {
        _addSectionPage(pdf, '6. OBSERVATIONS FOUDRES', pw.Text('Aucune observation foudre disponible.'));
      }

      // ==================== 7. ANNEXES - PHOTOS ====================
      await _addAnnexesPhotos(pdf, missionId);

      // Générer le fichier PDF
      final bytes = await pdf.save();
      
      // Sauvegarder le fichier
      final dir = await getTemporaryDirectory();
      final fileName = 'Rapport_${mission.nomClient}_${_formatDate(DateTime.now())}.pdf'
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_');
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      print('✅ Rapport PDF généré: ${file.path}');
      return file;
    } catch (e, stack) {
      print('❌ Erreur génération rapport PDF: $e');
      print('Stack trace: $stack');
      return null;
    }
  }

  // ==================== MÉTHODES DE CONSTRUCTION DE PAGES MULTIPLES ====================

  static pw.Widget _buildCoverPage(Mission mission) {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'RAPPORT D\'AUDIT ÉLECTRIQUE',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: headerColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            mission.nomClient,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Date d\'intervention: ${_formatDate(mission.dateIntervention ?? DateTime.now())}',
            style: pw.TextStyle(fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),
          if (mission.natureMission != null)
            pw.Text(
              'Nature de la mission: ${mission.natureMission}',
              style: pw.TextStyle(fontSize: 14),
              textAlign: pw.TextAlign.center,
            ),
          pw.SizedBox(height: 40),
          pw.Text(
            'Rapport généré le: ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildMissionIdentification(Mission mission) {
    final List<List<String>> data = [];
    
    data.add(['Client', mission.nomClient]);
    if (mission.activiteClient != null) {
      data.add(['Activité du client', mission.activiteClient!]);
    }
    if (mission.adresseClient != null) {
      data.add(['Adresse', mission.adresseClient!]);
    }
    if (mission.dgResponsable != null) {
      data.add(['DG responsable', mission.dgResponsable!]);
    }
    if (mission.dateIntervention != null) {
      data.add(['Date d\'intervention', _formatDate(mission.dateIntervention!)]);
    }
    if (mission.dateRapport != null) {
      data.add(['Date du rapport', _formatDate(mission.dateRapport!)]);
    }
    if (mission.natureMission != null) {
      data.add(['Nature de la mission', mission.natureMission!]);
    }
    if (mission.periodicite != null) {
      data.add(['Périodicité', mission.periodicite!]);
    }
    if (mission.dureeMissionJours != null) {
      data.add(['Durée de la mission', '${mission.dureeMissionJours} jours']);
    }

    return [
      _buildSectionTitle('1. IDENTIFICATION DE LA MISSION'),
      
      // Tableau d'identification
      pw.TableHelper.fromTextArray(
        headers: ['Champ', 'Valeur'],
        data: data,
        headerStyle: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: pw.EdgeInsets.all(4),
        border: pw.TableBorder.all(width: 0.5),
      ),
      
      pw.SizedBox(height: largeMargin),
      
      // Documents fournis
      _buildSubTitle('Documents fournis par le client'),
      
      pw.TableHelper.fromTextArray(
        headers: ['Document', 'Fourni'],
        data: [
          ['Cahier des prescriptions', mission.docCahierPrescriptions == true ? 'OUI' : 'NON'],
          ['Notes de calculs', mission.docNotesCalculs == true ? 'OUI' : 'NON'],
          ['Schémas unifilaires', mission.docSchemasUnifilaires == true ? 'OUI' : 'NON'],
          ['Plan de masse', mission.docPlanMasse == true ? 'OUI' : 'NON'],
          ['Plans architecturaux', mission.docPlansArchitecturaux == true ? 'OUI' : 'NON'],
          ['Déclarations CE', mission.docDeclarationsCe == true ? 'OUI' : 'NON'],
          ['Liste des installations', mission.docListeInstallations == true ? 'OUI' : 'NON'],
          ['Plan des locaux à risques', mission.docPlanLocauxRisques == true ? 'OUI' : 'NON'],
          ['Rapport analyse foudre', mission.docRapportAnalyseFoudre == true ? 'OUI' : 'NON'],
          ['Rapport étude foudre', mission.docRapportEtudeFoudre == true ? 'OUI' : 'NON'],
          ['Registre de sécurité', mission.docRegistreSecurite == true ? 'OUI' : 'NON'],
          ['Rapport dernière vérification', mission.docRapportDerniereVerif == true ? 'OUI' : 'NON'],
          ['Autre document', mission.docAutre == true ? 'OUI' : 'NON'],
        ],
        headerStyle: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: pw.EdgeInsets.all(4),
        border: pw.TableBorder.all(width: 0.5),
      ),
    ];
  }

  static List<pw.Widget> _buildDescriptionInstallations(DescriptionInstallations description, String missionId) {
    final widgets = <pw.Widget>[
      _buildSectionTitle('2. DESCRIPTION DES INSTALLATIONS'),
    ];

    // ==================== Alimentation Moyenne Tension ====================
    if (description.alimentationMoyenneTension.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('2.1 Alimentation Moyenne Tension (MT)'),
        _buildInstallationItemsTable(description.alimentationMoyenneTension),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== Alimentation Basse Tension ====================
    if (description.alimentationBasseTension.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('2.2 Alimentation Basse Tension (BT)'),
        _buildInstallationItemsTable(description.alimentationBasseTension),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== Groupe Électrogène ====================
    if (description.groupeElectrogene.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('2.3 Groupe Électrogène'),
        _buildInstallationItemsTable(description.groupeElectrogene),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== Alimentation en carburant ====================
    if (description.alimentationCarburant.isNotEmpty) {
      widgets.addAll([
        pw.Text(
          '2.3.1 Alimentation en carburant',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        _buildInstallationItemsTable(description.alimentationCarburant),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== Inverseur ====================
    if (description.inverseur.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('2.4 Inverseur'),
        _buildInstallationItemsTable(description.inverseur),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== Stabilisateur ====================
    if (description.stabilisateur.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('2.5 Stabilisateur'),
        _buildInstallationItemsTable(description.stabilisateur),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== Onduleurs ====================
    if (description.onduleurs.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('2.6 Onduleurs'),
        _buildInstallationItemsTable(description.onduleurs),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== Caractéristiques générales ====================
    final selections = <Map<String, String?>>[];
    
    if (description.regimeNeutre != null) {
      selections.add({'Caractéristique': 'Régime du neutre', 'Valeur': description.regimeNeutre});
    }
    
    if (description.eclairageSecurite != null) {
      selections.add({'Caractéristique': 'Éclairage de sécurité', 'Valeur': description.eclairageSecurite});
    }
    
    if (description.modificationsInstallations != null) {
      selections.add({'Caractéristique': 'Modifications des installations', 'Valeur': description.modificationsInstallations});
    }
    
    if (description.noteCalcul != null) {
      selections.add({'Caractéristique': 'Note de calcul', 'Valeur': description.noteCalcul});
    }
    
    if (description.registreSecurite != null) {
      selections.add({'Caractéristique': 'Registre de sécurité', 'Valeur': description.registreSecurite});
    }
    
    if (description.presenceParatonnerre != null) {
      selections.add({'Caractéristique': 'Présence de paratonnerre', 'Valeur': description.presenceParatonnerre});
    }
    
    if (description.analyseRisqueFoudre != null) {
      selections.add({'Caractéristique': 'Analyse risque foudre', 'Valeur': description.analyseRisqueFoudre});
    }
    
    if (description.etudeTechniqueFoudre != null) {
      selections.add({'Caractéristique': 'Étude technique foudre', 'Valeur': description.etudeTechniqueFoudre});
    }
    
    if (selections.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('2.7 Caractéristiques générales'),
        pw.TableHelper.fromTextArray(
          headers: ['Caractéristique', 'Valeur'],
          data: selections.map((s) => [s['Caractéristique']!, s['Valeur']!]).toList(),
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
      ]);
    }

    return widgets;
  }

  static List<pw.Widget> _buildAuditInstallations(AuditInstallationsElectriques audit, String missionId) {
    final widgets = <pw.Widget>[
      _buildSectionTitle('3. AUDIT DES INSTALLATIONS ÉLECTRIQUES'),
    ];

    // ==================== MOYENNE TENSION ====================
    if (audit.moyenneTensionLocaux.isNotEmpty || audit.moyenneTensionZones.isNotEmpty) {
      widgets.add(_buildSubTitle('3.1 MOYENNE TENSION'));
      
      // Locaux MT
      if (audit.moyenneTensionLocaux.isNotEmpty) {
        widgets.add(pw.Text(
          '3.1.1 Locaux Moyenne Tension',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ));
        
        for (int i = 0; i < audit.moyenneTensionLocaux.length; i++) {
          final local = audit.moyenneTensionLocaux[i];
          widgets.addAll(_buildLocalMTDetails(local, i + 1));
        }
      }
      
      // Zones MT
      if (audit.moyenneTensionZones.isNotEmpty) {
        widgets.add(pw.Text(
          '3.1.2 Zones Moyenne Tension',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ));
        
        for (int i = 0; i < audit.moyenneTensionZones.length; i++) {
          final zone = audit.moyenneTensionZones[i];
          widgets.addAll(_buildZoneMTDetails(zone, i + 1));
        }
      }
    }
    
    // ==================== BASSE TENSION ====================
    if (audit.basseTensionZones.isNotEmpty) {
      widgets.add(_buildSubTitle('3.2 BASSE TENSION'));
      
      for (int i = 0; i < audit.basseTensionZones.length; i++) {
        final zone = audit.basseTensionZones[i];
        widgets.addAll(_buildZoneBTDetails(zone, i + 1));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildClassementEmplacements(List<ClassementEmplacement> classements) {
    final widgets = <pw.Widget>[
      _buildSectionTitle('4. CLASSEMENT DES EMPLACEMENTS'),
    ];

    if (classements.isEmpty) {
      widgets.add(
        pw.Center(
          child: pw.Text('Aucun classement disponible.'),
        ),
      );
    } else {
      widgets.add(
        pw.TableHelper.fromTextArray(
          headers: [
            'Localisation', 'Zone', 'Type', 'AF', 'BE', 'AE', 'AD', 'AG', 'IP', 'IK'
          ],
          data: classements.map((emp) => [
            emp.localisation,
            emp.zone ?? '-',
            emp.typeLocal ?? '-',
            emp.af ?? '-',
            emp.be ?? '-',
            emp.ae ?? '-',
            emp.ad ?? '-',
            emp.ag ?? '-',
            emp.ip ?? '-',
            emp.ik ?? '-',
          ]).toList(),
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
      );
    }

    return widgets;
  }

  static List<pw.Widget> _buildMesuresEssais(MesuresEssais mesures, String missionId) {
    final widgets = <pw.Widget>[
      _buildSectionTitle('5. MESURES ET ESSAIS'),
    ];

    // ==================== SECTION 1: CONDITIONS DE MESURE ====================
    if (mesures.conditionMesure.observation != null && mesures.conditionMesure.observation!.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('5.1 Conditions de mesure'),
        pw.TableHelper.fromTextArray(
          headers: ['Conditions de mesure'],
          data: [[mesures.conditionMesure.observation!]],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== SECTION 2: ESSAIS DE DÉMARRAGE AUTOMATIQUE ====================
    if (mesures.essaiDemarrageAuto.observation != null && mesures.essaiDemarrageAuto.observation!.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('5.2 Essais de démarrage automatique du groupe électrogène'),
        pw.TableHelper.fromTextArray(
          headers: ['Résultat des essais'],
          data: [[mesures.essaiDemarrageAuto.observation!]],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== SECTION 3: TEST D'ARRÊT D'URGENCE ====================
    if (mesures.testArretUrgence.observation != null && mesures.testArretUrgence.observation!.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('5.3 Test de fonctionnement de l\'arrêt d\'urgence'),
        pw.TableHelper.fromTextArray(
          headers: ['Résultat du test'],
          data: [[mesures.testArretUrgence.observation!]],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== SECTION 4: PRISES DE TERRE ====================
    if (mesures.prisesTerre.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('5.4 Prises de terre'),
        pw.TableHelper.fromTextArray(
          headers: [
            'Localisation', 'Identification', 'Condition mesure',
            'Nature prise terre', 'Méthode mesure', 'Valeur mesure (Ω)', 'Observation'
          ],
          data: mesures.prisesTerre.map((pt) => [
            pt.localisation,
            pt.identification,
            pt.conditionMesure,
            pt.naturePriseTerre,
            pt.methodeMesure,
            pt.valeurMesure?.toStringAsFixed(2) ?? '-',
            pt.observation ?? '-',
          ]).toList(),
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
        pw.SizedBox(height: mediumMargin),
      ]);
    }
    
    // ==================== SECTION 5: AVIS SUR LES MESURES ====================
    if (mesures.avisMesuresTerre.observation != null && mesures.avisMesuresTerre.observation!.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('5.5 Avis sur les mesures'),
      ]);
      
      // Liste des PT satisfaisants
      if (mesures.avisMesuresTerre.satisfaisants.isNotEmpty) {
        widgets.add(pw.Text(
          'Prises de terre satisfaisantes:',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ));
        for (var pt in mesures.avisMesuresTerre.satisfaisants) {
          widgets.add(pw.Text('• $pt', style: pw.TextStyle(fontSize: 9, lineSpacing: 1.5)));
        }
        widgets.add(pw.SizedBox(height: smallMargin));
      }
      
      // Liste des PT non satisfaisants
      if (mesures.avisMesuresTerre.nonSatisfaisants.isNotEmpty) {
        widgets.add(pw.Text(
          'Prises de terre non satisfaisantes:',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ));
        for (var pt in mesures.avisMesuresTerre.nonSatisfaisants) {
          widgets.add(pw.Text('• $pt', style: pw.TextStyle(fontSize: 9, lineSpacing: 1.5)));
        }
        widgets.add(pw.SizedBox(height: smallMargin));
      }
      
      widgets.add(pw.TableHelper.fromTextArray(
        headers: ['Avis général'],
        data: [[mesures.avisMesuresTerre.observation!]],
        headerStyle: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: pw.TextStyle(fontSize: 9, lineSpacing: 1.5),
        cellPadding: pw.EdgeInsets.all(4),
        border: pw.TableBorder.all(width: 0.5),
      ));
      widgets.add(pw.SizedBox(height: mediumMargin));
    }
    
    // ==================== SECTION 6: ESSAIS DÉCLENCHEMENT DIFFÉRENTIELS ====================
    if (mesures.essaisDeclenchement.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('5.6 Essais de déclenchement des dispositifs différentiels'),
        pw.TableHelper.fromTextArray(
          headers: [
            'Localisation', 'Coffret', 'Désignation circuit', 'Type dispositif',
            'Réglage IΔn (mA)', 'Tempo (s)', 'Isolement (MΩ)', 'Essai', 'Observation'
          ],
          data: mesures.essaisDeclenchement.map((essai) => [
            essai.localisation,
            essai.coffret ?? '-',
            essai.designationCircuit ?? '-',
            essai.typeDispositif,
            essai.reglageIAn?.toString() ?? '-',
            essai.tempo?.toString() ?? '-',
            essai.isolement?.toString() ?? '-',
            essai.essai,
            essai.observation ?? '-',
          ]).toList(),
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
        pw.SizedBox(height: mediumMargin),
      ]);
      
      // Statistiques
      final stats = _calculateEssaisStats(mesures.essaisDeclenchement);
      widgets.add(
        pw.TableHelper.fromTextArray(
          headers: ['Statistiques', 'Valeur'],
          data: [
            ['Total essais', stats['total'].toString()],
            ['Essais réussis', stats['bon'].toString()],
            ['Essais non réussis', stats['mauvais'].toString()],
            ['Essais non essayés', stats['non_essaye'].toString()],
          ],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
      );
    }
    
    // ==================== SECTION 7: CONTINUITÉ ET RÉSISTANCE ====================
    if (mesures.continuiteResistances.isNotEmpty) {
      widgets.addAll([
        _buildSubTitle('5.7 Continuité et résistance des conducteurs de protection'),
        pw.TableHelper.fromTextArray(
          headers: ['Localisation', 'Désignation tableau', 'Origine mesure', 'Observation'],
          data: mesures.continuiteResistances.map((cont) => [
            cont.localisation,
            cont.designationTableau,
            cont.origineMesure,
            cont.observation ?? '-',
          ]).toList(),
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9),
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
      ]);
    }

    return widgets;
  }

  static List<pw.Widget> _buildObservationsFoudre(List<Foudre> foudres) {
    final widgets = <pw.Widget>[
      _buildSectionTitle('6. OBSERVATIONS FOUDRES'),
    ];

    if (foudres.isEmpty) {
      widgets.add(
        pw.Center(
          child: pw.Text('Aucune observation foudre disponible.'),
        ),
      );
    } else {
      // Trier par priorité
      foudres.sort((a, b) => a.niveauPriorite.compareTo(b.niveauPriorite));

      widgets.add(
        pw.TableHelper.fromTextArray(
          headers: ['Priorité', 'Observation'],
          data: foudres.map((f) => [
            f.niveauPriorite.toString(),
            f.observation,
          ]).toList(),
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(fontSize: 9, lineSpacing: 1.5),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(width: 0.5),
        ),
      );
    }

    return widgets;
  }

  // ==================== MÉTHODES DE DÉTAILS ====================

  static List<pw.Widget> _buildLocalMTDetails(MoyenneTensionLocal local, int index) {
    final widgets = <pw.Widget>[];
    
    widgets.add(pw.Text(
      'Local MT ${index}: ${local.nom} (${local.type})',
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
    ));
    
    // Tableau d'identification du local
    widgets.add(pw.TableHelper.fromTextArray(
      headers: ['Nom du local', 'Type'],
      data: [[local.nom, local.type]],
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    ));
    
    // Dispositions constructives
    if (local.dispositionsConstructives.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Dispositions constructives:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildElementsTableWithNormes(local.dispositionsConstructives));
    }
    
    // Conditions d'exploitation
    if (local.conditionsExploitation.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Conditions d\'exploitation:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildElementsTableWithNormes(local.conditionsExploitation));
    }
    
    // Cellule
    if (local.cellule != null) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.addAll(_buildCelluleDetails(local.cellule!));
    }
    
    // Transformateur
    if (local.transformateur != null) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.addAll(_buildTransformateurDetails(local.transformateur!));
    }
    
    // Coffrets dans le local
    if (local.coffrets.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Coffrets/Armoires dans le local:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      for (int j = 0; j < local.coffrets.length; j++) {
        final coffret = local.coffrets[j];
        widgets.addAll(_buildCoffretDetails(coffret, j + 1));
      }
    }
    
    // Observations
    if (local.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Observations du local:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildObservationsTable(local.observationsLibres));
    }
    
    widgets.add(pw.SizedBox(height: mediumMargin));
    return widgets;
  }

  static List<pw.Widget> _buildZoneMTDetails(MoyenneTensionZone zone, int index) {
    final widgets = <pw.Widget>[];
    
    widgets.add(pw.Text(
      'Zone MT ${index}: ${zone.nom}',
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
    ));
    
    // Tableau d'identification de la zone
    final data = <List<String>>[];
    data.add(['Nom de la zone', zone.nom]);
    if (zone.description != null) {
      data.add(['Description', zone.description!]);
    }
    
    widgets.add(pw.TableHelper.fromTextArray(
      headers: ['Champ', 'Valeur'],
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    ));
    
    // Coffrets dans la zone
    if (zone.coffrets.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Coffrets/Armoires dans la zone:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      for (int j = 0; j < zone.coffrets.length; j++) {
        final coffret = zone.coffrets[j];
        widgets.addAll(_buildCoffretDetails(coffret, j + 1));
      }
    }
    
    // Observations de la zone
    if (zone.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Observations de la zone:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildObservationsTable(zone.observationsLibres));
    }
    
    // Locaux dans la zone
    if (zone.locaux.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Locaux dans la zone:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      for (int j = 0; j < zone.locaux.length; j++) {
        final local = zone.locaux[j];
        widgets.addAll(_buildLocalDansZoneDetails(local, j + 1));
      }
    }
    
    widgets.add(pw.SizedBox(height: mediumMargin));
    return widgets;
  }

  static List<pw.Widget> _buildZoneBTDetails(BasseTensionZone zone, int index) {
    final widgets = <pw.Widget>[];
    
    widgets.add(pw.Text(
      'Zone BT ${index}: ${zone.nom}',
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
    ));
    
    // Tableau d'identification de la zone
    final data = <List<String>>[];
    data.add(['Nom de la zone', zone.nom]);
    if (zone.description != null) {
      data.add(['Description', zone.description!]);
    }
    
    widgets.add(pw.TableHelper.fromTextArray(
      headers: ['Champ', 'Valeur'],
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    ));
    
    // Coffrets directs dans la zone
    if (zone.coffretsDirects.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Coffrets/Armoires directs dans la zone:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      for (int j = 0; j < zone.coffretsDirects.length; j++) {
        final coffret = zone.coffretsDirects[j];
        widgets.addAll(_buildCoffretDetails(coffret, j + 1));
      }
    }
    
    // Observations de la zone
    if (zone.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Observations de la zone:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildObservationsTable(zone.observationsLibres));
    }
    
    // Locaux dans la zone
    if (zone.locaux.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Locaux dans la zone:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      for (int j = 0; j < zone.locaux.length; j++) {
        final local = zone.locaux[j];
        widgets.addAll(_buildLocalBTDansZoneDetails(local, j + 1));
      }
    }
    
    widgets.add(pw.SizedBox(height: mediumMargin));
    return widgets;
  }

  static List<pw.Widget> _buildLocalDansZoneDetails(MoyenneTensionLocal local, int index) {
    final widgets = <pw.Widget>[];
    
    widgets.add(pw.Text(
      'Local dans zone ${index}: ${local.nom}',
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
    ));
    
    // Tableau d'identification du local
    widgets.add(pw.TableHelper.fromTextArray(
      headers: ['Nom du local'],
      data: [[local.nom]],
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    ));
    
    // Coffrets dans le local
    if (local.coffrets.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Coffrets/Armoires dans le local:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      for (int k = 0; k < local.coffrets.length; k++) {
        final coffret = local.coffrets[k];
        widgets.addAll(_buildCoffretDetails(coffret, k + 1));
      }
    }
    
    // Observations du local
    if (local.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Observations du local:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildObservationsTable(local.observationsLibres));
    }
    
    widgets.add(pw.SizedBox(height: smallMargin));
    return widgets;
  }

  static List<pw.Widget> _buildLocalBTDansZoneDetails(BasseTensionLocal local, int index) {
    final widgets = <pw.Widget>[];
    
    widgets.add(pw.Text(
      'Local BT ${index}: ${local.nom} (${local.type})',
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
    ));
    
    // Tableau d'identification du local
    widgets.add(pw.TableHelper.fromTextArray(
      headers: ['Nom du local', 'Type'],
      data: [[local.nom, local.type]],
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    ));
    
    // Dispositions constructives
    if (local.dispositionsConstructives != null && local.dispositionsConstructives!.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Dispositions constructives:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildElementsTableWithNormes(local.dispositionsConstructives!));
    }
    
    // Conditions d'exploitation
    if (local.conditionsExploitation != null && local.conditionsExploitation!.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Conditions d\'exploitation:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildElementsTableWithNormes(local.conditionsExploitation!));
    }
    
    // Coffrets dans le local
    if (local.coffrets.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Coffrets/Armoires dans le local:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      for (int k = 0; k < local.coffrets.length; k++) {
        final coffret = local.coffrets[k];
        widgets.addAll(_buildCoffretDetails(coffret, k + 1));
      }
    }
    
    // Observations du local
    if (local.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Observations du local:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildObservationsTable(local.observationsLibres));
    }
    
    widgets.add(pw.SizedBox(height: smallMargin));
    return widgets;
  }

  static List<pw.Widget> _buildCelluleDetails(Cellule cellule) {
    final widgets = <pw.Widget>[];
    
    widgets.add(pw.Text(
      'Cellule',
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
    ));
    
    widgets.add(pw.TableHelper.fromTextArray(
      headers: ['Fonction', 'Type', 'Marque/Modèle/Année', 'Tension assignée', 'Pouvoir de coupure', 'Numérotation', 'Parafoudres'],
      data: [[
        cellule.fonction,
        cellule.type,
        cellule.marqueModeleAnnee,
        cellule.tensionAssignee,
        cellule.pouvoirCoupure,
        cellule.numerotation,
        cellule.parafoudres
      ]],
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    ));
    
    if (cellule.elementsVerifies.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Éléments vérifiés de la cellule:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildElementsTableWithNormes(cellule.elementsVerifies));
    }
    
    // Photos de la cellule
    if (cellule.photos.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Photos de la cellule:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildPhotosList(cellule.photos));
    }
    
    widgets.add(pw.SizedBox(height: smallMargin));
    return widgets;
  }

  static List<pw.Widget> _buildTransformateurDetails(TransformateurMTBT transformateur) {
    final widgets = <pw.Widget>[];
    
    widgets.add(pw.Text(
      'Transformateur',
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
    ));
    
    widgets.add(pw.TableHelper.fromTextArray(
      headers: ['Type', 'Marque/Année', 'Puissance assignée', 'Tension primaire/secondaire', 'Relais Buchholz', 'Type de refroidissement', 'Régime du neutre'],
      data: [[
        transformateur.typeTransformateur,
        transformateur.marqueAnnee,
        transformateur.puissanceAssignee,
        transformateur.tensionPrimaireSecondaire,
        transformateur.relaisBuchholz,
        transformateur.typeRefroidissement,
        transformateur.regimeNeutre
      ]],
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    ));
    
    if (transformateur.elementsVerifies.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Éléments vérifiés du transformateur:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildElementsTableWithNormes(transformateur.elementsVerifies));
    }
    
    // Photos du transformateur
    if (transformateur.photos.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Photos du transformateur:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildPhotosList(transformateur.photos));
    }
    
    widgets.add(pw.SizedBox(height: smallMargin));
    return widgets;
  }

  static List<pw.Widget> _buildCoffretDetails(CoffretArmoire coffret, int index) {
    final widgets = <pw.Widget>[];
    
    widgets.add(pw.Text(
      'Coffret ${index}: ${coffret.nom} (${coffret.type})',
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
    ));
    
    // Tableau d'identification du coffret
    final data = <List<String>>[];
    data.add(['Nom', coffret.nom]);
    data.add(['Type', coffret.type]);
    if (coffret.qrCode.isNotEmpty) {
      data.add(['QR Code', coffret.qrCode]);
    }
    if (coffret.description != null) {
      data.add(['Description', coffret.description!]);
    }
    if (coffret.repere != null) {
      data.add(['Repère', coffret.repere!]);
    }
    data.add(['Zone ATEX', coffret.zoneAtex ? 'OUI' : 'NON']);
    data.add(['Domaine tension', coffret.domaineTension]);
    data.add(['Identification armoire', coffret.identificationArmoire ? 'OUI' : 'NON']);
    data.add(['Signalisation danger', coffret.signalisationDanger ? 'OUI' : 'NON']);
    data.add(['Présence schéma', coffret.presenceSchema ? 'OUI' : 'NON']);
    data.add(['Présence parafoudre', coffret.presenceParafoudre ? 'OUI' : 'NON']);
    data.add(['Vérification thermographie', coffret.verificationThermographie ? 'OUI' : 'NON']);
    
    widgets.add(pw.TableHelper.fromTextArray(
      headers: ['Champ', 'Valeur'],
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    ));
    
    // Alimentations
    if (coffret.alimentations.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Alimentations:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(pw.TableHelper.fromTextArray(
        headers: ['Type de protection', 'PDC (kA)', 'Calibre', 'Section câble (mm²)'],
        data: coffret.alimentations.map((a) => [
          a.typeProtection,
          a.pdcKA,
          a.calibre,
          a.sectionCable
        ]).toList(),
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: pw.TextStyle(fontSize: 8),
        cellPadding: pw.EdgeInsets.all(4),
        border: pw.TableBorder.all(width: 0.5),
      ));
    }
    
    // Protection de tête
    if (coffret.protectionTete != null) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Protection de tête:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(pw.TableHelper.fromTextArray(
        headers: ['Type', 'PDC (kA)'],
        data: [[
          coffret.protectionTete!.typeProtection,
          coffret.protectionTete!.pdcKA
        ]],
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: pw.TextStyle(fontSize: 8),
        cellPadding: pw.EdgeInsets.all(4),
        border: pw.TableBorder.all(width: 0.5),
      ));
    }
    
    // Points de vérification
    if (coffret.pointsVerification.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Points de vérification:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildPointsVerificationTable(coffret.pointsVerification));
    }
    
    // Observations
    if (coffret.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Observations du coffret:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildObservationsTable(coffret.observationsLibres));
    }
    
    // Photos du coffret
    if (coffret.photos.isNotEmpty) {
      widgets.add(pw.SizedBox(height: smallMargin));
      widgets.add(pw.Text(
        'Photos du coffret:',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      widgets.add(_buildPhotosList(coffret.photos));
    }
    
    widgets.add(pw.SizedBox(height: smallMargin));
    return widgets;
  }

  // ==================== MÉTHODES UTILITAIRES ====================

  static pw.Widget _buildInstallationItemsTable(List<InstallationItem> items) {
    if (items.isEmpty) return pw.Container();

    // Extraire tous les champs uniques
    final fields = <String>{};
    for (var item in items) {
      fields.addAll(item.data.keys);
    }
    final sortedFields = fields.toList()..sort();

    // Créer les données pour la table
    final data = <List<String>>[];
    for (var item in items) {
      data.add([
        for (var field in sortedFields)
          item.data[field]?.toString() ?? '-',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: sortedFields,
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    );
  }

  static pw.Widget _buildPointsVerificationTable(List<PointVerification> points) {
    return pw.TableHelper.fromTextArray(
      headers: ['Point de vérification', 'Conformité', 'Observation', 'Référence normative', 'Priorité'],
      data: points.map((p) => [
        p.pointVerification,
        p.conformite,
        p.observation ?? '-',
        p.referenceNormative ?? '-',
        p.priorite?.toString() ?? '-',
      ]).toList(),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 8),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    );
  }

  static pw.Widget _buildObservationsTable(List<ObservationLibre> observations) {
    return pw.TableHelper.fromTextArray(
      headers: ['N°', 'Observation'],
      data: observations.asMap().entries.map((entry) => [
        (entry.key + 1).toString(),
        entry.value.texte
      ]).toList(),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 8, lineSpacing: 1.5),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    );
  }

  static pw.Widget _buildElementsTableWithNormes(List<ElementControle> elements) {
    return pw.TableHelper.fromTextArray(
      headers: ['Élément de contrôle', 'Conformité', 'Observation', 'Référence normative', 'Priorité'],
      data: elements.map((e) => [
        e.elementControle,
        e.conforme ? 'Conforme' : 'Non conforme',
        e.observation ?? '-',
        e.referenceNormative ?? '-',
        e.priorite?.toString() ?? '-',
      ]).toList(),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 8),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    );
  }

  static pw.Widget _buildPhotosList(List<String> photos) {
    return pw.TableHelper.fromTextArray(
      headers: ['N°', 'Nom du fichier'],
      data: photos.asMap().entries.map((entry) => [
        (entry.key + 1).toString(),
        path.basename(entry.value)
      ]).toList(),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 8),
      cellPadding: pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(width: 0.5),
    );
  }

  static void _addSectionPage(pw.Document pdf, String title, pw.Widget content) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(pageMargin),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(title),
              pw.SizedBox(height: largeMargin),
              content,
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: mediumMargin),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: headerColor,
        ),
      ),
    );
  }

  static pw.Widget _buildSubTitle(String title) {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: mediumMargin, bottom: smallMargin),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: pw.EdgeInsets.only(top: largeMargin),
      child: pw.Text(
        'Page ${context.pageNumber}',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey,
        ),
      ),
    );
  }

  static bool _hasMesuresData(MesuresEssais mesures) {
    return (mesures.conditionMesure.observation != null && mesures.conditionMesure.observation!.isNotEmpty) ||
           (mesures.essaiDemarrageAuto.observation != null && mesures.essaiDemarrageAuto.observation!.isNotEmpty) ||
           (mesures.testArretUrgence.observation != null && mesures.testArretUrgence.observation!.isNotEmpty) ||
           mesures.prisesTerre.isNotEmpty ||
           (mesures.avisMesuresTerre.observation != null && mesures.avisMesuresTerre.observation!.isNotEmpty) ||
           mesures.essaisDeclenchement.isNotEmpty ||
           mesures.continuiteResistances.isNotEmpty;
  }

  static Future<void> _addAnnexesPhotos(pw.Document pdf, String missionId) async {
    // Récupérer toutes les photos de la mission
    final allPhotos = <String>[];
    
    // Ajouter les photos de l'audit
    final audit = HiveService.getAuditInstallationsByMissionId(missionId);
    if (audit != null) {
      // Photos des locaux MT
      for (var local in audit.moyenneTensionLocaux) {
        if (local.photos.isNotEmpty) {
          allPhotos.addAll(local.photos.where((photo) => photo.isNotEmpty));
        }
        // Photos des éléments dans les locaux
        if (local.cellule != null && local.cellule!.photos.isNotEmpty) {
          allPhotos.addAll(local.cellule!.photos.where((photo) => photo.isNotEmpty));
        }
        if (local.transformateur != null && local.transformateur!.photos.isNotEmpty) {
          allPhotos.addAll(local.transformateur!.photos.where((photo) => photo.isNotEmpty));
        }
        // Photos des coffrets dans les locaux
        for (var coffret in local.coffrets) {
          if (coffret.photos.isNotEmpty) {
            allPhotos.addAll(coffret.photos.where((photo) => photo.isNotEmpty));
          }
        }
      }
      
      // Photos des zones MT
      for (var zone in audit.moyenneTensionZones) {
        if (zone.photos.isNotEmpty) {
          allPhotos.addAll(zone.photos.where((photo) => photo.isNotEmpty));
        }
        for (var coffret in zone.coffrets) {
          if (coffret.photos.isNotEmpty) {
            allPhotos.addAll(coffret.photos.where((photo) => photo.isNotEmpty));
          }
        }
        for (var local in zone.locaux) {
          if (local.photos.isNotEmpty) {
            allPhotos.addAll(local.photos.where((photo) => photo.isNotEmpty));
          }
        }
      }
      
      // Photos des zones BT
      for (var zone in audit.basseTensionZones) {
        if (zone.photos.isNotEmpty) {
          allPhotos.addAll(zone.photos.where((photo) => photo.isNotEmpty));
        }
        for (var coffret in zone.coffretsDirects) {
          if (coffret.photos.isNotEmpty) {
            allPhotos.addAll(coffret.photos.where((photo) => photo.isNotEmpty));
          }
        }
        for (var local in zone.locaux) {
          if (local.photos.isNotEmpty) {
            allPhotos.addAll(local.photos.where((photo) => photo.isNotEmpty));
          }
        }
      }
    }
    
    // Créer la page d'annexes
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(pageMargin),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            _buildSectionTitle('7. ANNEXES - PHOTOS'),
          ];

          if (allPhotos.isEmpty) {
            widgets.add(
              pw.Center(
                child: pw.Text('Aucune photo disponible.'),
              ),
            );
          } else {
            widgets.add(
              pw.Text(
                'Liste des photos prises lors de l\'audit:',
                style: pw.TextStyle(fontSize: 12),
              ),
            );
            
            widgets.add(pw.SizedBox(height: mediumMargin));
            
            widgets.add(
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['N°', 'Fichier photo', 'Description'],
                data: allPhotos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final photoPath = entry.value;
                  final fileName = path.basename(photoPath);
                  
                  String description = 'Photo d\'audit';
                  if (fileName.toLowerCase().contains('zone')) description = 'Photo de zone';
                  if (fileName.toLowerCase().contains('local')) description = 'Photo de local';
                  if (fileName.toLowerCase().contains('coffret')) description = 'Photo de coffret';
                  if (fileName.toLowerCase().contains('transformateur')) description = 'Photo de transformateur';
                  if (fileName.toLowerCase().contains('cellule')) description = 'Photo de cellule';
                  if (fileName.toLowerCase().contains('point')) description = 'Photo point vérification';
                  if (fileName.toLowerCase().contains('element')) description = 'Photo élément contrôle';
                  if (fileName.toLowerCase().contains('observation')) description = 'Photo observation';
                  
                  return [(index + 1).toString(), fileName, description];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: pw.TextStyle(fontSize: 9, lineSpacing: 1.5),
                cellPadding: pw.EdgeInsets.all(4),
                border: pw.TableBorder.all(width: 0.5),
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: widgets,
          );
        },
      ),
    );
    
    // Ajouter une page pour chaque photo (facultatif - peut générer un gros PDF)
    for (int i = 0; i < allPhotos.length; i++) {
        final photoPath = allPhotos[i];
        try {
          final file = File(photoPath);
          if (await file.exists()) {
            final imageBytes = await file.readAsBytes();
            final image = pw.MemoryImage(imageBytes);
            
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                margin: pw.EdgeInsets.all(pageMargin),
                build: (pw.Context context) {
                  return pw.Column(
                    children: [
                      pw.Text(
                        'Photo ${i + 1}/${allPhotos.length}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: mediumMargin),
                      pw.Text(
                        path.basename(photoPath),
                        style: pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: largeMargin),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Image(
                          image,
                          fit: pw.BoxFit.contain,
                          height: 400,
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }
        } catch (e) {
          print('❌ Erreur chargement photo $photoPath: $e');
        }
      }

  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static Map<String, int> _calculateEssaisStats(List<EssaiDeclenchementDifferentiel> essais) {
    int total = essais.length;
    int bon = essais.where((e) => e.essai == 'B' || e.essai == 'OK').length;
    int mauvais = essais.where((e) => e.essai == 'M' || e.essai == 'NON OK').length;
    int nonEssaye = essais.where((e) => e.essai == 'NE').length;
    
    return {
      'total': total,
      'bon': bon,
      'mauvais': mauvais,
      'non_essaye': nonEssaye,
    };
  }

  // ==================== MÉTHODES DE PARTAGE ET SUPPRESSION ====================

  static Future<void> shareReport(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Rapport d\'Audit Électrique PDF',
        text: 'Veuillez trouver ci-joint le rapport d\'audit électrique généré.',
      );
      print('✅ Rapport PDF partagé avec succès');
    } catch (e) {
      print('❌ Erreur lors du partage PDF: $e');
    }
  }

  static Future<void> deleteReport(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        print('✅ Rapport PDF supprimé: ${file.path}');
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression PDF: $e');
    }
  }
}