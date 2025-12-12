import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class EssaisDeclenchementScreen extends StatefulWidget {
  final Mission mission;

  const EssaisDeclenchementScreen({super.key, required this.mission});

  @override
  State<EssaisDeclenchementScreen> createState() => _EssaisDeclenchementScreenState();
}

class _EssaisDeclenchementScreenState extends State<EssaisDeclenchementScreen> {
  List<EssaiDeclenchementDifferentiel> _essais = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEssais();
  }

  Future<void> _loadEssais() async {
    setState(() => _isLoading = true);
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      _essais = mesures.essaisDeclenchement;
    } catch (e) {
      print('❌ Erreur chargement essais déclenchement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _ajouterEssai() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterEssaiDeclenchementScreen(
          mission: widget.mission,
        ),
      ),
    );

    if (result == true) {
      await _loadEssais();
    }
  }

  void _editerEssai(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterEssaiDeclenchementScreen(
          mission: widget.mission,
          essai: _essais[index],
          index: index,
        ),
      ),
    );

    if (result == true) {
      await _loadEssais();
    }
  }

  Future<void> _supprimerEssai(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression', style: TextStyle(fontSize: 18)),
        content: Text('Voulez-vous vraiment supprimer cet essai ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await HiveService.deleteEssaiDeclenchement(
                missionId: widget.mission.id,
                index: index,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Essai supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
                await _loadEssais();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEssaiCard(EssaiDeclenchementDifferentiel essai, int index) {
    Color cardColor;
    String statutText;
    IconData statutIcon;
    
    switch (essai.essai) {
      case 'OK':
        cardColor = Colors.green;
        statutText = 'OK';
        statutIcon = Icons.check_circle;
        break;
      case 'NON OK':
        cardColor = Colors.red;
        statutText = 'NON OK';
        statutIcon = Icons.warning;
        break;
      default:
        cardColor = Colors.grey;
        statutText = 'NON ESSAYÉ';
        statutIcon = Icons.help_outline;
    }

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
        onTap: () => _editerEssai(index),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
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
                        Icon(statutIcon, size: 14, color: cardColor),
                        SizedBox(width: 6),
                        Text(
                          statutText,
                          style: TextStyle(
                            fontSize: 12,
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
                        _editerEssai(index);
                      } else if (value == 'delete') {
                        _supprimerEssai(index);
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
              
              // Circuit et localisation
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if(essai.designationCircuit != null && essai.designationCircuit!.isNotEmpty) ...[
                  Text(
                    essai.designationCircuit!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  ],
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          essai.localisation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (essai.coffret != null && essai.coffret!.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.electrical_services, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Text(
                          essai.coffret!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              
              SizedBox(height: 12),
              
              // Paramètres techniques
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              essai.typeDispositifComplet,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (essai.reglageIAn != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Réglage IΔn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${essai.reglageIAn} mA',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (essai.tempo != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Temporisation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${essai.tempo} s',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        if (essai.isolement != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Isolement',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${essai.isolement} MΩ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    if (essai.observation != null && essai.observation!.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Divider(),
                      SizedBox(height: 8),
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
                            essai.observation!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
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
        title: Text('Essais déclenchement'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterEssai,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                
                if (_essais.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flash_on_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucun essai de déclenchement',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Cliquez sur le bouton + pour ajouter un essai',
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
                      onRefresh: _loadEssais,
                      child: ListView.builder(
                        itemCount: _essais.length,
                        itemBuilder: (context, index) {
                          return _buildEssaiCard(_essais[index], index);
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// Écran pour ajouter/modifier un essai
class AjouterEssaiDeclenchementScreen extends StatefulWidget {
  final Mission mission;
  final EssaiDeclenchementDifferentiel? essai;
  final int? index;

  const AjouterEssaiDeclenchementScreen({
    super.key,
    required this.mission,
    this.essai,
    this.index,
  });

  bool get isEdition => essai != null;

  @override
  State<AjouterEssaiDeclenchementScreen> createState() => _AjouterEssaiDeclenchementScreenState();
}

class _AjouterEssaiDeclenchementScreenState extends State<AjouterEssaiDeclenchementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localisationController = TextEditingController();
  final _coffretController = TextEditingController();
  final _circuitController = TextEditingController();
  final _reglageController = TextEditingController();
  final _tempoController = TextEditingController();
  final _isolementController = TextEditingController();
  final _observationController = TextEditingController();
  
  String _selectedType = 'DDR';
  String _selectedResultat = 'NE';
  
  List<String> _localisations = [];
  List<String> _coffrets = [];

  @override
  void initState() {
    super.initState();
    _chargerLocalisations();
if (widget.isEdition) {
      _chargerDonneesExistantes();
    } else {
      // Initialiser avec une valeur par défaut
      _localisationController.text = _localisations.isNotEmpty ? _localisations.first : '';
    }
  }

  void _chargerLocalisations() {
    _localisations = HiveService.getLocalisationsForEssais(widget.mission.id);
    if (_localisations.isEmpty) {
      _localisations = ['Local technique', 'TGBT', 'Tableau divisionnaire'];
    }
    
    // S'assurer que la valeur courante est dans la liste
    if (_localisationController.text.isNotEmpty && 
        !_localisations.contains(_localisationController.text)) {
      // Si la valeur existante n'est pas dans la liste, l'ajouter temporairement
      _localisations.add(_localisationController.text);
    }
  }

  void _chargerDonneesExistantes() {
    final essai = widget.essai!;
    
    // Charger d'abord les localisations
    _chargerLocalisations();
    
    // Ensuite charger les données
    _localisationController.text = essai.localisation;
    
    // Charger les coffrets pour cette localisation
    _coffrets = HiveService.getCoffretsForLocalisation(widget.mission.id, essai.localisation);
    
    if (essai.coffret != null && essai.coffret!.isNotEmpty) {
      _coffretController.text = essai.coffret!;
      // S'assurer que le coffret est dans la liste
      if (!_coffrets.contains(essai.coffret)) {
        _coffrets.add(essai.coffret!);
      }
    }
    _circuitController.text = essai.designationCircuit!;
    _selectedType = essai.typeDispositif;
    if (essai.reglageIAn != null) {
      _reglageController.text = essai.reglageIAn!.toString();
    }
    if (essai.tempo != null) {
      _tempoController.text = essai.tempo!.toString();
    }
    if (essai.isolement != null) {
      _isolementController.text = essai.isolement!.toString();
    }
    _selectedResultat = essai.essai;
    if (essai.observation != null) {
      _observationController.text = essai.observation!;
    }
  }

  void _onLocalisationChanged(String? value) {
    if (value != null) {
      setState(() {
        _localisationController.text = value;
        _coffrets = HiveService.getCoffretsForLocalisation(widget.mission.id, value);
      });
    }
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      final essai = EssaiDeclenchementDifferentiel(
        localisation: _localisationController.text.trim(),
        coffret: _coffretController.text.trim().isNotEmpty
            ? _coffretController.text.trim()
            : null,
        designationCircuit: _circuitController.text.trim(),
        typeDispositif: _selectedType,
        reglageIAn: _reglageController.text.trim().isNotEmpty
            ? double.tryParse(_reglageController.text.trim())
            : null,
        tempo: _tempoController.text.trim().isNotEmpty
            ? double.tryParse(_tempoController.text.trim())
            : null,
        isolement: _isolementController.text.trim().isNotEmpty
            ? double.tryParse(_isolementController.text.trim())
            : null,
        essai: _selectedResultat,
        observation: _observationController.text.trim().isNotEmpty
            ? _observationController.text.trim()
            : null,
      );

      bool success;
      if (widget.isEdition) {
        success = await HiveService.updateEssaiDeclenchement(
          missionId: widget.mission.id,
          index: widget.index!,
          essai: essai,
        );
      } else {
        success = await HiveService.addEssaiDeclenchement(
          missionId: widget.mission.id,
          essai: essai,
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdition ? 'Essai modifié' : 'Essai ajouté'),
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

  Widget _buildDropdown(String label, List<String> options, String value, Function(String?) onChanged, {bool allowCustom = false}) {
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
              value: value.isNotEmpty && options.contains(value) ? value : (options.isNotEmpty ? options.first : null),
              isExpanded: true,
              underline: SizedBox(),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
              // Gérer le cas où la valeur n'est pas dans la liste
              hint: Text('Sélectionner...'),
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
        title: Text(widget.isEdition ? 'Modifier essai' : 'Ajouter essai'),
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
                    _buildDropdown(
                      'Localisation*',
                      _localisations,
                      _localisationController.text.isNotEmpty ? _localisationController.text : _localisations.first,
                      _onLocalisationChanged,
                    ),
                    
                    _buildDropdown(
                      'Coffret',
                      ['', ..._coffrets],
                      _coffretController.text,
                      (value) {
                        if (value != null) {
                          setState(() => _coffretController.text = value);
                        }
                      },
                    ),
                    
                    _buildTextField('Désignation du circuit', _circuitController, isRequired: false),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Type de dispositif*',
                            HiveService.getTypesDispositifDifferentiel(),
                            _selectedType,
                            (value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            'Résultat essai*',
                            HiveService.getResultatsEssai(),
                            _selectedResultat,
                            (value) {
                              if (value != null) {
                                setState(() => _selectedResultat = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    
                     _buildTextField('Réglage IΔn (mA)', _reglageController, isRequired: false),
                        
                        SizedBox(width: 16),
                        _buildTextField('Temporisation (s)', _tempoController, isRequired: false),
                        
                    
                    _buildTextField('Isolement (MΩ)', _isolementController, isRequired: false),
                    
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
    _coffretController.dispose();
    _circuitController.dispose();
    _reglageController.dispose();
    _tempoController.dispose();
    _isolementController.dispose();
    _observationController.dispose();
    super.dispose();
  }
}