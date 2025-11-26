import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';

class StatusSelectorModal extends StatefulWidget {
  final Mission mission;
  final Function(String)? onStatusChanged;

  const StatusSelectorModal({
    super.key,
    required this.mission,
    this.onStatusChanged,
  });

  @override
  State<StatusSelectorModal> createState() => _StatusSelectorModalState();
}

class _StatusSelectorModalState extends State<StatusSelectorModal> {
  String? _selectedStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.mission.status;
  }

  String _normalizeStatus(String status) {
    final lowerStatus = status.toLowerCase().trim();
    if (lowerStatus.contains('encour') || lowerStatus.contains('en cours')) return 'En cours';
    if (lowerStatus.contains('termine') || lowerStatus.contains('terminé')) return 'Terminé';
    if (lowerStatus.contains('attente')) return 'En attente';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
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

  List<String> get _availableStatuses => ['En attente', 'En cours', 'Terminé'];

  Future<void> _updateStatus() async {
    if (_selectedStatus == null || _selectedStatus == widget.mission.status) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await HiveService.updateMissionStatus(
        missionId: widget.mission.id,
        newStatus: _selectedStatus!,
      );

      if (success) {
        widget.onStatusChanged?.call(_selectedStatus!);
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Statut mis à jour: ${_normalizeStatus(_selectedStatus!)}'),
              ],
            ),
            backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Pas trop arrondi
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.update, color: AppTheme.primaryBlue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Changer le statut',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            Text(
              'Statut actuel: ${_normalizeStatus(widget.mission.status)}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Liste des statuts avec radios
            ..._availableStatuses.map((status) {
              final normalizedStatus = _normalizeStatus(status);
              final isSelected = _normalizeStatus(_selectedStatus!) == normalizedStatus;
              final statusColor = _getStatusColor(status);
              
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Radio<String>(
                    value: status,
                    groupValue: _selectedStatus,
                    onChanged: _isUpdating ? null : (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                    activeColor: statusColor,
                  ),
                  title: Text(
                    normalizedStatus,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? statusColor : AppTheme.darkBlue,
                    ),
                  ),
                  tileColor: isSelected ? statusColor.withOpacity(0.1) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: _isUpdating ? null : () {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                ),
              );
            }).toList(),
            
            SizedBox(height: 24),
            
            Row(
              children: [
                SizedBox(
                  child: ElevatedButton(
                    onPressed: _isUpdating || _selectedStatus == widget.mission.status
                        ? null 
                        : _updateStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
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
                        : Text('Appliquer'),
                  ),
                ),
                                SizedBox(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Annuler'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}