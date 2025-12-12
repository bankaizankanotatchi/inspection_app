
// description_installations.dart
import 'package:hive/hive.dart';

part 'description_installations.g.dart';

@HiveType(typeId: 2)
class DescriptionInstallations extends HiveObject {
  @HiveField(0)
  String missionId;

  // Caractéristiques de l'alimentation moyenne tension
  @HiveField(1)
  List<Map<String, String>> alimentationMoyenneTension;

  // Caractéristiques de l'alimentation basse tension sortie transformateur
  @HiveField(2)
  List<Map<String, String>> alimentationBasseTension;

  // Caractéristiques du groupe électrogène
  @HiveField(3)
  List<Map<String, String>> groupeElectrogene;

  // Alimentation du groupe électrogène en carburant
  @HiveField(4)
  List<Map<String, String>> alimentationCarburant;

  // Caractéristiques de l'inverseur
  @HiveField(5)
  List<Map<String, String>> inverseur;

  // Caractéristiques du stabilisateur
  @HiveField(6)
  List<Map<String, String>> stabilisateur;

  // Caractéristiques des onduleurs
  @HiveField(7)
  List<Map<String, String>> onduleurs;

  // Sélections radio
  @HiveField(8)
  String? regimeNeutre;

  @HiveField(9)
  String? eclairageSecurite;

  @HiveField(10)
  String? modificationsInstallations;

  @HiveField(11)
  String? noteCalcul;

  @HiveField(12)
  String? registreSecurite;

  // Paratonnerre
  @HiveField(13)
  String? presenceParatonnerre;

  @HiveField(14)
  String? analyseRisqueFoudre;

  @HiveField(15)
  String? etudeTechniqueFoudre;

  @HiveField(16)
  DateTime updatedAt;

  DescriptionInstallations({
    required this.missionId,
    this.alimentationMoyenneTension = const [],
    this.alimentationBasseTension = const [],
    this.groupeElectrogene = const [],
    this.alimentationCarburant = const [],
    this.inverseur = const [],
    this.stabilisateur = const [],
    this.onduleurs = const [],
    this.regimeNeutre,
    this.eclairageSecurite,
    this.modificationsInstallations,
    this.noteCalcul,
    this.registreSecurite,
    this.presenceParatonnerre,
    this.analyseRisqueFoudre,
    this.etudeTechniqueFoudre,
    required this.updatedAt,
  });

  factory DescriptionInstallations.create(String missionId) {
    return DescriptionInstallations(
      missionId: missionId,
      updatedAt: DateTime.now(),
    );
  }
}