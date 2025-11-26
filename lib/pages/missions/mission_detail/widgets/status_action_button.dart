import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/mission_execution.dart';
import 'package:inspec_app/services/hive_service.dart';

class StatusActionButton extends StatefulWidget {
  final Mission mission;
  final Function(String)? onStatusChanged;

  const StatusActionButton({
    super.key,
    required this.mission,
    this.onStatusChanged,
  });

  @override
  State<StatusActionButton> createState() => _StatusActionButtonState();
}

class _StatusActionButtonState extends State<StatusActionButton> {
  bool _isUpdating = false;

  String _normalizeStatus(String status) {
    final lowerStatus = status.toLowerCase().trim();
    if (lowerStatus.contains('encour') || lowerStatus.contains('en cours')) return 'En cours';
    if (lowerStatus.contains('termine') || lowerStatus.contains('terminé')) return 'Terminé';
    if (lowerStatus.contains('attente')) return 'En attente';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _getButtonText(String status) {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'En attente':
        return 'Débuter';
      case 'En cours':
        return 'Continuer';
      case 'Terminé':
        return 'Cloturé';
      default:
        return 'Modifier';
    }
  }

  Color _getButtonColor(String status) {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'En attente':
        return Colors.green;
      case 'En cours':
        return Colors.orange;
      case 'Terminé':
        return Colors.grey; // Grisé pour "Cloturé"
      default:
        return AppTheme.primaryBlue;
    }
  }

  bool _isButtonEnabled(String status) {
    final normalizedStatus = _normalizeStatus(status);
    return normalizedStatus != 'Terminé'; // Désactivé seulement pour "Terminé"
  }

  Future<void> _handleStatusUpdate() async {
    if (_isUpdating) return;

    final normalizedStatus = _normalizeStatus(widget.mission.status);
    
    // Si le statut est "En attente", on passe à "En cours"
    if (normalizedStatus == 'En attente') {
      await _updateStatus('En cours');
    }
    
    // Navigation vers la page d'exécution pour "En attente" et "En cours"
    if (normalizedStatus == 'En attente' || normalizedStatus == 'En cours') {
      _navigateToMissionExecution();
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await HiveService.updateMissionStatus(
        missionId: widget.mission.id,
        newStatus: newStatus,
      );

      if (success) {
        // Notifier le parent du changement
        widget.onStatusChanged?.call(newStatus);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Statut mis à jour: $newStatus'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Erreur lors de la mise à jour'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _navigateToMissionExecution() {
    // Navigation vers la page d'exécution de mission
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MissionExecutionScreen(
          mission: widget.mission,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = _getButtonText(widget.mission.status);
    final buttonColor = _getButtonColor(widget.mission.status);
    final isEnabled = _isButtonEnabled(widget.mission.status);

    return ElevatedButton(
      onPressed: isEnabled && !_isUpdating ? _handleStatusUpdate : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isUpdating
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              buttonText,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
    );
  }
}