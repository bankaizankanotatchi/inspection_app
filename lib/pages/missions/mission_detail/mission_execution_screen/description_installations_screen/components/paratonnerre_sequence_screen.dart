// paratonnerre_sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/constants/app_theme.dart';

class ParatonnerreSequenceScreen extends StatefulWidget {
  final Mission mission;
final void Function(String missionId) onComplete;
  final bool isComplete;

  const ParatonnerreSequenceScreen({
    super.key,
    required this.mission,
    required this.onComplete,
    required this.isComplete,
  });

  @override
  State<ParatonnerreSequenceScreen> createState() => _ParatonnerreSequenceScreenState();
}

class _ParatonnerreSequenceScreenState extends State<ParatonnerreSequenceScreen> {
  String? _presenceParatonnerre;
  String? _analyseRisqueFoudre;
  String? _etudeTechniqueFoudre;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelections();
  }

  Future<void> _loadSelections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final desc = await HiveService.getOrCreateDescriptionInstallations(widget.mission.id);
      
      setState(() {
        _presenceParatonnerre = desc.presenceParatonnerre;
        _analyseRisqueFoudre = desc.analyseRisqueFoudre;
        _etudeTechniqueFoudre = desc.etudeTechniqueFoudre;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    if (_presenceParatonnerre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner la présence de paratonnerre'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    if (_analyseRisqueFoudre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner l\'analyse risque foudre'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    if (_etudeTechniqueFoudre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner l\'étude technique foudre'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    return true;
  }

  Future<void> _saveSelections() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success1 = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: 'presence_paratonnerre',
        value: _presenceParatonnerre!,
      );

      final success2 = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: 'analyse_risque_foudre',
        value: _analyseRisqueFoudre!,
      );

      final success3 = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: 'etude_technique_foudre',
        value: _etudeTechniqueFoudre!,
      );

      if (success1 && success2 && success3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sélections sauvegardées'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onComplete(widget.mission.id);
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
        _isLoading = false;
      });
    }
  }

  Widget _buildRadioGroup(String title, String? selectedValue, Function(String?) onChanged) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onChanged('OUI'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selectedValue == 'OUI' 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.transparent,
                      side: BorderSide(
                        color: selectedValue == 'OUI' 
                            ? Colors.green 
                            : Colors.grey.shade300,
                        width: selectedValue == 'OUI' ? 2 : 1,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'OUI',
                      style: TextStyle(
                        color: selectedValue == 'OUI' ? Colors.green : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onChanged('NON'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selectedValue == 'NON' 
                          ? Colors.red.withOpacity(0.1) 
                          : Colors.transparent,
                      side: BorderSide(
                        color: selectedValue == 'NON' 
                            ? Colors.red 
                            : Colors.grey.shade300,
                        width: selectedValue == 'NON' ? 2 : 1,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'NON',
                      style: TextStyle(
                        color: selectedValue == 'NON' ? Colors.red : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.check_circle, 
                color: widget.isComplete ? Colors.green : Colors.grey.shade300,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Paratonnerre',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Toutes les sélections sont obligatoires',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 32),

          // Options de sélection
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView(
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
          ),

          // Bouton d'action
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSelections,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text('SAUVEGARDER'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}