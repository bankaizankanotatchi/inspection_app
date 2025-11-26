import 'package:flutter/material.dart';
import '../../../../models/mission.dart';
import '../../../../constants/app_theme.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;

  const MissionCard({super.key, required this.mission});

  // Méthode pour normaliser le statut (gérer les fautes de frappe)
  String _normalizeStatus(String status) {
    final lowerStatus = status.toLowerCase().trim();
    
    if (lowerStatus.contains('encour') || lowerStatus.contains('en cours')) {
      return 'En cours';
    } else if (lowerStatus.contains('termine') || lowerStatus.contains('terminé')) {
      return 'Terminé';
    } else if (lowerStatus.contains('attente')) {
      return 'En attente';
    } else {
      // Retourner le statut original avec première lettre en majuscule
      return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  // Méthode pour obtenir la couleur du badge selon le statut
  Color _getStatusColor(String status) {
    final normalizedStatus = _normalizeStatus(status);
    
    switch (normalizedStatus) {
      case 'En attente':
        return Colors.orange;
      case 'En cours':
        return Colors.blue;
      case 'Terminé':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = _normalizeStatus(mission.status);
    final statusColor = _getStatusColor(mission.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mission: ${mission.nomClient} - Statut: $normalizedStatus'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (mission.logoClient != null)
                    Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: AppTheme.greyLight,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          mission.logoClient!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.business, color: AppTheme.primaryBlue);
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.nomClient,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (mission.activiteClient != null)
                          Text(
                            mission.activiteClient!,
                            style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Badge de statut
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  normalizedStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (mission.adresseClient != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppTheme.greyDark),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mission.adresseClient!,
                        style: TextStyle(fontSize: 13, color: AppTheme.greyDark),
                      ),
                    ),
                  ],
                ),
              ],
              if (mission.dateIntervention != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.greyDark),
                    const SizedBox(width: 4),
                    Text(
                      'Intervention: ${_formatDate(mission.dateIntervention!)}',
                      style: TextStyle(fontSize: 13, color: AppTheme.greyDark),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.greyDark),
                  const SizedBox(width: 4),
                  Text(
                    'Créé: ${_formatDate(mission.createdAt)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.greyDark),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.update, size: 14, color: AppTheme.greyDark),
                  const SizedBox(width: 4),
                  Text(
                    'Modifié: ${_formatDate(mission.updatedAt)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.greyDark),
                  ),
                ],
              ),
              if (mission.natureMission != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    mission.natureMission!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}