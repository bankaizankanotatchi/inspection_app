// classement_locaux.dart
import 'package:hive/hive.dart';

part 'classement_locaux.g.dart';

@HiveType(typeId: 14)
class ClassementEmplacement extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  String localisation; // Nom du local

  @HiveField(2)
  String? zone; // Zone parente (si existe)

  @HiveField(3)
  String origineClassement; // Par défaut "KES I&P"

  // Influences externes - AF, BE, AE, AD, AG
  @HiveField(4)
  String? af; // Substances corrosives ou polluantes

  @HiveField(5)
  String? be; // Matières traitées ou entreposées

  @HiveField(6)
  String? ae; // Pénétration de corps solides

  @HiveField(7)
  String? ad; // Pénétration de liquides

  @HiveField(8)
  String? ag; // Risques de chocs mécaniques

  // Indices calculés automatiquement
  @HiveField(9)
  String? ip; // IP calculé (ex: IP30)

  @HiveField(10)
  String? ik; // IK calculé (ex: IK02)

  @HiveField(11)
  DateTime updatedAt;

  @HiveField(12)
  String? typeLocal; // Type du local (LOCAL_TRANSFORMATEUR, etc.)

  ClassementEmplacement({
    required this.missionId,
    required this.localisation,
    this.zone,
    this.origineClassement = 'KES I&P',
    this.af,
    this.be,
    this.ae,
    this.ad,
    this.ag,
    this.ip,
    this.ik,
    required this.updatedAt,
    this.typeLocal,
  });

  factory ClassementEmplacement.create({
    required String missionId,
    required String localisation,
    String? zone,
    String? typeLocal,
  }) {
    return ClassementEmplacement(
      missionId: missionId,
      localisation: localisation,
      zone: zone,
      origineClassement: 'KES I&P',
      updatedAt: DateTime.now(),
      typeLocal: typeLocal,
    );
  }

  // Méthode pour calculer automatiquement IP et IK
  void calculerIndices() {
    // Calcul IP à partir de AE et AD
    ip = _calculerIP();
    
    // Calcul IK à partir de AG
    ik = _calculerIK();
  }

  String? _calculerIP() {
    if (ae == null || ad == null) return null;
    
    // Extraire les chiffres d'AE et AD
    final aeNum = _extraireNumAE(ae!);
    final adNum = _extraireNumAD(ad!);
    
    if (aeNum == null || adNum == null) return null;
    
    return 'IP${aeNum}${adNum}';
  }

  String? _calculerIK() {
    if (ag == null) return null;
    
    switch (ag!) {
      case 'AG1': return 'IK02';
      case 'AG2': return 'IK07';
      case 'AG3': return 'IK08';
      case 'AG4': return 'IK10';
      default: return null;
    }
  }

  int? _extraireNumAE(String ae) {
    switch (ae) {
      case 'AE1': return 2;
      case 'AE2': return 3;
      case 'AE3': return 4;
      case 'AE4': return 5; // ou 6 selon spécification
      default: return null;
    }
  }

  int? _extraireNumAD(String ad) {
    switch (ad) {
      case 'AD1': return 0;
      case 'AD2': return 1;
      case 'AD3': return 2;
      case 'AD4': return 3;
      case 'AD5': return 4;
      case 'AD6': return 5;
      case 'AD7': return 6;
      case 'AD8': return 7;
      case 'AD9': return 8;
      default: return null;
    }
  }
}