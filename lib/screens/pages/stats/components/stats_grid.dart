import 'package:flutter/material.dart';
import 'package:inspec_app/screens/pages/stats/widgets/stat_card_widget.dart';

class StatsGrid extends StatelessWidget {
  final int totalMissions;
  final int pendingMissions;
  final int inProgressMissions;
  final int completedMissions;

  const StatsGrid({
    super.key,
    required this.totalMissions,
    required this.pendingMissions,
    required this.inProgressMissions,
    required this.completedMissions,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 1,
      mainAxisSpacing: 1,
      padding: EdgeInsets.zero,
      children: [
        StatCardWidget(
          title: 'Total Missions',
          value: totalMissions.toString(),
          icon: Icons.assignment,
          color: Colors.blue,
        ),
        StatCardWidget(
          title: 'En attente',
          value: pendingMissions.toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        StatCardWidget(
          title: 'En cours',
          value: inProgressMissions.toString(),
          icon: Icons.play_arrow,
          color: Colors.blue,
        ),
        StatCardWidget(
          title: 'Terminées',
          value: completedMissions.toString(),
          icon: Icons.flag,
          color: Colors.green,
        ),
      ],
    );
  }
}