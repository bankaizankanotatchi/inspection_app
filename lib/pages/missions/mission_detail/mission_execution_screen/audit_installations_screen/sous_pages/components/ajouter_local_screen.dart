import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_emplacement_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AjouterLocalScreen extends StatefulWidget {
  final Mission mission;
  final bool isMoyenneTension;
  final dynamic local; // Pour l'édition
  final int? localIndex; // Pour l'édition
  final int? zoneIndex; // Pour basse tension ou moyenne tension dans zone
  final bool isInZone; // Nouveau paramètre
  
  const AjouterLocalScreen({
    super.key,
    required this.mission,
    required this.isMoyenneTension,
    this.local,
    this.localIndex,
    this.zoneIndex,
    this.isInZone = false, // Par défaut false
  });

  bool get isEdition => local != null;

  @override
  State<AjouterLocalScreen> createState() => _AjouterLocalScreenState();
}

class _AjouterLocalScreenState extends State<AjouterLocalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  String? _selectedType;
  List<ElementControle> _dispositionsConstructives = [];
  List<ElementControle> _conditionsExploitation = [];
  
  final ImagePicker _picker = ImagePicker();
  
  // Photos du local
  List<String> _localPhotos = [];
  bool _isLoadingPhotos = false;
  
  // Observations libres
  final _observationController = TextEditingController();
  List<String> _observationPhotos = [];
  final List<ObservationLibre> _observationsExistantes = [];

  // Données pour la cellule (uniquement pour LOCAL_TRANSFORMATEUR)
  final _celluleFonctionController = TextEditingController();
  final _celluleTypeController = TextEditingController();
  final _celluleMarqueController = TextEditingController();
  final _celluleTensionController = TextEditingController();
  final _cellulePouvoirController = TextEditingController();
  final _celluleNumerotationController = TextEditingController();
  final _celluleParafoudresController = TextEditingController();
  List<ElementControle> _celluleElements = [];

  // Données pour le transformateur (uniquement pour LOCAL_TRANSFORMATEUR)
  final _transfoTypeController = TextEditingController();
  final _transfoMarqueController = TextEditingController();
  final _transfoPuissanceController = TextEditingController();
  final _transfoTensionController = TextEditingController();
  final _transfoBuchholzController = TextEditingController();
  final _transfoRefroidissementController = TextEditingController();
  final _transfoRegimeController = TextEditingController();
  List<ElementControle> _transfoElements = [];

  // API RAG NFC 15-100
  static const String _baseUrl = "http://192.168.0.217:8000";
  Map<int, List<String>> _elementSuggestions = {}; // Suggestions par élément
  Map<int, bool> _elementLoading = {}; // État de chargement par élément
  Map<int, Timer?> _elementDebounceTimers = {}; // Timers par élément
  
  // Contrôleurs pour les champs observation
  Map<String, TextEditingController> _observationControllers = {};
  Map<String, TextEditingController> _normeControllers = {};

  // Variables de validation
  bool _nomValid = false;
  bool _typeValid = false;
  bool _localPhotosValid = false;
  bool _observationsValid = true; // Par défaut vrai pour édition
  bool _dispositionsValid = false;
  bool _conditionsValid = false;
  bool _celluleDonneesValid = true; // Par défaut vrai si pas de cellule
  bool _transfoDonneesValid = true; // Par défaut vrai si pas de transformateur
  bool _celluleElementsValid = true; // Par défaut vrai si pas de cellule
  bool _transfoElementsValid = true; // Par défaut vrai si pas de transformateur

  @override
  void initState() {
    super.initState();
    if (widget.isEdition) {
      _chargerDonneesExistantes();
      // Pour l'édition, on suppose que les champs sont déjà valides
      _nomValid = true;
      _typeValid = true;
      _localPhotosValid = _localPhotos.isNotEmpty;
      _dispositionsValid = _validateElements(_dispositionsConstructives);
      _conditionsValid = _validateElements(_conditionsExploitation);
      if (_selectedType == 'LOCAL_TRANSFORMATEUR') {
        _celluleDonneesValid = _validateCelluleDonnees();
        _transfoDonneesValid = _validateTransfoDonnees();
        _celluleElementsValid = _validateElements(_celluleElements);
        _transfoElementsValid = _validateElements(_transfoElements);
      }
    } else {
      _initializeElementsControle();
    }
  }

  void _chargerDonneesExistantes() {
    final local = widget.local!;
    _nomController.text = local.nom;
    _selectedType = local.type;
    _dispositionsConstructives = List.from(local.dispositionsConstructives);
    _conditionsExploitation = List.from(local.conditionsExploitation);

    // Charger les observations existantes
    _observationsExistantes.addAll(local.observationsLibres);

    // Charger les photos du local
    if (local.photos.isNotEmpty) {
      _localPhotos = List.from(local.photos);
    }

    // Charger les données spécifiques au transformateur
    if (local is MoyenneTensionLocal && local.type == 'LOCAL_TRANSFORMATEUR') {
      if (local.cellule != null) {
        _celluleFonctionController.text = local.cellule!.fonction;
        _celluleTypeController.text = local.cellule!.type;
        _celluleMarqueController.text = local.cellule!.marqueModeleAnnee;
        _celluleTensionController.text = local.cellule!.tensionAssignee;
        _cellulePouvoirController.text = local.cellule!.pouvoirCoupure;
        _celluleNumerotationController.text = local.cellule!.numerotation;
        _celluleParafoudresController.text = local.cellule!.parafoudres;
        _celluleElements = List.from(local.cellule!.elementsVerifies);
      }
      if (local.transformateur != null) {
        _transfoTypeController.text = local.transformateur!.typeTransformateur;
        _transfoMarqueController.text = local.transformateur!.marqueAnnee;
        _transfoPuissanceController.text = local.transformateur!.puissanceAssignee;
        _transfoTensionController.text = local.transformateur!.tensionPrimaireSecondaire;
        _transfoBuchholzController.text = local.transformateur!.relaisBuchholz;
        _transfoRefroidissementController.text = local.transformateur!.typeRefroidissement;
        _transfoRegimeController.text = local.transformateur!.regimeNeutre;
        _transfoElements = List.from(local.transformateur!.elementsVerifies);
      }
    }
  }

  void _initializeElementsControle() {
    _dispositionsConstructives = [];
    _conditionsExploitation = [];
    _celluleElements = [];
    _transfoElements = [];
  }

  // ===== VALIDATION DES CHAMPS =====
  
  void _validateNom(String value) {
    setState(() {
      _nomValid = value.trim().isNotEmpty;
    });
  }

  void _validateType(String? value) {
    setState(() {
      _typeValid = value != null && value.isNotEmpty;
    });
  }

  void _validateLocalPhotos() {
    setState(() {
      _localPhotosValid = _localPhotos.isNotEmpty;
    });
  }

  void _validateObservations() {
    bool isValid = true;
    if (!widget.isEdition) {
      // Pour les nouvelles observations
      if (_observationController.text.trim().isEmpty && _observationsExistantes.isEmpty) {
        isValid = false;
      }
    }
    setState(() {
      _observationsValid = isValid;
    });
  }

  bool _validateElements(List<ElementControle> elements) {
    if (elements.isEmpty) return false;
    
    for (var element in elements) {
      if (element.priorite == null || 
          element.observation?.trim().isEmpty == true ||
          element.referenceNormative?.trim().isEmpty == true) {
        return false;
      }
    }
    return true;
  }

  bool _validateCelluleDonnees() {
    return _celluleFonctionController.text.trim().isNotEmpty &&
           _celluleTypeController.text.trim().isNotEmpty &&
           _celluleMarqueController.text.trim().isNotEmpty &&
           _celluleTensionController.text.trim().isNotEmpty &&
           _cellulePouvoirController.text.trim().isNotEmpty &&
           _celluleNumerotationController.text.trim().isNotEmpty &&
           _celluleParafoudresController.text.trim().isNotEmpty;
  }

  bool _validateTransfoDonnees() {
    return _transfoTypeController.text.trim().isNotEmpty &&
           _transfoMarqueController.text.trim().isNotEmpty &&
           _transfoPuissanceController.text.trim().isNotEmpty &&
           _transfoTensionController.text.trim().isNotEmpty &&
           _transfoBuchholzController.text.trim().isNotEmpty &&
           _transfoRefroidissementController.text.trim().isNotEmpty &&
           _transfoRegimeController.text.trim().isNotEmpty;
  }

  void _validateDispositions() {
    setState(() {
      _dispositionsValid = _validateElements(_dispositionsConstructives);
    });
  }

  void _validateConditions() {
    setState(() {
      _conditionsValid = _validateElements(_conditionsExploitation);
    });
  }

  void _validateCelluleElements() {
    setState(() {
      _celluleElementsValid = _validateElements(_celluleElements);
    });
  }

  void _validateTransfoElements() {
    setState(() {
      _transfoElementsValid = _validateElements(_transfoElements);
    });
  }

  bool _validateAllFields() {
    bool allValid = true;
    
    // Valider nom
    if (_nomController.text.trim().isEmpty) {
      _nomValid = false;
      allValid = false;
    }
    
    // Valider type
    if (_selectedType == null || _selectedType!.isEmpty) {
      _typeValid = false;
      allValid = false;
    }
    
    // Valider photos du local
    if (_localPhotos.isEmpty) {
      _localPhotosValid = false;
      allValid = false;
    }
    
    // Valider observations (uniquement pour création)
    if (!widget.isEdition) {
      _validateObservations();
      if (!_observationsValid) {
        allValid = false;
      }
    }
    
    // Valider dispositions constructives
    _validateDispositions();
    if (!_dispositionsValid) {
      allValid = false;
    }
    
    // Valider conditions d'exploitation
    _validateConditions();
    if (!_conditionsValid) {
      allValid = false;
    }
    
    // Valider les sections spécifiques au transformateur
    if (_selectedType == 'LOCAL_TRANSFORMATEUR') {
      if (!_validateCelluleDonnees()) {
        _celluleDonneesValid = false;
        allValid = false;
      }
      
      if (!_validateTransfoDonnees()) {
        _transfoDonneesValid = false;
        allValid = false;
      }
      
      _validateCelluleElements();
      if (!_celluleElementsValid) {
        allValid = false;
      }
      
      _validateTransfoElements();
      if (!_transfoElementsValid) {
        allValid = false;
      }
    }
    
    setState(() {});
    return allValid;
  }

  // ===== API RAG NFC 15-100 =====

  @override
  void dispose() {
    // Annuler tous les timers
    _elementDebounceTimers.forEach((key, timer) {
      timer?.cancel();
    });
    
    // Disposer tous les contrôleurs d'observation
    _observationControllers.forEach((key, controller) {
      controller.dispose();
    });
    
    // Disposer tous les contrôleurs de norme
    _normeControllers.forEach((key, controller) {
      controller.dispose();
    });
    
    _nomController.dispose();
    _observationController.dispose();
    _celluleFonctionController.dispose();
    _celluleTypeController.dispose();
    _celluleMarqueController.dispose();
    _celluleTensionController.dispose();
    _cellulePouvoirController.dispose();
    _celluleNumerotationController.dispose();
    _celluleParafoudresController.dispose();
    _transfoTypeController.dispose();
    _transfoMarqueController.dispose();
    _transfoPuissanceController.dispose();
    _transfoTensionController.dispose();
    _transfoBuchholzController.dispose();
    _transfoRefroidissementController.dispose();
    _transfoRegimeController.dispose();
    super.dispose();
  }

  // Autocompletion en temps réel pour un élément spécifique
  void _onElementObservationChanged(int elementIndex, String text, String sectionType) {
    _elementDebounceTimers[elementIndex]?.cancel();
    
    if (text.length >= 3) {
      _elementDebounceTimers[elementIndex] = Timer(Duration(milliseconds: 500), () async {
        await _getElementSuggestions(elementIndex, text, sectionType);
      });
    } else {
      setState(() {
        _elementSuggestions[elementIndex]?.clear();
      });
    }
  }

  // Récupérer suggestions pour un élément
  Future<void> _getElementSuggestions(int elementIndex, String query, String sectionType) async {
    if (query.length < 3) return;

    final body = <String, dynamic>{
      'query': query,
      'max_results': 5,
    };

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/autocomplete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          _elementSuggestions[elementIndex] = List<String>.from(data['suggestions'] ?? []);
        });
      }
    } catch (e) {
      print('Erreur suggestions pour élément $elementIndex: $e');
    }
  }

  // Extraire norme pour un élément spécifique et la mettre dans le champ référence normative
  Future<void> _extractNormeForElement(int elementIndex, String observation, ElementControle element, String sectionType) async {
    if (observation.isEmpty) {
      _showSnackBar('Entrez une observation', Colors.orange);
      return;
    }

    setState(() {
      _elementLoading[elementIndex] = true;
      _elementSuggestions[elementIndex]?.clear();
    });

    final body = <String, dynamic>{
      'observation': observation,
    };

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/extract_norme'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final norme = data['norme'] ?? 'N/A';
        final confidence = (data['confidence'] ?? 0.0) * 100;
        
        // Mettre la norme dans le champ référence normative
        setState(() {
          element.referenceNormative = norme;
          _elementLoading[elementIndex] = false;
          
          // Mettre à jour le contrôleur de norme
          final normeKey = '$sectionType-$elementIndex';
          if (_normeControllers.containsKey(normeKey)) {
            _normeControllers[normeKey]!.text = norme;
          }
        });
        
        _showSnackBar('Norme extraite avec ${confidence.toStringAsFixed(0)}% de confiance', Colors.green);
      } else {
        setState(() {
          _elementLoading[elementIndex] = false;
        });
        _showSnackBar('Erreur HTTP: ${res.statusCode}', Colors.red);
      }
    } catch (e) {
      setState(() {
        _elementLoading[elementIndex] = false;
      });
      _showSnackBar('Erreur de connexion à l\'API', Colors.red);
    }
  }

  void _useElementSuggestion(int elementIndex, String suggestion, ElementControle element, String sectionType) {
    // Clé unique pour cet élément
    final observationKey = '$sectionType-$elementIndex';
    
    // Mettre à jour l'élément
    element.observation = suggestion;
    
    // Mettre à jour le contrôleur s'il existe
    if (_observationControllers.containsKey(observationKey)) {
      _observationControllers[observationKey]!.text = suggestion;
    }
    
    setState(() {
      _elementSuggestions[elementIndex]?.clear();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ===== FIN API RAG =====

  // ===== MÉTHODES POUR GESTION DES PHOTOS DU LOCAL =====

  Future<void> _prendrePhotoLocal() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'locaux');
        setState(() {
          _localPhotos.add(savedPath);
          _validateLocalPhotos();
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _choisirPhotoLocalDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'locaux');
        setState(() {
          _localPhotos.add(savedPath);
          _validateLocalPhotos();
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  // ===== MÉTHODES POUR GESTION DES PHOTOS D'OBSERVATION =====

  Future<void> _prendrePhotoObservation() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() {
          _observationPhotos.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoObservationDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() {
          _observationPhotos.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  Future<String> _savePhotoToAppDirectory(File photoFile, String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/audit_photos/$subDir');
    
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    
    final fileName = '${subDir}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${photosDir.path}/$fileName';
    
    await photoFile.copy(newPath);
    return newPath;
  }

  void _previsualiserPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photos[index]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _supprimerPhoto(photos, index);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _supprimerPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la photo'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                photos.removeAt(index);
                _validateLocalPhotos();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(String title, List<String> photos, Function prendrePhoto, Function choisirPhoto, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        
        if (_isLoadingPhotos && title.contains('Local'))
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (photos.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isRequired ? Colors.red.shade300 : Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 48,
                    color: isRequired ? Colors.red.shade400 : Colors.grey.shade400,
                  ),
                  SizedBox(height: 8),
                  Text(
                    isRequired ? 'Aucune photo (obligatoire)*' : 'Aucune photo',
                    style: TextStyle(
                      color: isRequired ? Colors.red : Colors.grey.shade600,
                      fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _previsualiserPhoto(photos, index),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photos[index]),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _supprimerPhoto(photos, index),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        
        SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => prendrePhoto(),
                icon: Icon(Icons.camera_alt, size: 20),
                label: Text('Prendre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 4,),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => choisirPhoto(),
                icon: Icon(Icons.photo_library, size: 20),
                label: Text('Galerie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===== GESTION DES OBSERVATIONS =====

  Widget _buildObservationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OBSERVATIONS SUR LE LOCAL*',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        SizedBox(height: 16),

        // Observations existantes
        if (_observationsExistantes.isNotEmpty)
          ..._observationsExistantes.asMap().entries.map((entry) {
            final index = entry.key;
            final observation = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            observation.texte,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _supprimerObservationExistante(index),
                        ),
                      ],
                    ),
                    if (observation.photos.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          Text(
                            'Photos associées (${observation.photos.length})',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: observation.photos.length,
                            itemBuilder: (context, photoIndex) {
                              return GestureDetector(
                                onTap: () => _previsualiserPhoto(observation.photos, photoIndex),
                                child: Image.file(
                                  File(observation.photos[photoIndex]),
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),

        // Nouvelle observation
        Card(
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle observation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),

                TextFormField(
                  controller: _observationController,
                  decoration: InputDecoration(
                    labelText: 'Observation*',
                    border: OutlineInputBorder(),
                    hintText: 'Saisissez votre observation...',
                    errorText: !_observationsValid && _observationController.text.isEmpty ? 
                      'Une observation est obligatoire' : null,
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (value) => _validateObservations(),
                ),

                SizedBox(height: 16),

                // Photos pour la nouvelle observation
                _buildPhotosSection(
                  'Photos pour cette observation',
                  _observationPhotos,
                  _prendrePhotoObservation,
                  _choisirPhotoObservationDepuisGalerie,
                ),

                SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _ajouterObservation,
                  child: Text('Ajouter cette observation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _ajouterObservation() {
    final texte = _observationController.text.trim();
    if (texte.isEmpty) {
      _showError('Veuillez saisir une observation');
      return;
    }

    setState(() {
      _observationsExistantes.add(ObservationLibre(
        texte: texte,
        photos: List.from(_observationPhotos),
      ));
      _observationController.clear();
      _observationPhotos.clear();
      _validateObservations();
    });
  }

  void _supprimerObservationExistante(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'observation'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette observation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _observationsExistantes.removeAt(index);
                _validateObservations();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ===== FIN GESTION OBSERVATIONS =====

  void _onTypeChanged(String? newType) {
    setState(() {
      _selectedType = newType;
      _validateType(newType);
      if (!widget.isEdition) {
        _initializeElementsForType(newType);
      }
    });
  }

  void _initializeElementsForType(String? type) {
    if (type == null) return;

    // Dispositions constructives
    final dispositions = HiveService.getDispositionsConstructivesForLocal(type);
    _dispositionsConstructives = dispositions.map((element) => ElementControle(
      elementControle: element,
      conforme: false,
    )).toList();

    // Conditions d'exploitation
    final conditions = HiveService.getConditionsExploitationForLocal(type);
    _conditionsExploitation = conditions.map((element) => ElementControle(
      elementControle: element,
      conforme: false,
    )).toList();

    // Éléments spécifiques pour le local transformateur
    if (type == 'LOCAL_TRANSFORMATEUR') {
      final celluleElements = [
        'Schéma unifilaire affiché dans le local',
        'Cellule correctement posée et fixée',
        'Jonctions inter-cellules',
        'Canalisations et câbles d\'arrivée / départ',
        'Respect des distances de sécurité',
        'Commande manuelle / motorisée',
        'Voyants de position (O / F / T)',
        'Verrouillage mécanique',
        'Terre de protection (PE) reliée à chaque cellule',
      ];
      _celluleElements = celluleElements.map((element) => ElementControle(
        elementControle: element,
        conforme: false,
      )).toList();

      final transfoElements = [
        'Adapté au local et à la ventilation',
        'Plaque signalétique (puissance, tension, couplage)',
        'Mise à la terre du neutre et de la carcasse',
        'Raccordement des câbles MT et BT',
        'Protection contre les contacts directs',
        'Bac de rétention (pour transfo à huile)',
        'Protection contre les surintensités',
        'Essais diélectriques',
        'Distance entre transformateur',
        'Protection MT',
        'Protection BT (disjoncteur général, fusibles, relais thermique)',
        'Écran de câble MT relié à la terre',
      ];
      _transfoElements = transfoElements.map((element) => ElementControle(
        elementControle: element,
        conforme: false,
      )).toList();
    }
  }

  void _sauvegarder() async {
    // Valider tous les champs
    if (!_validateAllFields()) {
      _showError('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      dynamic nouveauLocal;

      // ===== TRANSFERT DU CLASSEMENT SI LE NOM A CHANGÉ =====
      if (widget.isEdition && widget.local != null) {
        final ancienNom = widget.local!.nom;
        final nouveauNom = _nomController.text.trim();
        
        if (ancienNom != nouveauNom) {
          // 1. Chercher le classement existant avec l'ancien nom
          final ancienClassement = HiveService.getClassementForLocal(
            missionId: widget.mission.id,
            localisation: ancienNom,
          );
          
          if (ancienClassement != null) {
            print('🔄 Transfert classement: $ancienNom → $nouveauNom');
            
            // 2. Mettre à jour la localisation du classement existant
            ancienClassement.localisation = nouveauNom;
            
            // 3. Mettre à jour zone et type si nécessaire
            if (widget.isInZone && widget.zoneIndex != null) {
              ancienClassement.zone = 'Zone ${widget.zoneIndex! + 1}';
            }
            ancienClassement.typeLocal = _selectedType;
            
            // 4. Sauvegarder les modifications
            ancienClassement.updatedAt = DateTime.now();
            await ancienClassement.save();
            
            print('✅ Classement transféré vers nouveau nom');
          }
        }
      }
      // ===== FIN TRANSFERT =====
      
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          // CAS 1: LOCAL DANS UNE ZONE MT (ajout ou édition)
          if (widget.isEdition && widget.localIndex != null) {
            // Éditer un local existant DANS une zone MT
            await HiveService.updateLocalInMoyenneTensionZone(
              missionId: widget.mission.id,
              zoneIndex: widget.zoneIndex!,
              localIndex: widget.localIndex!,
              local: _creerMoyenneTensionLocal(),
            );
            nouveauLocal = _creerMoyenneTensionLocal();
          } else {
            // Ajouter un nouveau local DANS une zone MT
            await HiveService.addLocalToMoyenneTensionZone(
              missionId: widget.mission.id,
              zoneIndex: widget.zoneIndex!,
              local: _creerMoyenneTensionLocal(),
            );
            nouveauLocal = _creerMoyenneTensionLocal();
          }
        } else {
          // CAS 2: LOCAL MT INDÉPENDANT (hors zone)
          if (widget.isEdition && widget.localIndex != null) {
            await HiveService.updateMoyenneTensionLocal(
              missionId: widget.mission.id,
              localIndex: widget.localIndex!,
              local: _creerMoyenneTensionLocal(),
            );
            nouveauLocal = _creerMoyenneTensionLocal();
          } else {
            await HiveService.addMoyenneTensionLocal(
              missionId: widget.mission.id,
              local: _creerMoyenneTensionLocal(),
            );
            nouveauLocal = _creerMoyenneTensionLocal();
          }
        }
      } else {
        // CAS 3: BASSE TENSION (toujours dans une zone)
        if (widget.zoneIndex != null) {
          if (widget.isEdition && widget.localIndex != null) {
            await HiveService.updateBasseTensionLocal(
              missionId: widget.mission.id,
              zoneIndex: widget.zoneIndex!,
              localIndex: widget.localIndex!,
              local: _creerBasseTensionLocal(),
            );
            nouveauLocal = _creerBasseTensionLocal();
          } else {
            await HiveService.addLocalToBasseTensionZone(
              missionId: widget.mission.id,
              zoneIndex: widget.zoneIndex!,
              local: _creerBasseTensionLocal(),
            );
            nouveauLocal = _creerBasseTensionLocal();
          }
        } else {
          // Ce cas ne devrait pas arriver pour BT
          _showError('Erreur: pour basse tension, un local doit être dans une zone');
          return;
        }
      }
      
      // Si c'est une édition, retour direct à DetailLocalScreen
      // Si c'est un ajout, aller au classement
      if (widget.isEdition) {
        Navigator.pop(context, true); // Retour direct à DetailLocalScreen
      } else {
        // Pour un nouvel ajout, aller au classement
        await _allerAuClassement(nouveauLocal);
      }
      
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      _showError('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<void> _allerAuClassement(dynamic local) async {
    if (local == null) {
      _showError('Erreur: impossible de créer le classement pour ce local');
      Navigator.pop(context, true);
      return;
    }
    
    try {
      ClassementEmplacement? classement;
      
      // IMPORTANT : pour l'édition, chercher d'abord l'existant
      if (widget.isEdition) {
        classement = HiveService.getClassementExisting(
          missionId: widget.mission.id,
          localisation: local.nom,
        );
      }
      
      // Si pas trouvé ou nouveau local, créer ou récupérer
      classement ??= await HiveService.getOrCreateClassementForLocal(
          missionId: widget.mission.id,
          localisation: local.nom,
          zone: widget.isInZone && widget.zoneIndex != null 
              ? 'Zone ${widget.zoneIndex! + 1}' 
              : null,
          typeLocal: local.type,
        );
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassementEmplacementScreen(
            mission: widget.mission,
            emplacement: classement!,
          ),
        ),
      );
      
      if (result == true) {
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      print('❌ Erreur allerAuClassement: $e');
      _showError('Erreur lors de l\'accès au classement: $e');
      Navigator.pop(context, true);
    }
  }

  MoyenneTensionLocal _creerMoyenneTensionLocal() {
    return MoyenneTensionLocal(
      nom: _nomController.text.trim(),
      type: _selectedType!,
      dispositionsConstructives: _dispositionsConstructives,
      conditionsExploitation: _conditionsExploitation,
      cellule: _selectedType == 'LOCAL_TRANSFORMATEUR' ? Cellule(
        fonction: _celluleFonctionController.text.trim(),
        type: _celluleTypeController.text.trim(),
        marqueModeleAnnee: _celluleMarqueController.text.trim(),
        tensionAssignee: _celluleTensionController.text.trim(),
        pouvoirCoupure: _cellulePouvoirController.text.trim(),
        numerotation: _celluleNumerotationController.text.trim(),
        parafoudres: _celluleParafoudresController.text.trim(),
        elementsVerifies: _celluleElements,
      ) : null,
      transformateur: _selectedType == 'LOCAL_TRANSFORMATEUR' ? TransformateurMTBT(
        typeTransformateur: _transfoTypeController.text.trim(),
        marqueAnnee: _transfoMarqueController.text.trim(),
        puissanceAssignee: _transfoPuissanceController.text.trim(),
        tensionPrimaireSecondaire: _transfoTensionController.text.trim(),
        relaisBuchholz: _transfoBuchholzController.text.trim(),
        typeRefroidissement: _transfoRefroidissementController.text.trim(),
        regimeNeutre: _transfoRegimeController.text.trim(),
        elementsVerifies: _transfoElements,
      ) : null,
      observationsLibres: _observationsExistantes, // Liste d'ObservationLibre
      photos: _localPhotos,
    );
  }

  BasseTensionLocal _creerBasseTensionLocal() {
    return BasseTensionLocal(
      nom: _nomController.text.trim(),
      type: _selectedType!,
      dispositionsConstructives: _dispositionsConstructives,
      conditionsExploitation: _conditionsExploitation,
      observationsLibres: _observationsExistantes, // Liste d'ObservationLibre
      photos: _localPhotos,
    );
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

  Widget _buildElementWithPriorityAndObservation(ElementControle element, int index, String sectionType) {
    final elementIndex = index;
    final suggestions = _elementSuggestions[elementIndex] ?? [];
    final isLoading = _elementLoading[elementIndex] ?? false;
    
    // Clés uniques pour les contrôleurs
    final observationKey = '$sectionType-$elementIndex';
    final normeKey = '$sectionType-$elementIndex-norme';

    // Créer ou récupérer le contrôleur d'observation
    if (!_observationControllers.containsKey(observationKey)) {
      _observationControllers[observationKey] = TextEditingController(text: element.observation ?? '');
    } else {
      // Synchroniser la valeur si nécessaire
      if (_observationControllers[observationKey]!.text != (element.observation ?? '')) {
        _observationControllers[observationKey]!.text = element.observation ?? '';
      }
    }
    
    // Créer ou récupérer le contrôleur de norme
    if (!_normeControllers.containsKey(normeKey)) {
      _normeControllers[normeKey] = TextEditingController(text: element.referenceNormative ?? '');
    } else {
      // Synchroniser la valeur si nécessaire
      if (_normeControllers[normeKey]!.text != (element.referenceNormative ?? '')) {
        _normeControllers[normeKey]!.text = element.referenceNormative ?? '';
      }
    }

    bool prioriteValid = element.priorite != null;
    bool observationValid = (element.observation ?? '').trim().isNotEmpty;
    bool normeValid = (element.referenceNormative ?? '').trim().isNotEmpty;
    bool photosValid = element.photos.isNotEmpty;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            Text(
              element.elementControle,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w500,
                color: AppTheme.darkBlue,
              ),
            ),
            SizedBox(height: 12),
            
            // Ligne 1: Conformité
            Container(
              width: double.infinity,
              child: DropdownButtonFormField<bool>(
                value: element.conforme,
                onChanged: (bool? newValue) {
                  setState(() {
                    element.conforme = newValue ?? false;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Conformité*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(
                    value: true, 
                    child: Text('Oui', style: TextStyle(color: Colors.green))
                  ),
                  DropdownMenuItem(
                    value: false, 
                    child: Text('Non', style: TextStyle(color: Colors.red))
                  ),
                ],
                isExpanded: true,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Ligne 2: Priorité
            Container(
              width: double.infinity,
              child: DropdownButtonFormField<int?>(
                value: element.priorite,
                onChanged: (int? newValue) {
                  setState(() {
                    element.priorite = newValue;
                    if (sectionType == 'dispositions') _validateDispositions();
                    if (sectionType == 'conditions') _validateConditions();
                    if (sectionType == 'cellule') _validateCelluleElements();
                    if (sectionType == 'transformateur') _validateTransfoElements();
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Priorité*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  errorText: !prioriteValid ? 'Sélectionnez une priorité' : null,
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text('Sélectionnez...')),
                  DropdownMenuItem(
                    value: 1, 
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.blue, size: 12),
                        SizedBox(width: 8),
                        Text('N1 - Basse', style: TextStyle(color: Colors.blue)),
                      ],
                    )
                  ),
                  DropdownMenuItem(
                    value: 2, 
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.orange, size: 12),
                        SizedBox(width: 8),
                        Text('N2 - Moyenne', style: TextStyle(color: Colors.orange)),
                      ],
                    )
                  ),
                  DropdownMenuItem(
                    value: 3, 
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.red, size: 12),
                        SizedBox(width: 8),
                        Text('N3 - Haute', style: TextStyle(color: Colors.red)),
                      ],
                    )
                  ),
                ],
                isExpanded: true,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Ligne 3: Observation avec API RAG
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _observationControllers[observationKey],
                  onChanged: (value) {
                    element.observation = value;
                    _onElementObservationChanged(elementIndex, value, sectionType);
                    if (sectionType == 'dispositions') _validateDispositions();
                    if (sectionType == 'conditions') _validateConditions();
                    if (sectionType == 'cellule') _validateCelluleElements();
                    if (sectionType == 'transformateur') _validateTransfoElements();
                  },
                  decoration: InputDecoration(
                    labelText: 'Observation*',
                    border: OutlineInputBorder(),
                    hintText: 'Saisissez vos observations...',
                    errorText: !observationValid ? 'Ce champ est obligatoire' : null,
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    suffixIcon: isLoading
                        ? Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  maxLines: 2,
                ),
                
                // Suggestions automatiques
                if (suggestions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggestions:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                        SizedBox(height: 4),
                        ...suggestions.map((s) => InkWell(
                          onTap: () => _useElementSuggestion(elementIndex, s, element, sectionType),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_right, size: 14, color: AppTheme.primaryBlue),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    s,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                
                // Bouton pour extraire la norme
                if (element.observation?.isNotEmpty == true && !isLoading)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _extractNormeForElement(elementIndex, element.observation!, element, sectionType),
                      icon: Icon(Icons.description, size: 16),
                      label: Text('Trouver la norme NFC 15-100'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        minimumSize: Size(double.infinity, 36),
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 12),

            // Ligne 4: Référence normative (rempli automatiquement par l'API)
            TextFormField(
              controller: _normeControllers[normeKey],
              onChanged: (value) {
                element.referenceNormative = value;
                if (sectionType == 'dispositions') _validateDispositions();
                if (sectionType == 'conditions') _validateConditions();
                if (sectionType == 'cellule') _validateCelluleElements();
                if (sectionType == 'transformateur') _validateTransfoElements();
              },
              decoration: InputDecoration(
                labelText: 'Référence normative*',
                border: OutlineInputBorder(),
                hintText: 'Ex: NF C 15-100, IEC 60364...',
                errorText: !normeValid ? 'Ce champ est obligatoire' : null,
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                prefixIcon: Icon(Icons.description, color: AppTheme.primaryBlue),
              ),
              maxLines: 1,
            ),
            
            SizedBox(height: 16),
            
            // Ligne 5: Photos pour cette question
            _buildPhotosForElement(element, index, sectionType),
          ],
        ),
      ),
    );
  }

  // Nouvelle méthode pour gérer les photos par élément
  Widget _buildPhotosForElement(ElementControle element, int elementIndex, String sectionType) {
    
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos pour cette question',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${element.photos.length} photo(s)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        
        // Affichage des photos existantes
        if (element.photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 0.8,
            ),
            itemCount: element.photos.length,
            itemBuilder: (context, photoIndex) {
              return GestureDetector(
                onTap: () => _previsualiserPhoto(element.photos, photoIndex),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(element.photos[photoIndex]),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _supprimerPhotoElement(element, photoIndex, elementIndex, sectionType),
                        child: Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        else
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                'Aucune photo (obligatoire)*',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        SizedBox(height: 12),
        
        // Boutons pour ajouter des photos
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _prendrePhotoPourElement(element, elementIndex, sectionType),
                icon: Icon(Icons.camera_alt, size: 16),
                label: Text('Prendre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _choisirPhotoPourElement(element, elementIndex, sectionType),
                icon: Icon(Icons.photo_library, size: 16),
                label: Text('Galerie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Méthodes pour gérer les photos par élément
  Future<void> _prendrePhotoPourElement(ElementControle element, int elementIndex, String sectionType) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'element_photos');
        setState(() {
          element.photos.add(savedPath);
          if (sectionType == 'dispositions') _validateDispositions();
          if (sectionType == 'conditions') _validateConditions();
          if (sectionType == 'cellule') _validateCelluleElements();
          if (sectionType == 'transformateur') _validateTransfoElements();
        });
        
        // Sauvegarder dans HiveService
        await HiveService.addPhotoToElementControle(
          missionId: widget.mission.id,
          localisation: _nomController.text.trim(),
          elementIndex: elementIndex,
          cheminPhoto: savedPath,
          sectionType: sectionType,
        );
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoPourElement(ElementControle element, int elementIndex, String sectionType) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'element_photos');
        setState(() {
          element.photos.add(savedPath);
          if (sectionType == 'dispositions') _validateDispositions();
          if (sectionType == 'conditions') _validateConditions();
          if (sectionType == 'cellule') _validateCelluleElements();
          if (sectionType == 'transformateur') _validateTransfoElements();
        });
        
        // Sauvegarder dans HiveService
        await HiveService.addPhotoToElementControle(
          missionId: widget.mission.id,
          localisation: _nomController.text.trim(),
          elementIndex: elementIndex,
          cheminPhoto: savedPath,
          sectionType: sectionType,
        );
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  void _supprimerPhotoElement(ElementControle element, int photoIndex, int elementIndex, String sectionType) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la photo'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                element.photos.removeAt(photoIndex);
                if (sectionType == 'dispositions') _validateDispositions();
                if (sectionType == 'conditions') _validateConditions();
                if (sectionType == 'cellule') _validateCelluleElements();
                if (sectionType == 'transformateur') _validateTransfoElements();
              });
              
              // Mettre à jour dans HiveService
              await HiveService.removePhotoFromElementControle(
                missionId: widget.mission.id,
                localisation: _nomController.text.trim(),
                elementIndex: elementIndex,
                photoIndex: photoIndex,
                sectionType: sectionType,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // Modifier la méthode _buildElementControleList pour passer l'index et le type
  Widget _buildElementControleList(String title, List<ElementControle> elements, String sectionType) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(height: 12),
            ...elements.asMap().entries.map((entry) {
              final index = entry.key;
              final element = entry.value;
              return _buildElementWithPriorityAndObservation(element, index, sectionType);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isMultiline = false, bool isRequired = false, String? sectionType}) {
    bool isValid = controller.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        onChanged: (value) {
          if (sectionType == 'cellule') {
            _celluleDonneesValid = _validateCelluleDonnees();
          } else if (sectionType == 'transfo') {
            _transfoDonneesValid = _validateTransfoDonnees();
          }
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          errorText: isRequired && !isValid ? 'Ce champ est obligatoire' : null,
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        maxLines: isMultiline ? 3 : 1,
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final localTypes = HiveService.getLocalTypes();
    final filteredTypes = widget.isMoyenneTension
        ? localTypes.entries.toList()
        : localTypes.entries.toList();

    return DropdownButtonFormField<String>(
      value: _selectedType,
      onChanged: _onTypeChanged,
      decoration: InputDecoration(
        labelText: 'Type de local*',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        errorText: !_typeValid ? 'Sélectionnez un type' : null,
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
      items: filteredTypes.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(
            entry.value,
            style: TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      isExpanded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdition ? 'Modifier le Local' : 'Ajouter un Local'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _sauvegarder,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: ListView(
            children: [
              // Indication si dans une zone
              if (widget.isInZone && widget.zoneIndex != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ce local sera ajouté dans la zone',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),

              // Nom du local
              _buildTextField(_nomController, 'Nom du local*', isRequired: true),
              SizedBox(height: 16),

              // Type de local
              _buildTypeDropdown(),
              SizedBox(height: 24),

              // Section Photos du local
              Card(
                elevation: 1,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: _buildPhotosSection(
                    'Photos du local* (obligatoire)',
                    _localPhotos,
                    _prendrePhotoLocal,
                    _choisirPhotoLocalDepuisGalerie,
                    isRequired: true,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Observations libres (uniquement pour création)
              if(!widget.isEdition)
                _buildObservationsSection(),
              if(!widget.isEdition)
                SizedBox(height: 24),

              // Afficher les sections selon le type sélectionné
              if (_selectedType != null) ...[
                // Dispositions constructives
                _buildElementControleList('DISPOSITIONS CONSTRUCTIVES* (tous les champs obligatoires)', _dispositionsConstructives, 'dispositions'),
                
                // Conditions d'exploitation
                _buildElementControleList('CONDITIONS D\'EXPLOITATION* (tous les champs obligatoires)', _conditionsExploitation, 'conditions'),

                // Sections spécifiques pour le local transformateur
                if (_selectedType == 'LOCAL_TRANSFORMATEUR') ...[
                  SizedBox(height: 16),
                  Text(
                    'CELLULE* (tous les champs obligatoires)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTextField(_celluleFonctionController, 'Fonction de la cellule*', isRequired: true, sectionType: 'cellule'),
                  _buildTextField(_celluleTypeController, 'Type de cellule*', isRequired: true, sectionType: 'cellule'),
                  _buildTextField(_celluleMarqueController, 'Marque / modèle / année*', isRequired: true, sectionType: 'cellule'),
                  _buildTextField(_celluleTensionController, 'Tension assignée*', isRequired: true, sectionType: 'cellule'),
                  _buildTextField(_cellulePouvoirController, 'Pouvoir de coupure assigné (kA)*', isRequired: true, sectionType: 'cellule'),
                  _buildTextField(_celluleNumerotationController, 'Numérotation / repérage cellule*', isRequired: true, sectionType: 'cellule'),
                  _buildTextField(_celluleParafoudresController, 'Parafoudres installés sur l\'arrivée*', isRequired: true, sectionType: 'cellule'),
                  _buildElementControleList('ÉLÉMENTS VÉRIFIÉS - CELLULE* (tous les champs obligatoires)', _celluleElements, 'cellule'),

                  SizedBox(height: 16),
                  Text(
                    'TRANSFORMATEUR MT/BT* (tous les champs obligatoires)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTextField(_transfoTypeController, 'Type de transformateur*', isRequired: true, sectionType: 'transfo'),
                  _buildTextField(_transfoMarqueController, 'Marque/ Année de fabrication*', isRequired: true, sectionType: 'transfo'),
                  _buildTextField(_transfoPuissanceController, 'Puissance assignée (kVA)*', isRequired: true, sectionType: 'transfo'),
                  _buildTextField(_transfoTensionController, 'Tension primaire / secondaire*', isRequired: true, sectionType: 'transfo'),
                  _buildTextField(_transfoBuchholzController, 'Présence du relais Buchholz*', isRequired: true, sectionType: 'transfo'),
                  _buildTextField(_transfoRefroidissementController, 'Type de refroidissement*', isRequired: true, sectionType: 'transfo'),
                  _buildTextField(_transfoRegimeController, 'Régime du neutre*', isRequired: true, sectionType: 'transfo'),
                  _buildElementControleList('ÉLÉMENTS VÉRIFIÉS - TRANSFORMATEUR* (tous les champs obligatoires)', _transfoElements, 'transformateur'),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}