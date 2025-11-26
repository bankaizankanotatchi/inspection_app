import 'package:flutter/material.dart';
import '../../../models/mission.dart';

class FilterDialog extends StatelessWidget {
  final String selectedFilter;
  final List<Mission> missions;
  final Function(List<Mission>) onFilterApplied;
  final Function(String) onFilterSelected;

  FilterDialog({
    super.key,
    required this.selectedFilter,
    required this.missions,
    required this.onFilterApplied,
    required this.onFilterSelected,
  });

  final List<String> _filterOptions = [
    'Tous',
    'Par nom client',
    'Par date d\'intervention',
    'Par date de création',
    'Par date de modification',
    'Par nature de mission',
    'Par activité client',
    'Par statut'
  ];

  void _applyFilter(String filter) {
    List<Mission> filtered = List.from(missions);

    switch (filter) {
      case 'Par date de création':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Par date de modification':
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'Par date d\'intervention':
        filtered.sort((a, b) {
          if (a.dateIntervention == null && b.dateIntervention == null) return 0;
          if (a.dateIntervention == null) return 1;
          if (b.dateIntervention == null) return -1;
          return b.dateIntervention!.compareTo(a.dateIntervention!);
        });
        break;
      case 'Par nom client':
        filtered.sort((a, b) => a.nomClient.compareTo(b.nomClient));
        break;
      case 'Par nature de mission':
        filtered.sort((a, b) {
          if (a.natureMission == null && b.natureMission == null) return 0;
          if (a.natureMission == null) return 1;
          if (b.natureMission == null) return -1;
          return a.natureMission!.compareTo(b.natureMission!);
        });
        break;
      case 'Par activité client':
        filtered.sort((a, b) {
          if (a.activiteClient == null && b.activiteClient == null) return 0;
          if (a.activiteClient == null) return 1;
          if (b.activiteClient == null) return -1;
          return a.activiteClient!.compareTo(b.activiteClient!);
        });
        break;
      case 'Par statut':
        filtered.sort((a, b) => _normalizeStatus(a.status).compareTo(_normalizeStatus(b.status)));
        break;
      case 'Tous':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    onFilterApplied(filtered);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('Filtrer les missions', style: TextStyle(fontSize: 18)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(0),
          itemCount: _filterOptions.length,
          itemBuilder: (context, index) {
            final option = _filterOptions[index];
            return RadioListTile<String>(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(option),
              value: option,
              groupValue: selectedFilter,
              onChanged: (value) {
                onFilterSelected(value!);
                _applyFilter(value);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onFilterSelected('Tous');
            onFilterApplied(missions);
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