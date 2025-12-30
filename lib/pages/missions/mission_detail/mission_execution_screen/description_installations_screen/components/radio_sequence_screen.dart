// radio_sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/constants/app_theme.dart';

class RadioSequenceScreen extends StatefulWidget {
  final Mission mission;
  final String title;
  final String field;
  final List<String> options;
final void Function(String field) onComplete;
  final bool isComplete;

  const RadioSequenceScreen({
    super.key,
    required this.mission,
    required this.title,
    required this.field,
    required this.options,
    required this.onComplete,
    required this.isComplete,
  });

  @override
  State<RadioSequenceScreen> createState() => _RadioSequenceScreenState();
}

class _RadioSequenceScreenState extends State<RadioSequenceScreen> {
  String? _selectedOption;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSelection();
  }

  Future<void> _loadCurrentSelection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final desc = await HiveService.getOrCreateDescriptionInstallations(widget.mission.id);
      
      setState(() {
        switch (widget.field) {
          case 'regime_neutre':
            _selectedOption = desc.regimeNeutre;
            break;
          case 'eclairage_securite':
            _selectedOption = desc.eclairageSecurite;
            break;
          case 'modifications_installations':
            _selectedOption = desc.modificationsInstallations;
            break;
          case 'note_calcul':
            _selectedOption = desc.noteCalcul;
            break;
          case 'registre_securite':
            _selectedOption = desc.registreSecurite;
            break;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelection() async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une option'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: widget.field,
        value: _selectedOption!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Option sauvegardée'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onComplete(widget.field);
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
                  widget.title,
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
            'Sélectionnez une option (obligatoire)',
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
                : ListView.builder(
                    itemCount: widget.options.length,
                    itemBuilder: (context, index) {
                      final option = widget.options[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedOption == option 
                                ? AppTheme.primaryBlue 
                                : Colors.grey.shade300,
                            width: _selectedOption == option ? 2 : 1,
                          ),
                        ),
                        elevation: 0,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          leading: Radio<String>(
                            value: option,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                              });
                            },
                            activeColor: AppTheme.primaryBlue,
                          ),
                          title: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedOption = option;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Bouton d'action
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSelection,
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