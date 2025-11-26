import 'package:hive/hive.dart';

part 'mission.g.dart';

@HiveType(typeId: 1)
class Mission extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nomClient;

  @HiveField(2)
  String? activiteClient;

  @HiveField(3)
  String? adresseClient;

  @HiveField(4)
  String? logoClient;

  @HiveField(5)
  List<String>? accompagnateurs;

  @HiveField(6)
  List<Map<String, dynamic>>? verificateurs;

  @HiveField(7)
  String? dgResponsable;

  @HiveField(8)
  DateTime? dateIntervention;

  @HiveField(9)
  DateTime? dateRapport;

  @HiveField(10)
  String? natureMission;

  @HiveField(11)
  String? periodicite;

  @HiveField(12)
  int? dureeMissionJours;

  @HiveField(13)
  String? docCahierPrescriptions;

  @HiveField(14)
  String? docNotesCalculs;

  @HiveField(15)
  String? docSchemasUnifilaires;

  @HiveField(16)
  String? docPlanMasse;

  @HiveField(17)
  String? docPlansArchitecturaux;

  @HiveField(18)
  String? docDeclarationsCe;

  @HiveField(19)
  String? docListeInstallations;

  @HiveField(20)
  String? docPlanLocauxRisques;

  @HiveField(21)
  String? docRapportAnalyseFoudre;

  @HiveField(22)
  String? docRapportEtudeFoudre;

  @HiveField(23)
  String? docRegistreSecurite;

  @HiveField(24)
  String? docRapportDerniereVerif;

  @HiveField(25)
  DateTime createdAt;

  @HiveField(26)
  DateTime updatedAt;

  @HiveField(27)
  String status;

  Mission({
    required this.id,
    required this.nomClient,
    this.activiteClient,
    this.adresseClient,
    this.logoClient,
    this.accompagnateurs,
    this.verificateurs,
    this.dgResponsable,
    this.dateIntervention,
    this.dateRapport,
    this.natureMission,
    this.periodicite,
    this.dureeMissionJours,
    this.docCahierPrescriptions,
    this.docNotesCalculs,
    this.docSchemasUnifilaires,
    this.docPlanMasse,
    this.docPlansArchitecturaux,
    this.docDeclarationsCe,
    this.docListeInstallations,
    this.docPlanLocauxRisques,
    this.docRapportAnalyseFoudre,
    this.docRapportEtudeFoudre,
    this.docRegistreSecurite,
    this.docRapportDerniereVerif,
    required this.createdAt,
    required this.updatedAt,
    required this.status, // Ajouté dans le constructeur
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? '',
      nomClient: json['nom_client'] ?? '',
      activiteClient: json['activite_client'],
      adresseClient: json['adresse_client'],
      logoClient: json['logo_client'],
      accompagnateurs: json['accompagnateurs'] != null
          ? List<String>.from(json['accompagnateurs'])
          : null,
      verificateurs: json['verificateurs'] != null
          ? List<Map<String, dynamic>>.from(
              json['verificateurs'].map((v) => Map<String, dynamic>.from(v)))
          : null,
      dgResponsable: json['dg_responsable'],
      dateIntervention: json['date_intervention'] != null
          ? DateTime.parse(json['date_intervention'])
          : null,
      dateRapport: json['date_rapport'] != null
          ? DateTime.parse(json['date_rapport'])
          : null,
      natureMission: json['nature_mission'],
      periodicite: json['periodicite'],
      dureeMissionJours: json['duree_mission_jours'],
      docCahierPrescriptions: json['doc_cahier_prescriptions'],
      docNotesCalculs: json['doc_notes_calculs'],
      docSchemasUnifilaires: json['doc_schemas_unifilaires'],
      docPlanMasse: json['doc_plan_masse'],
      docPlansArchitecturaux: json['doc_plans_architecturaux'],
      docDeclarationsCe: json['doc_declarations_ce'],
      docListeInstallations: json['doc_liste_installations'],
      docPlanLocauxRisques: json['doc_plan_locaux_risques'],
      docRapportAnalyseFoudre: json['doc_rapport_analyse_foudre'],
      docRapportEtudeFoudre: json['doc_rapport_etude_foudre'],
      docRegistreSecurite: json['doc_registre_securite'],
      docRapportDerniereVerif: json['doc_rapport_derniere_verif'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_client': nomClient,
      'activite_client': activiteClient,
      'adresse_client': adresseClient,
      'logo_client': logoClient,
      'accompagnateurs': accompagnateurs,
      'verificateurs': verificateurs,
      'dg_responsable': dgResponsable,
      'date_intervention': dateIntervention?.toIso8601String(),
      'date_rapport': dateRapport?.toIso8601String(),
      'nature_mission': natureMission,
      'periodicite': periodicite,
      'duree_mission_jours': dureeMissionJours,
      'doc_cahier_prescriptions': docCahierPrescriptions,
      'doc_notes_calculs': docNotesCalculs,
      'doc_schemas_unifilaires': docSchemasUnifilaires,
      'doc_plan_masse': docPlanMasse,
      'doc_plans_architecturaux': docPlansArchitecturaux,
      'doc_declarations_ce': docDeclarationsCe,
      'doc_liste_installations': docListeInstallations,
      'doc_plan_locaux_risques': docPlanLocauxRisques,
      'doc_rapport_analyse_foudre': docRapportAnalyseFoudre,
      'doc_rapport_etude_foudre': docRapportEtudeFoudre,
      'doc_registre_securite': docRegistreSecurite,
      'doc_rapport_derniere_verif': docRapportDerniereVerif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status, 
    };
  }
}