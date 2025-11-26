import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/screens/pages/stats/widgets/recent_mission_item_widget.dart';

class StatsRecentMissions extends StatelessWidget {
  final List<Mission> recentMissions;

  const StatsRecentMissions({
    super.key,
    required this.recentMissions,
  });

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
                Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Missions récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...recentMissions.map((mission) => RecentMissionItemWidget(mission: mission)),
            if (recentMissions.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Aucune mission dans cette période',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}