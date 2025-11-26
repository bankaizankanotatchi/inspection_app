import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/screens/pages/stats/widgets/distribution_item_widget.dart';

class StatsStatusDistribution extends StatelessWidget {
  final int pendingMissions;
  final int inProgressMissions;
  final int completedMissions;
  final int totalMissions;

  const StatsStatusDistribution({
    super.key,
    required this.pendingMissions,
    required this.inProgressMissions,
    required this.completedMissions,
    required this.totalMissions,
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
                Icon(Icons.pie_chart, color: AppTheme.primaryBlue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Répartition des missions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            DistributionItemWidget(
              status: 'En attente',
              count: pendingMissions,
              total: totalMissions,
              color: Colors.orange,
            ),
            DistributionItemWidget(
              status: 'En cours',
              count: inProgressMissions,
              total: totalMissions,
              color: Colors.blue,
            ),
            DistributionItemWidget(
              status: 'Terminé',
              count: completedMissions,
              total: totalMissions,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}