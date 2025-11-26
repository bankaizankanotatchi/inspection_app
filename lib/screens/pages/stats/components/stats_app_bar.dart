import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';

class StatsAppBar extends StatelessWidget {
  final String selectedPeriod;
  final String periodLabel;
  final bool isCustomPeriod;
  final VoidCallback onResetPeriod;

  const StatsAppBar({
    super.key,
    required this.selectedPeriod,
    required this.periodLabel,
    required this.isCustomPeriod,
    required this.onResetPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.lightBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCustomPeriod ? Icons.date_range : Icons.calendar_today,
              size: 20,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Période active',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  periodLabel,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isCustomPeriod)
            IconButton(
              icon: Icon(Icons.close, size: 20, color: AppTheme.primaryBlue),
              onPressed: onResetPeriod,
              tooltip: 'Réinitialiser',
            ),
        ],
      ),
    );
  }
}