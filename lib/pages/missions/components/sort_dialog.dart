import 'package:flutter/material.dart';
import '../../../models/mission.dart';
import '../../../constants/app_theme.dart';

class SortDialog extends StatefulWidget {
  final String selectedFilter;
  final List<Mission> missions;
  final Function(List<Mission>) onFilterApplied;
  final Function(String) onFilterSelected;

  const SortDialog({
    super.key,
    required this.selectedFilter,
    required this.missions,
    required this.onFilterApplied,
    required this.onFilterSelected,
  });

  @override
  State<SortDialog> createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  Widget _buildSortSection({
    required String title,
    required IconData icon,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ...options.map((option) => RadioListTile<String>(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          dense: true,
          title: Text(option, style: const TextStyle(fontSize: 14)),
          value: option,
          groupValue: widget.selectedFilter.contains(option) ? option : null,
          onChanged: (value) {
            onSelected(value!);
          },
        )),
      ],
    );
  }

  void _filterByStatus(String status) {
    final filtered = widget.missions.where((mission) {
      return _normalizeStatus(mission.status) == status;
    }).toList();

    widget.onFilterSelected('Par statut: $status');
    widget.onFilterApplied(filtered);
  }

  void _filterByPeriod(String period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (period) {
      case 'Aujourd\'hui':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Cette semaine':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'Ce mois':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Cette année':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'Période personnalisée':
        _showCustomDateRangeDialog();
        return;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    final filtered = widget.missions.where((mission) {
      final missionDate = mission.createdAt;
      return missionDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
             missionDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    widget.onFilterSelected('Par période: $period');
    widget.onFilterApplied(filtered);
  }

  void _showCustomDateRangeDialog() {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Text('Période personnalisée', style: TextStyle(fontSize: 18)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                    title: const Text('Date de début'),
                    subtitle: Text(
                      startDate != null ? _formatDate(startDate!) : 'Non sélectionnée',
                      style: TextStyle(
                        color: startDate != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppTheme.primaryBlue,
                                onPrimary: Colors.white,
                                onSurface: AppTheme.darkBlue,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (selectedDate != null) {
                        setDialogState(() {
                          startDate = selectedDate;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                    title: const Text('Date de fin'),
                    subtitle: Text(
                      endDate != null ? _formatDate(endDate!) : 'Non sélectionnée',
                      style: TextStyle(
                        color: endDate != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppTheme.primaryBlue,
                                onPrimary: Colors.white,
                                onSurface: AppTheme.darkBlue,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (selectedDate != null) {
                        setDialogState(() {
                          endDate = selectedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
                onPressed: startDate != null && endDate != null
                    ? () {
                        if (startDate!.isAfter(endDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La date de début doit être avant la date de fin'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        // Fermer le dialog personnalisé d'abord
                        Navigator.of(context).pop();
                        
                        // Appliquer le filtre personnalisé
                        _applyCustomDateRange(startDate!, endDate!);
                      }
                    : null,
                child: const Text('Appliquer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _applyCustomDateRange(DateTime startDate, DateTime endDate) {
    // S'assurer que la date de début commence à 00:00:00
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    // S'assurer que la date de fin termine à 23:59:59
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    final filtered = widget.missions.where((mission) {
      final missionDate = mission.createdAt;
      return missionDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
             missionDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    widget.onFilterSelected('Période: ${_formatDate(startDate)} - ${_formatDate(endDate)}');
    widget.onFilterApplied(filtered);
    
    // Fermer aussi le dialog principal de tri
    Navigator.of(context).pop();
  }

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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('Trier les missions', style: TextStyle(fontSize: 18)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortSection(
                title: 'Par statut',
                icon: Icons.flag_outlined,
                options: ['En attente', 'En cours', 'Terminé'],
                onSelected: (value) {
                  Navigator.of(context).pop();
                  _filterByStatus(value);
                },
              ),
              const Divider(height: 24),
              _buildSortSection(
                title: 'Par période',
                icon: Icons.calendar_today_outlined,
                options: ['Aujourd\'hui', 'Cette semaine', 'Ce mois', 'Cette année', 'Période personnalisée'],
                onSelected: (value) {
                  if (value != 'Période personnalisée') {
                    Navigator.of(context).pop();
                    _filterByPeriod(value);
                  } else {
                    _filterByPeriod(value); // Le dialog personnalisé gère la fermeture
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onFilterSelected('Tous');
            widget.onFilterApplied(widget.missions);
            Navigator.of(context).pop();
          },
          child: const Text('Réinitialiser'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}