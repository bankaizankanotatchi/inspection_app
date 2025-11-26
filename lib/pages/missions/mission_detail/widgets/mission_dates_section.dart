import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';

class MissionDatesSection extends StatelessWidget {
  final Mission mission;

  const MissionDatesSection({
    super.key,
    required this.mission,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildDateItem(String label, DateTime? date, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
                  date != null ? _formatDate(date) : 'Non définie',
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
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
                  Icons.calendar_today_outlined,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Dates Importantes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (mission.dateIntervention != null)
              _buildDateItem(
                'Date d\'intervention',
                mission.dateIntervention!,
                Icons.event_available_outlined,
                Colors.green,
              ),
            
            if (mission.dateRapport != null)
              _buildDateItem(
                'Date de rapport',
                mission.dateRapport!,
                Icons.description_outlined,
                Colors.blue,
              ),
            
            _buildDateItem(
              'Créée le',
              mission.createdAt,
              Icons.create_outlined,
              Colors.orange,
            ),
            
            _buildDateItem(
              'Modifiée le',
              mission.updatedAt,
              Icons.update_outlined,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}