import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';

class MissionTeamSection extends StatelessWidget {
  final Mission mission;

  const MissionTeamSection({
    super.key,
    required this.mission,
  });

  Widget _buildTeamList(String title, List<dynamic>? members, IconData icon) {
    if (members == null || members.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkBlue,
          ),
        ),
        SizedBox(height: 8),
        ...members.map((member) {
          final name = member is String ? member : member['nom'] ?? 'Inconnu';
          final matricule = member is Map ? member['matricule'] : null;
          
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                      if (matricule != null)
                        Text(
                          'Matricule: $matricule',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVerificateurs = mission.verificateurs != null && mission.verificateurs!.isNotEmpty;
    final hasAccompagnateurs = mission.accompagnateurs != null && mission.accompagnateurs!.isNotEmpty;

    if (!hasVerificateurs && !hasAccompagnateurs) {
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
                  Icons.people_outlined,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Équipe de Mission',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (hasVerificateurs)
              _buildTeamList(
                'Vérificateurs',
                mission.verificateurs,
                Icons.verified_user_outlined,
              ),
            
            if (hasAccompagnateurs)
              _buildTeamList(
                'Accompagnateurs',
                mission.accompagnateurs,
                Icons.person_outline,
              ),
          ],
        ),
      ),
    );
  }
}