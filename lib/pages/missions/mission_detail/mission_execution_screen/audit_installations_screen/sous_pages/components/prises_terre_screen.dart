import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class PrisesTerreScreen extends StatefulWidget {
  final Mission mission;

  const PrisesTerreScreen({super.key, required this.mission});

  @override
  State<PrisesTerreScreen> createState() => _PrisesTerreScreenState();
}

class _PrisesTerreScreenState extends State<PrisesTerreScreen> {
  List<PriseTerre> _prisesTerre = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrisesTerre();
  }

  Future<void> _loadPrisesTerre() async {
    setState(() => _isLoading = true);
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      _prisesTerre = mesures.prisesTerre;
    } catch (e) {
      print('❌ Erreur chargement prises terre: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _ajouterPriseTerre() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterPriseTerreScreen(
          mission: widget.mission,
        ),
      ),
    );

    if (result == true) {
      await _loadPrisesTerre();
    }
  }

  void _editerPriseTerre(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterPriseTerreScreen(
          mission: widget.mission,
          priseTerre: _prisesTerre[index],
          index: index,
        ),
      ),
    );

    if (result == true) {
      await _loadPrisesTerre();
    }
  }

  Future<void> _supprimerPriseTerre(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression', style: TextStyle(fontSize: 18)),
        content: Text('Voulez-vous vraiment supprimer cette prise de terre ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await HiveService.deletePriseTerre(
                missionId: widget.mission.id,
                index: index,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Prise de terre supprimée'),
                    backgroundColor: Colors.green,
                  ),
                );
                await _loadPrisesTerre();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriseTerreCard(PriseTerre priseTerre, int index) {
    
    Color cardColor;
      cardColor = Colors.grey;
    

    return  Container(
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey
        ),
      ),
      child: InkWell(
        onTap: () => _editerPriseTerre(index),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec identification et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardColor),
                    ),
                    child: Row(
                      children: [
                        Text(
                          priseTerre.identification,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editerPriseTerre(index);
                      } else if (value == 'delete') {
                        _supprimerPriseTerre(index);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Localisation
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      priseTerre.localisation,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Détails
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                      // Observation
                    if (priseTerre.conditionMesure.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Condition de mesure',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            priseTerre.conditionMesure!,
                            style: TextStyle(
                              fontSize: 14,
                                fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                   
                          SizedBox(height: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nature',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              priseTerre.naturePriseTerre,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                         SizedBox(height: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Méthode',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              priseTerre.methodeMesure,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    
                    SizedBox(height: 12),
                    
                    // Valeur de mesure
                    if (priseTerre.valeurMesure != null)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: cardColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Valeur mesurée',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${priseTerre.valeurMesure!.toStringAsFixed(2)} Ω',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: 12),
                    
                    // Observation
                    if (priseTerre.observation != null && priseTerre.observation!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Observation',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            priseTerre.observation!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prises de terre'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterPriseTerre,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                
                if (_prisesTerre.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune prise de terre',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Cliquez sur le bouton + pour ajouter une prise de terre',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadPrisesTerre,
                      child: ListView.builder(
                        itemCount: _prisesTerre.length,
                        itemBuilder: (context, index) {
                          return _buildPriseTerreCard(_prisesTerre[index], index);
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// Écran pour ajouter/modifier une prise de terre
class AjouterPriseTerreScreen extends StatefulWidget {
  final Mission mission;
  final PriseTerre? priseTerre;
  final int? index;

  const AjouterPriseTerreScreen({
    super.key,
    required this.mission,
    this.priseTerre,
    this.index,
  });

  bool get isEdition => priseTerre != null;

  @override
  State<AjouterPriseTerreScreen> createState() => _AjouterPriseTerreScreenState();
}

class _AjouterPriseTerreScreenState extends State<AjouterPriseTerreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localisationController = TextEditingController();
  final _identificationController = TextEditingController();
  final _conditionController = TextEditingController();
  final _natureController = TextEditingController();
  final _methodeController = TextEditingController();
  final _valeurController = TextEditingController();
  final _observationController = TextEditingController();
  


  @override
  void initState() {
    super.initState();
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    } else {
      _natureController.text = 'Boucle en fond de fouille';
      _methodeController.text = 'Impédance de boucle';
      _conditionController.text = '-';
    }
  }

  void _chargerDonneesExistantes() {
    final pt = widget.priseTerre!;
    _localisationController.text = pt.localisation;
    _identificationController.text = pt.identification;
    _conditionController.text = pt.conditionMesure;
    _natureController.text = pt.naturePriseTerre;
    _methodeController.text = pt.methodeMesure;
    if (pt.valeurMesure != null) {
      _valeurController.text = pt.valeurMesure!.toString();
    }
    if (pt.observation != null) {
      _observationController.text = pt.observation!;
    }
  
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      final priseTerre = PriseTerre(
        localisation: _localisationController.text.trim(),
        identification: _identificationController.text.trim(),
        conditionMesure: _conditionController.text.trim(),
        naturePriseTerre: _natureController.text.trim(),
        methodeMesure: _methodeController.text.trim(),
        valeurMesure: _valeurController.text.trim().isNotEmpty 
            ? double.tryParse(_valeurController.text.trim())
            : null,
        observation: _observationController.text.trim().isNotEmpty
            ? _observationController.text.trim()
            : null,
       
      );

      bool success;
      if (widget.isEdition) {
        success = await HiveService.updatePriseTerre(
          missionId: widget.mission.id,
          index: widget.index!,
          priseTerre: priseTerre,
        );
      } else {
        success = await HiveService.addPriseTerre(
          missionId: widget.mission.id,
          priseTerre: priseTerre,
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdition ? 'Prise de terre modifiée' : 'Prise de terre ajoutée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError('Erreur lors de la sauvegarde');
      }
    }
  }

  void _annuler() {
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = true, int maxLines = 1}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: '$label${isRequired ? '*' : ''}',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: maxLines,
            validator: isRequired ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir $label';
              }
              return null;
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value, Function(String?) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: SizedBox(),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
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
        title: Text(widget.isEdition ? 'Modifier prise terre' : 'Ajouter prise terre'),
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Formulaire
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildTextField('Localisation', _localisationController),
                    _buildTextField('Identification (PT1, PT2...)', _identificationController),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Condition mesure', _conditionController),
                        ),
                      ],
                    ),
                    
                    _buildDropdown(
                      'Nature prise de terre',
                      HiveService.getNaturesPriseTerre(),
                      _natureController.text,
                      (value) {
                        if (value != null) {
                          setState(() => _natureController.text = value);
                        }
                      },
                    ),
                    
                    _buildDropdown(
                      'Méthode de mesure',
                      HiveService.getMethodesMesure(),
                      _methodeController.text,
                      (value) {
                        if (value != null) {
                          setState(() => _methodeController.text = value);
                        }
                      },
                    ),
                    
                    _buildTextField('Valeur mesurée (Ω)', _valeurController, isRequired: false),
                    
                    _buildTextField('Observation', _observationController, isRequired: false, maxLines: 3),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Boutons d'action
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _sauvegarder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.isEdition ? 'MODIFIER' : 'AJOUTER',
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
      ),
    );
  }

  @override
  void dispose() {
    _localisationController.dispose();
    _identificationController.dispose();
    _conditionController.dispose();
    _natureController.dispose();
    _methodeController.dispose();
    _valeurController.dispose();
    _observationController.dispose();
    super.dispose();
  }
}