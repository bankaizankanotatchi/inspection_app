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
  
  // Variables de validation
  bool _origineValid = false;
  bool _afValid = false;
  bool _beValid = false;
  bool _aeValid = false;
  bool _adValid = false;
  bool _agValid = false;

  @override
  void initState() {
    super.initState();
    _emplacement = widget.emplacement;
    _origineController.text = _emplacement.origineClassement;
    
    // Valider les champs existants
    _origineValid = _emplacement.origineClassement.isNotEmpty;
    _afValid = _emplacement.af != null && _emplacement.af!.isNotEmpty;
    _beValid = _emplacement.be != null && _emplacement.be!.isNotEmpty;
    _aeValid = _emplacement.ae != null && _emplacement.ae!.isNotEmpty;
    _adValid = _emplacement.ad != null && _emplacement.ad!.isNotEmpty;
    _agValid = _emplacement.ag != null && _emplacement.ag!.isNotEmpty;
  }

  @override
  void dispose() {
    _origineController.dispose();
    super.dispose();
  }

  // Méthodes de validation
  void _validateOrigine(String value) {
    setState(() {
      _origineValid = value.trim().isNotEmpty;
    });
  }

  void _validateAF(String? value) {
    setState(() {
      _afValid = value != null && value.isNotEmpty;
    });
  }

  void _validateBE(String? value) {
    setState(() {
      _beValid = value != null && value.isNotEmpty;
    });
  }

  void _validateAE(String? value) {
    setState(() {
      _aeValid = value != null && value.isNotEmpty;
    });
  }

  void _validateAD(String? value) {
    setState(() {
      _adValid = value != null && value.isNotEmpty;
    });
  }

  void _validateAG(String? value) {
    setState(() {
      _agValid = value != null && value.isNotEmpty;
    });
  }

  bool _validateAllFields() {
    bool allValid = true;
    
    // Valider origine
    if (_origineController.text.trim().isEmpty) {
      _origineValid = false;
      allValid = false;
    }
    
    // Valider AF
    if (_emplacement.af == null || _emplacement.af!.isEmpty) {
      _afValid = false;
      allValid = false;
    }
    
    // Valider BE
    if (_emplacement.be == null || _emplacement.be!.isEmpty) {
      _beValid = false;
      allValid = false;
    }
    
    // Valider AE
    if (_emplacement.ae == null || _emplacement.ae!.isEmpty) {
      _aeValid = false;
      allValid = false;
    }
    
    // Valider AD
    if (_emplacement.ad == null || _emplacement.ad!.isEmpty) {
      _adValid = false;
      allValid = false;
    }
    
    // Valider AG
    if (_emplacement.ag == null || _emplacement.ag!.isEmpty) {
      _agValid = false;
      allValid = false;
    }
    
    setState(() {});
    return allValid;
  }

void _sauvegarder() async {
  // Valider tous les champs avant sauvegarde
  if (!_validateAllFields()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Veuillez remplir tous les champs obligatoires'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  _emplacement.origineClassement = _origineController.text.trim();
  _emplacement.calculerIndices();
  
  final success = await HiveService.updateEmplacement(_emplacement);
  
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Classement sauvegardé'),
        backgroundColor: Colors.green,
      ),
    );
    // Retourner true pour indiquer succès
    Navigator.pop(context, true);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors de la sauvegarde'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _annuler() {
  // Retourner false pour indiquer annulation
  Navigator.pop(context, false);
}

Widget _buildSelecteur(String title, String? currentValue, List<String> options, Function(String?) onChanged, {required bool isValid}) {
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isValid ? Colors.grey.shade300 : Colors.red,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$title*', // Astérisque pour indiquer l'obligation
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isValid ? AppTheme.darkBlue : Colors.red,
              ),
            ),
            if (!isValid)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  '(obligatoire)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isValid ? Colors.grey.shade400 : Colors.red,
              ),
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
          onChanged: (value) {
            onChanged(value);
            // Valider le champ après changement
            switch (title) {
              case 'AF - Substances corrosives ou polluantes*':
                _validateAF(value);
                break;
              case 'BE - Matières traitées ou entreposées*':
                _validateBE(value);
                break;
              case 'AE - Pénétration de corps solides*':
                _validateAE(value);
                break;
              case 'AD - Pénétration de liquides*':
                _validateAD(value);
                break;
              case 'AG - Risques de chocs mécaniques*':
                _validateAG(value);
                break;
            }
          },
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
            // Message d'information
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TOUS LES CHAMPS SONT OBLIGATOIRES',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
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
                border: Border.all(
                  color: _origineValid ? Colors.grey.shade300 : Colors.red,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Origine du classement*',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _origineValid ? AppTheme.darkBlue : Colors.red,
                        ),
                      ),
                      if (!_origineValid)
                        Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            '(obligatoire)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _origineController,
                    onChanged: _validateOrigine,
                    decoration: InputDecoration(
                      hintText: 'Ex: KES I&P',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _origineValid ? Colors.grey : Colors.red,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _origineValid ? Colors.grey : Colors.red,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _origineValid ? Colors.blue : Colors.red,
                        ),
                      ),
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
                'Influences externes (tous les champs sont obligatoires)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
            ),
            
            // Sélecteurs d'influences
            _buildSelecteur(
              'AF - Substances corrosives ou polluantes*',
              _emplacement.af,
              HiveService.getOptionsAF(),
              (value) => setState(() => _emplacement.af = value),
              isValid: _afValid,
            ),
            
            _buildSelecteur(
              'BE - Matières traitées ou entreposées*',
              _emplacement.be,
              HiveService.getOptionsBE(),
              (value) => setState(() => _emplacement.be = value),
              isValid: _beValid,
            ),
            
            _buildSelecteur(
              'AE - Pénétration de corps solides*',
              _emplacement.ae,
              HiveService.getOptionsAE(),
              (value) => setState(() => _emplacement.ae = value),
              isValid: _aeValid,
            ),
            
            _buildSelecteur(
              'AD - Pénétration de liquides*',
              _emplacement.ad,
              HiveService.getOptionsAD(),
              (value) => setState(() => _emplacement.ad = value),
              isValid: _adValid,
            ),
            
            _buildSelecteur(
              'AG - Risques de chocs mécaniques*',
              _emplacement.ag,
              HiveService.getOptionsAG(),
              (value) => setState(() => _emplacement.ag = value),
              isValid: _agValid,
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