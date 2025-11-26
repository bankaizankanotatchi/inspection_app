import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';

class StatsEmptyState extends StatelessWidget {
  final VoidCallback onResetPeriod;

  const StatsEmptyState({
    super.key,
    required this.onResetPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Aucune mission trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkBlue,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'pour la période sélectionnée',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onResetPeriod,
            icon: Icon(Icons.refresh),
            label: Text('Voir ce mois'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}