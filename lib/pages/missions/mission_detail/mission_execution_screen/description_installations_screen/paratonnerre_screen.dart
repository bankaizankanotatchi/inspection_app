import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class ParatonnerreScreen extends StatefulWidget {
  final Mission mission;

  const ParatonnerreScreen({super.key, required this.mission});

  @override
  State<ParatonnerreScreen> createState() => _ParatonnerreScreenState();
}

class _ParatonnerreScreenState extends State<ParatonnerreScreen> {
  String? _presenceParatonnerre;
  String? _analyseRisqueFoudre;
  String? _etudeTechniqueFoudre;

  @override
  void initState() {
    super.initState();
    _loadSelections();
  }

  void _loadSelections() async {
    final desc = await HiveService.getOrCreateDescriptionInstallations(widget.mission.id);
    
    setState(() {
      _presenceParatonnerre = desc.presenceParatonnerre;
      _analyseRisqueFoudre = desc.analyseRisqueFoudre;
      _etudeTechniqueFoudre = desc.etudeTechniqueFoudre;
    });
  }

  void _sauvegarder() async {
    final success1 = await HiveService.updateSelection(
      missionId: widget.mission.id,
      field: 'presence_paratonnerre',
      value: _presenceParatonnerre ?? '',
    );

    final success2 = await HiveService.updateSelection(
      missionId: widget.mission.id,
      field: 'analyse_risque_foudre',
      value: _analyseRisqueFoudre ?? '',
    );

    final success3 = await HiveService.updateSelection(
      missionId: widget.mission.id,
      field: 'etude_technique_foudre',
      value: _etudeTechniqueFoudre ?? '',
    );

    if (success1 && success2 && success3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sélections sauvegardées')),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildRadioGroup(String title, String? selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Column(
          children: [
            RadioListTile<String>(
              title: Text('OUI'),
              value: 'OUI',
              groupValue: selectedValue,
              onChanged: onChanged,
              activeColor: AppTheme.primaryBlue,
            ),
            Container(height: 1, color: Colors.grey.shade300),
            RadioListTile<String>(
              title: Text('NON'),
              value: 'NON',
              groupValue: selectedValue,
              onChanged: onChanged,
              activeColor: AppTheme.primaryBlue,
            ),
            Container(height: 1, color: Colors.grey.shade300),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Présence de paratonnerre'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _sauvegarder,
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildRadioGroup(
            'Présence de paratonnerre',
            _presenceParatonnerre,
            (value) => setState(() => _presenceParatonnerre = value),
          ),
          _buildRadioGroup(
            'Analyse risque foudre',
            _analyseRisqueFoudre,
            (value) => setState(() => _analyseRisqueFoudre = value),
          ),
          _buildRadioGroup(
            'Etude technique foudre',
            _etudeTechniqueFoudre,
            (value) => setState(() => _etudeTechniqueFoudre = value),
          ),
        ],
      ),
    );
  }
}