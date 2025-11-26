import 'package:flutter/material.dart';
import '../../../models/mission.dart';

class SearchDialog extends StatefulWidget {
  final String searchQuery;
  final List<Mission> missions;
  final Function(List<Mission>) onSearchApplied;
  final Function(String) onSearchQueryChanged;

  const SearchDialog({
    super.key,
    required this.searchQuery,
    required this.missions,
    required this.onSearchApplied,
    required this.onSearchQueryChanged,
  });

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  void _applySearch(String query) {
    final filtered = widget.missions.where((mission) {
      final searchQuery = query.toLowerCase();
      return mission.nomClient.toLowerCase().contains(searchQuery) ||
          (mission.activiteClient?.toLowerCase().contains(searchQuery) ?? false) ||
          (mission.adresseClient?.toLowerCase().contains(searchQuery) ?? false) ||
          (mission.natureMission?.toLowerCase().contains(searchQuery) ?? false) ||
          mission.status.toLowerCase().contains(searchQuery);
    }).toList();

    widget.onSearchApplied(filtered);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('Rechercher une mission', style: TextStyle(fontSize: 14)),
      content: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'par nom, activité, adresse, statut...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onChanged: (value) {
          widget.onSearchQueryChanged(value);
          _applySearch(value);
        },
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          TextButton(
            onPressed: () {
              _searchController.clear();
              widget.onSearchQueryChanged('');
              widget.onSearchApplied(widget.missions);
            },
            child: const Text('Effacer'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}