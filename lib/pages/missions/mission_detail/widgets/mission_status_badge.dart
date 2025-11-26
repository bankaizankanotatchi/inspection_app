import 'package:flutter/material.dart';

class MissionStatusBadge extends StatelessWidget {
  final String status;

  const MissionStatusBadge({
    super.key,
    required this.status,
  });

  String _normalizeStatus(String status) {
    final lowerStatus = status.toLowerCase().trim();
    
    if (lowerStatus.contains('encour') || lowerStatus.contains('en cours')) {
      return 'En cours';
    } else if (lowerStatus.contains('termine') || lowerStatus.contains('terminé')) {
      return 'Terminé';
    } else if (lowerStatus.contains('attente')) {
      return 'En attente';
    } else {
      return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

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

  IconData _getStatusIcon(String status) {
    final normalizedStatus = _normalizeStatus(status);
    
    switch (normalizedStatus) {
      case 'En attente':
        return Icons.pending_actions;
      case 'En cours':
        return Icons.play_arrow;
      case 'Terminé':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = _normalizeStatus(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              '$normalizedStatus',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}