import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';

class RecentMissionItemWidget extends StatelessWidget {
  final Mission mission;

  const RecentMissionItemWidget({
    super.key,
    required this.mission,
  });

  Color _getStatusColor(String status) {
    final normalized = _normalizeStatus(status);
    switch (normalized) {
      case 'En attente': return Colors.orange;
      case 'En cours': return Colors.blue;
      case 'Terminé': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _normalizeStatus(String status) {
    final lowerStatus = status.toLowerCase().trim();
    if (lowerStatus.contains('encour') || lowerStatus.contains('en cours')) return 'En cours';
    if (lowerStatus.contains('termine') || lowerStatus.contains('terminé')) return 'Terminé';
    if (lowerStatus.contains('attente')) return 'En attente';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(mission.status),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.nomClient,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.darkBlue,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(mission.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _normalizeStatus(mission.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(mission.status),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.access_time, size: 12, color: AppTheme.textLight),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(mission.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}