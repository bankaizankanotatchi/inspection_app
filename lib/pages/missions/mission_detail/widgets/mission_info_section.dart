import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';

class MissionInfoSection extends StatelessWidget {
  final Mission mission;

  const MissionInfoSection({
    super.key,
    required this.mission,
  });

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryBlue,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Icons.info_outlined,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Informations Générales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (mission.natureMission != null)
              _buildInfoItem(
                'Nature de la mission',
                mission.natureMission!,
                Icons.assignment_outlined,
              ),
            
            if (mission.periodicite != null)
              _buildInfoItem(
                'Périodicité',
                mission.periodicite!,
                Icons.repeat_outlined,
              ),
            
            if (mission.dureeMissionJours != null)
              _buildInfoItem(
                'Durée estimée',
                '${mission.dureeMissionJours} jours',
                Icons.schedule_outlined,
              ),
            
            if (mission.dgResponsable != null)
              _buildInfoItem(
                'DG Responsable',
                mission.dgResponsable!,
                Icons.person_outline,
              ),
          ],
        ),
      ),
    );
  }
}