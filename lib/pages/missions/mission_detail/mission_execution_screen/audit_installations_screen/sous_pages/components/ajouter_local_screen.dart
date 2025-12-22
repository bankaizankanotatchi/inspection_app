import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    if (widget.isEdition) {
      _chargerDonneesExistantes();
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
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(String title, List<String> photos, Function prendrePhoto, Function choisirPhoto) {
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
            Text(
              '${photos.length} photo(s)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aucune photo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
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
          'OBSERVATIONS SUR LE LOCAL',
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
                    labelText: 'Observation',
                    border: OutlineInputBorder(),
                    hintText: 'Saisissez votre observation...',
                  ),
                  maxLines: 3,
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
    if (_formKey.currentState!.validate() && _selectedType != null) {
      _formKey.currentState!.save();
      
      try {
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
            } else {
              // Ajouter un nouveau local DANS une zone MT
              await HiveService.addLocalToMoyenneTensionZone(
                missionId: widget.mission.id,
                zoneIndex: widget.zoneIndex!,
                local: _creerMoyenneTensionLocal(),
              );
            }
          } else {
            // CAS 2: LOCAL MT INDÉPENDANT (hors zone)
            if (widget.isEdition && widget.localIndex != null) {
              await HiveService.updateMoyenneTensionLocal(
                missionId: widget.mission.id,
                localIndex: widget.localIndex!,
                local: _creerMoyenneTensionLocal(),
              );
            } else {
              await HiveService.addMoyenneTensionLocal(
                missionId: widget.mission.id,
                local: _creerMoyenneTensionLocal(),
              );
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
            } else {
              await HiveService.addLocalToBasseTensionZone(
                missionId: widget.mission.id,
                zoneIndex: widget.zoneIndex!,
                local: _creerBasseTensionLocal(),
              );
            }
          } else {
            // Ce cas ne devrait pas arriver pour BT
            _showError('Erreur: pour basse tension, un local doit être dans une zone');
            return;
          }
        }
        
        Navigator.pop(context, true);
      } catch (e) {
        print('❌ Erreur sauvegarde: $e');
        _showError('Erreur lors de la sauvegarde: $e');
      }
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
      ),
    );
  }

Widget _buildElementWithPriorityAndObservation(ElementControle element, int index, String sectionType) {
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                labelText: 'Conformité',
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
                });
              },
              decoration: InputDecoration(
                labelText: 'Priorité',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          
          // Ligne 3: Observation
          TextFormField(
            initialValue: element.observation,
            onChanged: (value) => element.observation = value,
            decoration: InputDecoration(
              labelText: 'Observation',
              border: OutlineInputBorder(),
              hintText: 'Saisissez vos observations...',
            ),
            maxLines: 2,
          ),
          
          SizedBox(height: 16),
          
          // Ligne 4: Photos pour cette question
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
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Text(
              'Aucune photo',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
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

  Widget _buildConformiteSelector(ElementControle element) {
    return DropdownButtonFormField<bool>(
      value: element.conforme,
      onChanged: (bool? newValue) {
        setState(() {
          element.conforme = newValue ?? false;
        });
      },
      decoration: InputDecoration(
        labelText: 'Conformité',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
      ),
      items: [
        DropdownMenuItem(value: true, child: Text('Oui', style: TextStyle(color: Colors.green))),
        DropdownMenuItem(value: false, child: Text('Non', style: TextStyle(color: Colors.red))),
      ],
      isExpanded: true,
    );
  }

  Widget _buildPrioriteSelector(ElementControle element) {
    return DropdownButton<int?>(
      value: element.priorite,
      hint: Text('Prio'),
      onChanged: (int? newValue) {
        setState(() {
          element.priorite = newValue;
        });
      },
      items: [
        DropdownMenuItem(value: null, child: Text('-')),
        DropdownMenuItem(value: 1, child: Text('N1', style: TextStyle(color: Colors.blue))),
        DropdownMenuItem(value: 2, child: Text('N2', style: TextStyle(color: Colors.orange))),
        DropdownMenuItem(value: 3, child: Text('N3', style: TextStyle(color: Colors.red))),
      ],
    );
  }


  Widget _buildTextField(TextEditingController controller, String label, {bool isMultiline = false, bool isRequired = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        maxLines: isMultiline ? 3 : 1,
        validator: isRequired ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ce champ est obligatoire';
          }
          return null;
        } : null,
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
      validator: (value) {
        if (value == null) return 'Veuillez sélectionner un type';
        return null;
      },
      isExpanded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdition ? 'Modifier le Local' : 'Ajouter un Local'),
        backgroundColor: widget.isMoyenneTension ? Colors.blue : Colors.blue,
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
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ce local sera ajouté dans la zone',
                        style: TextStyle(
                          color: Colors.blue,
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
                    'Photos du local',
                    _localPhotos,
                    _prendrePhotoLocal,
                    _choisirPhotoLocalDepuisGalerie,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Observations libres
               if(!widget.isEdition)
              _buildObservationsSection(),
               if(!widget.isEdition)
              SizedBox(height: 24),

              // Afficher les sections selon le type sélectionné
              if (_selectedType != null) ...[
                // Dispositions constructives
                _buildElementControleList('DISPOSITIONS CONSTRUCTIVES', _dispositionsConstructives, 'dispositions'),
                
                // Conditions d'exploitation
                _buildElementControleList('CONDITIONS D\'EXPLOITATION', _conditionsExploitation, 'conditions'),


                // Sections spécifiques pour le local transformateur
                if (_selectedType == 'LOCAL_TRANSFORMATEUR') ...[
                  SizedBox(height: 16),
                  Text(
                    'CELLULE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTextField(_celluleFonctionController, 'Fonction de la cellule'),
                  _buildTextField(_celluleTypeController, 'Type de cellule'),
                  _buildTextField(_celluleMarqueController, 'Marque / modèle / année'),
                  _buildTextField(_celluleTensionController, 'Tension assignée'),
                  _buildTextField(_cellulePouvoirController, 'Pouvoir de coupure assigné (kA)'),
                  _buildTextField(_celluleNumerotationController, 'Numérotation / repérage cellule'),
                  _buildTextField(_celluleParafoudresController, 'Parafoudres installés sur l\'arrivée'),
                  _buildElementControleList('ÉLÉMENTS VÉRIFIÉS - CELLULE', _celluleElements, 'cellule'),

                  SizedBox(height: 16),
                  Text(
                    'TRANSFORMATEUR MT/BT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTextField(_transfoTypeController, 'Type de transformateur'),
                  _buildTextField(_transfoMarqueController, 'Marque/ Année de fabrication'),
                  _buildTextField(_transfoPuissanceController, 'Puissance assignée (kVA)'),
                  _buildTextField(_transfoTensionController, 'Tension primaire / secondaire'),
                  _buildTextField(_transfoBuchholzController, 'Présence du relais Buchholz'),
                  _buildTextField(_transfoRefroidissementController, 'Type de refroidissement'),
                  _buildTextField(_transfoRegimeController, 'Régime du neutre'),
                 _buildElementControleList('ÉLÉMENTS VÉRIFIÉS - TRANSFORMATEUR', _transfoElements, 'transformateur'),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
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
}