import 'package:hive/hive.dart';

part 'verificateur.g.dart';

@HiveType(typeId: 0)
class Verificateur extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String matricule;

  @HiveField(3)
  DateTime createdAt;

  Verificateur({
    required this.id,
    required this.nom,
    required this.matricule,
    required this.createdAt,
  });

  factory Verificateur.fromJson(Map<String, dynamic> json) {
    return Verificateur(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      matricule: json['matricule'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'matricule': matricule,
      'created_at': createdAt.toIso8601String(),
    };
  }
}