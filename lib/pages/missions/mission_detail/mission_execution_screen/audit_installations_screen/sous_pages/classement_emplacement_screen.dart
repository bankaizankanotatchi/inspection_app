// classement_emplacement_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class ClassementEmplacementScreen extends StatefulWidget {
  final Mission mission;
  final ClassementEmplacement emplacement;

  const ClassementEmplacementScreen({
    super.key,
    required this.mission,
    required this.emplacement,
  });

  @override
  State<ClassementEmplacementScreen> createState() => _ClassementEmplacementScreenState();
}

class _ClassementEmplacementScreenState extends State<ClassementEmplacementScreen> {
  late ClassementEmplacement _emplacement;
  final _origineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emplacement = widget.emplacement;
    _origineController.text = _emplacement.origineClassement;
  }

  @override
  void dispose() {
    _origineController.dispose();
    super.dispose();
  }

  void _sauvegarder() async {
    _emplacement.origineClassement = _origineController.text.trim();
    _emplacement.calculerIndices(); // Recalculer IP/IK
    
    final success = await HiveService.updateEmplacement(_emplacement);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Classement sauvegardé')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
    }
  }

  void _annuler() {
    Navigator.pop(context);
  }

  // Méthode pour obtenir la description correcte selon le titre
  String _getDescriptionForTitle(String title, String code) {
    switch (title) {
      case 'AF - Substances corrosives ou polluantes':
        return HiveService.getDescriptionAF(code);
      case 'BE - Matières traitées ou entreposées':
        return HiveService.getDescriptionBE(code);
      case 'AE - Pénétration de corps solides':
        return HiveService.getDescriptionAE(code);
      case 'AD - Pénétration de liquides':
        return HiveService.getDescriptionAD(code);
      case 'AG - Risques de chocs mécaniques':
        return HiveService.getDescriptionAG(code);
      default:
        return code;
    }
  }

  Widget _buildSelecteur(String title, String? currentValue, List<String> options, Function(String?) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkBlue,
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  '$option',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildIndices() {
    // Recalculer les indices avant d'afficher
    _emplacement.calculerIndices();
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indices minimaux de protection (calculés automatiquement)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkBlue,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'IP',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _emplacement.ip ?? '--',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'IK',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _emplacement.ik ?? '--',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Calculés à partir des influences AE, AD et AG',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Classement: ${_emplacement.localisation}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _annuler,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _sauvegarder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on,
                      size: 28,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _emplacement.localisation,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (_emplacement.zone != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'Zone: ${_emplacement.zone}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (_emplacement.typeLocal != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'Type: ${_emplacement.typeLocal}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Origine classement
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Origine du classement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _origineController,
                    decoration: InputDecoration(
                      hintText: 'Ex: KES I&P',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Titre section influences
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Influences externes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
            ),
            
            // Sélecteurs d'influences
            _buildSelecteur(
              'AF - Substances corrosives ou polluantes',
              _emplacement.af,
              HiveService.getOptionsAF(),
              (value) => setState(() => _emplacement.af = value),
            ),
            
            _buildSelecteur(
              'BE - Matières traitées ou entreposées',
              _emplacement.be,
              HiveService.getOptionsBE(),
              (value) => setState(() => _emplacement.be = value),
            ),
            
            _buildSelecteur(
              'AE - Pénétration de corps solides',
              _emplacement.ae,
              HiveService.getOptionsAE(),
              (value) => setState(() => _emplacement.ae = value),
            ),
            
            _buildSelecteur(
              'AD - Pénétration de liquides',
              _emplacement.ad,
              HiveService.getOptionsAD(),
              (value) => setState(() => _emplacement.ad = value),
            ),
            
            _buildSelecteur(
              'AG - Risques de chocs mécaniques',
              _emplacement.ag,
              HiveService.getOptionsAG(),
              (value) => setState(() => _emplacement.ag = value),
            ),
            
            SizedBox(height: 20),
            
            // Indices calculés
            _buildIndices(),
            
            SizedBox(height: 30),
            
            // Boutons d'action
            Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sauvegarder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'SAUVEGARDER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _annuler,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'ANNULER',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
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
}