// foudre.dart
import 'package:hive/hive.dart';

part 'foudre.g.dart';

@HiveType(typeId: 15)
class Foudre extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  String observation; // Description de l'observation

  @HiveField(2)
  int niveauPriorite; // 1, 2 ou 3

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  Foudre({
    required this.missionId,
    required this.observation,
    required this.niveauPriorite,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(niveauPriorite >= 1 && niveauPriorite <= 3, 
           'Le niveau de priorité doit être compris entre 1 et 3');

  // Constructeur de création simplifié
  factory Foudre.create({
    required String missionId,
    required String observation,
    required int niveauPriorite,
  }) {
    final now = DateTime.now();
    return Foudre(
      missionId: missionId,
      observation: observation,
      niveauPriorite: niveauPriorite,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Factory pour créer à partir du JSON
  factory Foudre.fromJson(Map<String, dynamic> json) {
    return Foudre(
      missionId: json['mission_id'] ?? '',
      observation: json['observation'] ?? '',
      niveauPriorite: json['niveau_priorite'] ?? 2,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  // Méthode pour convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'mission_id': missionId,
      'observation': observation,
      'niveau_priorite': niveauPriorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}