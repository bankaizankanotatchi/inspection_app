import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'dart:io';

class AjouterCoffretScreen extends StatefulWidget {
  final Mission mission;
  final String parentType; // 'local' ou 'zone'
  final int parentIndex;
  final bool isMoyenneTension;
  final int? zoneIndex; // Pour basse tension ou moyenne tension dans zone
  final CoffretArmoire? coffret; // Pour l'édition
  final int? coffretIndex; // Pour l'édition
  final bool isInZone; // Nouveau paramètre
  final String? qrCode; 

  const AjouterCoffretScreen({
    super.key,
    required this.mission,
    required this.parentType,
    required this.parentIndex,
    required this.isMoyenneTension,
    this.zoneIndex,
    this.coffret,
    this.coffretIndex,
    this.isInZone = false, // Par défaut false
    this.qrCode, 
  });

  bool get isEdition => coffret != null;

  @override
  State<AjouterCoffretScreen> createState() => _AjouterCoffretScreenState();
}

class _AjouterCoffretScreenState extends State<AjouterCoffretScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _repereController = TextEditingController();
  String? _selectedType;
    final _qrCodeController = TextEditingController();
  bool _isQrCodeValid = false;

  // Informations générales
  bool _zoneAtex = false;
  String _domaineTension = '230/400';
  bool _identificationArmoire = false;
  bool _signalisationDanger = false;
  bool _presenceSchema = false;
  bool _presenceParafoudre = false;
  bool _verificationThermographie = false;

  // Alimentations (dépend du type de coffret)
  List<Alimentation> _alimentations = [];
  Alimentation? _protectionTete;

  // Points de vérification
  List<PointVerification> _pointsVerification = [];

  // Observations libres
  final _observationController = TextEditingController();
  List<String> _observationPhotos = [];
  final List<ObservationLibre> _observationsExistantes = [];

  // Photos du coffret
  final ImagePicker _picker = ImagePicker();
  List<String> _coffretPhotos = [];
  bool _isLoadingPhotos = false;

  @override
  void initState() {
    super.initState();
     if (widget.qrCode != null) {
      _qrCodeController.text = widget.qrCode!;
      _validateQrCode(widget.qrCode!);
    }
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    } else {
      _initializeAlimentations();
    }
  }

    // Méthode pour valider le QR code
  void _validateQrCode(String qrCode) {
    if (qrCode.isEmpty) {
      setState(() => _isQrCodeValid = false);
      return;
    }

    // Vérifier l'unicité
    final existing = HiveService.findCoffretByQrCode(widget.mission.id, qrCode);
    
    if (widget.isEdition) {
      // En édition, le QR code peut être le même que celui du coffret existant
      _isQrCodeValid = true;
    } else {
      // En création, le QR code doit être unique
      _isQrCodeValid = existing == null;
    }
  }

void _chargerDonneesExistantes() {
  final coffret = widget.coffret!;
  _nomController.text = coffret.nom;
  _selectedType = coffret.type;
  _repereController.text = coffret.repere ?? '';
  _zoneAtex = coffret.zoneAtex;
  _domaineTension = coffret.domaineTension;
  _identificationArmoire = coffret.identificationArmoire;
  _signalisationDanger = coffret.signalisationDanger;
  _presenceSchema = coffret.presenceSchema;
  _presenceParafoudre = coffret.presenceParafoudre;
  _verificationThermographie = coffret.verificationThermographie;
  _alimentations = List.from(coffret.alimentations);
  _protectionTete = coffret.protectionTete;
  
  // Charger les points de vérification AVEC leurs photos
  _pointsVerification = List.from(coffret.pointsVerification.map((point) {
    return PointVerification(
      pointVerification: point.pointVerification,
      conformite: point.conformite,
      observation: point.observation,
      referenceNormative: point.referenceNormative,
      priorite: point.priorite,
      photos: List.from(point.photos),
    );
  }));

  // Charger les observations existantes
  _observationsExistantes.addAll(coffret.observationsLibres);

  // Charger les photos du coffret
  if (coffret.photos.isNotEmpty) {
    _coffretPhotos = List.from(coffret.photos);
  }

  _initializeForCoffretType(_selectedType);
}
  // ===== MÉTHODES POUR GESTION DES PHOTOS DU COFFRET =====

  Future<void> _prendrePhotoCoffret() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets');
        setState(() {
          _coffretPhotos.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _choisirPhotoCoffretDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets');
        setState(() {
          _coffretPhotos.add(savedPath);
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
          ],
        ),
        SizedBox(height: 8),

        if (_isLoadingPhotos && title.contains('Coffret'))
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
                    style: TextStyle(color: Colors.grey.shade600),
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

            SizedBox(width: 4),
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
          'OBSERVATIONS SUR LE COFFRET',
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

  void _initializeAlimentations() {
    _alimentations = [];
    _protectionTete = null;
  }

  void _onTypeChanged(String? newType) {
    setState(() {
      _selectedType = newType;
      _initializeForCoffretType(newType);
    });
  }

  void _initializeForCoffretType(String? type) {
    if (type == null) return;

    // Si c'est une édition, on garde les points existants
    if (!widget.isEdition) {
      final points = HiveService.getPointsVerificationForCoffret(type);
      _pointsVerification = points
          .map(
            (point) => PointVerification(
              pointVerification: point,
              conformite: 'non_applicable',
            ),
          )
          .toList();
    }

    // Initialiser les alimentations selon le type (seulement si création)
    if (!widget.isEdition) {
      _alimentations.clear();
      _protectionTete = null;

      switch (type) {
        case 'Tableau urbain réduit (TUR)':
          _alimentations.add(
            Alimentation(
              typeProtection: '',
              pdcKA: '',
              calibre: '',
              sectionCable: '',
            ),
          );
          _protectionTete = Alimentation(
            typeProtection: '',
            pdcKA: '',
            calibre: '',
            sectionCable: '',
          );
          break;

        case 'INVERSEUR':
          _alimentations.addAll([
            Alimentation(
              typeProtection: '',
              pdcKA: '',
              calibre: '',
              sectionCable: '',
            ),
            Alimentation(
              typeProtection: '',
              pdcKA: '',
              calibre: '',
              sectionCable: '',
            ),
            Alimentation(
              typeProtection: '',
              pdcKA: '',
              calibre: '',
              sectionCable: '',
            ),
          ]);
          break;

        default:
          _alimentations.add(
            Alimentation(
              typeProtection: '',
              pdcKA: '',
              calibre: '',
              sectionCable: '',
            ),
          );
          _protectionTete = Alimentation(
            typeProtection: '',
            pdcKA: '',
            calibre: '',
            sectionCable: '',
          );
          break;
      }
    }
  }

  void _sauvegarder() async {
    if (_formKey.currentState!.validate() && _selectedType != null) {
      try {
        final coffret = CoffretArmoire(
          qrCode: _qrCodeController.text.trim(), 
          nom: _nomController.text.trim(),
          type: _selectedType!,
          repere: _repereController.text.trim().isNotEmpty
              ? _repereController.text.trim()
              : null,
          zoneAtex: _zoneAtex,
          domaineTension: _domaineTension,
          identificationArmoire: _identificationArmoire,
          signalisationDanger: _signalisationDanger,
          presenceSchema: _presenceSchema,
          presenceParafoudre: _presenceParafoudre,
          verificationThermographie: _verificationThermographie,
          alimentations: _alimentations,
          protectionTete: _protectionTete,
          pointsVerification: _pointsVerification,
          observationsLibres: _observationsExistantes, // Liste d'ObservationLibre
          photos: _coffretPhotos, // Photos du coffret
        );

        bool success;

        if (widget.isEdition) {
          success = await _updateCoffret(coffret);
        } else {
          // Logique de création
          if (widget.parentType == 'local') {
            if (widget.isMoyenneTension) {
              if (widget.isInZone && widget.zoneIndex != null) {
                // Coffret dans un local qui est dans une zone MT
                success = await _addCoffretToLocalInMoyenneTensionZone(coffret);
              } else {
                // Coffret dans un local MT indépendant
                success = await HiveService.addCoffretToMoyenneTensionLocal(
                  missionId: widget.mission.id,
                  localIndex: widget.parentIndex,
                  coffret: coffret,
                  qrCode: widget.qrCode!

                );
              }
            } else {
              // Coffret dans un local BT (toujours dans une zone)
              success = await HiveService.addCoffretToBasseTensionLocal(
                missionId: widget.mission.id,
                zoneIndex: widget.zoneIndex ?? 0,
                localIndex: widget.parentIndex,
                coffret: coffret,
              );
            }
          } else {
            // Coffret dans une zone
            if (widget.isMoyenneTension) {
              success = await HiveService.addCoffretToMoyenneTensionZone(
                missionId: widget.mission.id,
                zoneIndex: widget.parentIndex,
                coffret: coffret,
              );
            } else {
              success = await HiveService.addCoffretToBasseTensionZone(
                missionId: widget.mission.id,
                zoneIndex: widget.parentIndex,
                coffret: coffret,
              );
            }
          }
        }

        if (success) {
          Navigator.pop(context, true);
        } else {
          _showError('Erreur lors de la sauvegarde');
        }
      } catch (e) {
        _showError('Erreur: $e');
      }
    }
  }

  Future<bool> _addCoffretToLocalInMoyenneTensionZone(
    CoffretArmoire coffret,
  ) async {
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(
        widget.mission.id,
      );

      if (widget.zoneIndex != null &&
          widget.zoneIndex! < audit.moyenneTensionZones.length) {
        final zone = audit.moyenneTensionZones[widget.zoneIndex!];

        if (widget.parentIndex < zone.locaux.length) {
          zone.locaux[widget.parentIndex].coffrets.add(coffret);
          await HiveService.saveAuditInstallations(audit);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Erreur _addCoffretToLocalInMoyenneTensionZone: $e');
      return false;
    }
  }

  Future<bool> _updateCoffret(CoffretArmoire newCoffret) async {
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(
        widget.mission.id,
      );

      CoffretArmoire? targetCoffret;
      bool found = false;

      if (widget.parentType == 'local') {
        if (widget.isMoyenneTension) {
          if (widget.isInZone && widget.zoneIndex != null) {
            // Coffret dans un local qui est dans une zone MT
            if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
              final zone = audit.moyenneTensionZones[widget.zoneIndex!];
              if (widget.parentIndex < zone.locaux.length) {
                final local = zone.locaux[widget.parentIndex];
                if (widget.coffretIndex! < local.coffrets.length) {
                  targetCoffret = local.coffrets[widget.coffretIndex!];
                  found = true;
                }
              }
            }
          } else {
            // Coffret dans un local MT indépendant
            if (widget.parentIndex < audit.moyenneTensionLocaux.length) {
              final local = audit.moyenneTensionLocaux[widget.parentIndex];
              if (widget.coffretIndex! < local.coffrets.length) {
                targetCoffret = local.coffrets[widget.coffretIndex!];
                found = true;
              }
            }
          }
        } else {
          // Logique pour basse tension
          if (widget.zoneIndex != null &&
              widget.zoneIndex! < audit.basseTensionZones.length) {
            final zone = audit.basseTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length) {
              final local = zone.locaux[widget.parentIndex];
              if (widget.coffretIndex! < local.coffrets.length) {
                targetCoffret = local.coffrets[widget.coffretIndex!];
                found = true;
              }
            }
          }
        }
      } else {
        // Coffret dans une zone
        if (widget.isMoyenneTension) {
          if (widget.parentIndex < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.parentIndex];
            if (widget.coffretIndex! < zone.coffrets.length) {
              targetCoffret = zone.coffrets[widget.coffretIndex!];
              found = true;
            }
          }
        } else {
          if (widget.parentIndex < audit.basseTensionZones.length) {
            final zone = audit.basseTensionZones[widget.parentIndex];
            if (widget.coffretIndex! < zone.coffretsDirects.length) {
              targetCoffret = zone.coffretsDirects[widget.coffretIndex!];
              found = true;
            }
          }
        }
      }

      if (found && targetCoffret != null) {
        // Mettre à jour toutes les propriétés
        targetCoffret.nom = newCoffret.nom;
        targetCoffret.type = newCoffret.type;
        targetCoffret.repere = newCoffret.repere;
        targetCoffret.zoneAtex = newCoffret.zoneAtex;
        targetCoffret.domaineTension = newCoffret.domaineTension;
        targetCoffret.identificationArmoire = newCoffret.identificationArmoire;
        targetCoffret.signalisationDanger = newCoffret.signalisationDanger;
        targetCoffret.presenceSchema = newCoffret.presenceSchema;
        targetCoffret.presenceParafoudre = newCoffret.presenceParafoudre;
        targetCoffret.verificationThermographie =
            newCoffret.verificationThermographie;
        targetCoffret.alimentations = newCoffret.alimentations;
        targetCoffret.protectionTete = newCoffret.protectionTete;
        targetCoffret.pointsVerification = newCoffret.pointsVerification;
        targetCoffret.observationsLibres = newCoffret.observationsLibres;
        targetCoffret.photos = newCoffret.photos;

        await HiveService.saveAuditInstallations(audit);
        print('✅ Coffret mis à jour avec succès');
        return true;
      } else {
        print('❌ Coffret non trouvé pour mise à jour');
        return false;
      }
    } catch (e) {
      print('❌ Erreur updateCoffret: $e');
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildAlimentationCard(
    Alimentation alimentation,
    String title, {
    bool isProtectionTete = false,
  }) {
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
            _buildAlimentationForm(
              alimentation,
              isProtectionTete: isProtectionTete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlimentationForm(
    Alimentation alimentation, {
    bool isProtectionTete = false,
  }) {
    return Column(
      children: [
        _buildAlimentationField(
          'Type de protection',
          alimentation.typeProtection,
          (value) => alimentation.typeProtection = value,
        ),
        _buildAlimentationField(
          'PDC kA',
          alimentation.pdcKA,
          (value) => alimentation.pdcKA = value,
        ),
        _buildAlimentationField(
          isProtectionTete ? 'Calibre protection' : 'Calibre',
          alimentation.calibre,
          (value) => alimentation.calibre = value,
        ),
        _buildAlimentationField(
          'Section de câble',
          alimentation.sectionCable,
          (value) => alimentation.sectionCable = value,
        ),
      ],
    );
  }

  Widget _buildAlimentationField(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => onChanged(value),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

Widget _buildPointWithPriorityAndObservation(PointVerification point, int index) {
  return Card(
    margin: EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            point.pointVerification,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12),
          
          // Ligne 1: Conformité
          Container(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              value: point.conformite,
              onChanged: (String? newValue) {
                setState(() {
                  point.conformite = newValue!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Conformité',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(
                  value: 'oui',
                  child: Text('Oui', style: TextStyle(color: Colors.green)),
                ),
                DropdownMenuItem(
                  value: 'non',
                  child: Text('Non', style: TextStyle(color: Colors.red)),
                ),
                DropdownMenuItem(
                  value: 'non_applicable',
                  child: Text('Non applicable', style: TextStyle(color: Colors.orange)),
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
              value: point.priorite,
              onChanged: (int? newValue) {
                setState(() {
                  point.priorite = newValue;
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
            initialValue: point.observation,
            onChanged: (value) => point.observation = value,
            decoration: InputDecoration(
              labelText: 'Observation',
              border: OutlineInputBorder(),
              hintText: 'Saisissez vos observations...',
            ),
            maxLines: 2,
          ),
          
          SizedBox(height: 12),
          
          // Ligne 4: Référence normative
          TextFormField(
            initialValue: point.referenceNormative,
            onChanged: (value) => point.referenceNormative = value,
            decoration: InputDecoration(
              labelText: 'Référence normative',
              border: OutlineInputBorder(),
              hintText: 'Ex: NF C 15-100 art. 435',
            ),
          ),
          
          SizedBox(height: 16),
          
          // Ligne 5: Photos pour ce point
          _buildPhotosForPoint(point, index),
        ],
      ),
    ),
  );
}
 
 // Nouvelle méthode pour gérer les photos par point de vérification
Widget _buildPhotosForPoint(PointVerification point, int pointIndex) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Photos pour ce point',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '${point.photos.length} photo(s)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      SizedBox(height: 8),
      
      // Affichage des photos existantes
      if (point.photos.isNotEmpty)
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.8,
          ),
          itemCount: point.photos.length,
          itemBuilder: (context, photoIndex) {
            return GestureDetector(
              onTap: () => _previsualiserPhoto(point.photos, photoIndex),
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
                        File(point.photos[photoIndex]),
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
                      onTap: () => _supprimerPhotoPoint(point, photoIndex, pointIndex),
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
              onPressed: () => _prendrePhotoPourPoint(point, pointIndex),
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
              onPressed: () => _choisirPhotoPourPoint(point, pointIndex),
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

// Méthode pour prendre une photo pour un point spécifique
Future<void> _prendrePhotoPourPoint(PointVerification point, int pointIndex) async {
  try {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    
    if (photo != null) {
      final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'point_photos');
      setState(() {
        point.photos.add(savedPath);
      });
      
      // Sauvegarder la photo dans le coffret
      await _savePhotoToCoffretPoint(pointIndex, savedPath);
    }
  } catch (e) {
    _showError('Erreur lors de la prise de photo: $e');
  }
}

// Méthode pour choisir une photo depuis la galerie pour un point spécifique
Future<void> _choisirPhotoPourPoint(PointVerification point, int pointIndex) async {
  try {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    
    if (photo != null) {
      final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'point_photos');
      setState(() {
        point.photos.add(savedPath);
      });
      
      await _savePhotoToCoffretPoint(pointIndex, savedPath);
    }
  } catch (e) {
    _showError('Erreur lors de la sélection: $e');
  }
}

// Nouvelle méthode pour sauvegarder la photo dans le coffret
Future<void> _savePhotoToCoffretPoint(int pointIndex, String cheminPhoto) async {
  try {
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
    
    CoffretArmoire? targetCoffret;
    bool found = false;
    
    // Recherche du coffret en fonction des paramètres
    if (widget.parentType == 'local') {
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length) {
              final local = zone.locaux[widget.parentIndex];
              if (widget.coffretIndex != null && widget.coffretIndex! < local.coffrets.length) {
                targetCoffret = local.coffrets[widget.coffretIndex!];
                found = true;
              }
            }
          }
        } else {
          if (widget.parentIndex < audit.moyenneTensionLocaux.length) {
            final local = audit.moyenneTensionLocaux[widget.parentIndex];
            if (widget.coffretIndex != null && widget.coffretIndex! < local.coffrets.length) {
              targetCoffret = local.coffrets[widget.coffretIndex!];
              found = true;
            }
          }
        }
      } else {
        if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length) {
            final local = zone.locaux[widget.parentIndex];
            if (widget.coffretIndex != null && widget.coffretIndex! < local.coffrets.length) {
              targetCoffret = local.coffrets[widget.coffretIndex!];
              found = true;
            }
          }
        }
      }
    } else {
      if (widget.isMoyenneTension) {
        if (widget.parentIndex < audit.moyenneTensionZones.length) {
          final zone = audit.moyenneTensionZones[widget.parentIndex];
          if (widget.coffretIndex != null && widget.coffretIndex! < zone.coffrets.length) {
            targetCoffret = zone.coffrets[widget.coffretIndex!];
            found = true;
          }
        }
      } else {
        if (widget.parentIndex < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.parentIndex];
          if (widget.coffretIndex != null && widget.coffretIndex! < zone.coffretsDirects.length) {
            targetCoffret = zone.coffretsDirects[widget.coffretIndex!];
            found = true;
          }
        }
      }
    }
    
    if (found && targetCoffret != null && pointIndex < targetCoffret.pointsVerification.length) {
      targetCoffret.pointsVerification[pointIndex].photos.add(cheminPhoto);
      await HiveService.saveAuditInstallations(audit);
    }
  } catch (e) {
    print('❌ Erreur savePhotoToCoffretPoint: $e');
  }
}

// Méthode pour supprimer une photo d'un point
void _supprimerPhotoPoint(PointVerification point, int photoIndex, int pointIndex) async {
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
              point.photos.removeAt(photoIndex);
            });
            
            await _removePhotoFromCoffretPoint(pointIndex, photoIndex);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Supprimer'),
        ),
      ],
    ),
  );
}

// Nouvelle méthode pour supprimer la photo du coffret
Future<void> _removePhotoFromCoffretPoint(int pointIndex, int photoIndex) async {
  try {
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
    
    CoffretArmoire? targetCoffret;
    bool found = false;
    
    // Recherche du coffret en fonction des paramètres
    if (widget.parentType == 'local') {
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length) {
              final local = zone.locaux[widget.parentIndex];
              if (widget.coffretIndex != null && widget.coffretIndex! < local.coffrets.length) {
                targetCoffret = local.coffrets[widget.coffretIndex!];
                found = true;
              }
            }
          }
        } else {
          if (widget.parentIndex < audit.moyenneTensionLocaux.length) {
            final local = audit.moyenneTensionLocaux[widget.parentIndex];
            if (widget.coffretIndex != null && widget.coffretIndex! < local.coffrets.length) {
              targetCoffret = local.coffrets[widget.coffretIndex!];
              found = true;
            }
          }
        }
      } else {
        if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length) {
            final local = zone.locaux[widget.parentIndex];
            if (widget.coffretIndex != null && widget.coffretIndex! < local.coffrets.length) {
              targetCoffret = local.coffrets[widget.coffretIndex!];
              found = true;
            }
          }
        }
      }
    } else {
      if (widget.isMoyenneTension) {
        if (widget.parentIndex < audit.moyenneTensionZones.length) {
          final zone = audit.moyenneTensionZones[widget.parentIndex];
          if (widget.coffretIndex != null && widget.coffretIndex! < zone.coffrets.length) {
            targetCoffret = zone.coffrets[widget.coffretIndex!];
            found = true;
          }
        }
      } else {
        if (widget.parentIndex < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.parentIndex];
          if (widget.coffretIndex != null && widget.coffretIndex! < zone.coffretsDirects.length) {
            targetCoffret = zone.coffretsDirects[widget.coffretIndex!];
            found = true;
          }
        }
      }
    }
    
    if (found && targetCoffret != null && pointIndex < targetCoffret.pointsVerification.length) {
      if (photoIndex < targetCoffret.pointsVerification[pointIndex].photos.length) {
        targetCoffret.pointsVerification[pointIndex].photos.removeAt(photoIndex);
        await HiveService.saveAuditInstallations(audit);
      }
    }
  } catch (e) {
    print('❌ Erreur removePhotoFromCoffretPoint: $e');
  }
}


 
  Widget _buildTypeDropdown() {
    final coffretTypes = HiveService.getCoffretTypes();

    return DropdownButtonFormField<String>(
      value: _selectedType,
      onChanged: _onTypeChanged,
      decoration: InputDecoration(
        labelText: 'Type de coffret*',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      items: coffretTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(
            type,
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
        title: Text(
          widget.isEdition
              ? 'Modifier le Coffret'
              : 'Ajouter un Coffret/Armoire',
        ),
        backgroundColor: widget.isMoyenneTension ? Colors.blue : Colors.blue,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: Icon(Icons.check), onPressed: _sauvegarder)],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ListView(
            children: [
              // Indication si dans une zone
              if (widget.isInZone)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ce coffret sera ajouté dans une zone',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Informations de base
              Text(
                'INFORMATIONS DE BASE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              SizedBox(height: 16),

              _buildTextField(
                _nomController,
                'Nom du coffret*',
                isRequired: true,
              ),
              _buildTextField(_repereController, 'Repère'),

              _buildTypeDropdown(),
              SizedBox(height: 24),

              // Section Photos du coffret
              Card(
                elevation: 1,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: _buildPhotosSection(
                    'Photos du coffret',
                    _coffretPhotos,
                    _prendrePhotoCoffret,
                    _choisirPhotoCoffretDepuisGalerie,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Informations générales
              Text(
                'INFORMATIONS GÉNÉRALES',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              SizedBox(height: 16),

              _buildCheckbox(
                'Zone ATEX',
                _zoneAtex,
                (value) => setState(() => _zoneAtex = value ?? false),
              ),
              _buildCheckbox(
                'Identification de l\'armoire',
                _identificationArmoire,
                (value) =>
                    setState(() => _identificationArmoire = value ?? false),
              ),
              _buildCheckbox(
                'Signalisation de danger électrique',
                _signalisationDanger,
                (value) =>
                    setState(() => _signalisationDanger = value ?? false),
              ),
              _buildCheckbox(
                'Présence de schéma électrique',
                _presenceSchema,
                (value) => setState(() => _presenceSchema = value ?? false),
              ),
              _buildCheckbox(
                'Présence de parafoudre',
                _presenceParafoudre,
                (value) => setState(() => _presenceParafoudre = value ?? false),
              ),
              _buildCheckbox(
                'Vérification par thermographie infrarouge',
                _verificationThermographie,
                (value) =>
                    setState(() => _verificationThermographie = value ?? false),
              ),

              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _domaineTension,
                onChanged: (value) =>
                    setState(() => _domaineTension = value ?? '230/400'),
                decoration: InputDecoration(
                  labelText: 'Domaine de tension',
                  border: OutlineInputBorder(),
                ),
                items: ['230/400', '400/690', 'Autre'].map((tension) {
                  return DropdownMenuItem(value: tension, child: Text(tension));
                }).toList(),
              ),
              SizedBox(height: 24),

              // Alimentations (selon le type)
              if (_selectedType != null) ...[
                Text(
                  'ALIMENTATIONS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 16),

                if (_selectedType == 'INVERSEUR') ...[
                  if (_alimentations.length >= 3) ...[
                    _buildAlimentationCard(_alimentations[0], 'ALIMENTATION 1'),
                    _buildAlimentationCard(_alimentations[1], 'ALIMENTATION 2'),
                    _buildAlimentationCard(
                      _alimentations[2],
                      'SORTIE INVERSEUR',
                    ),
                  ],
                ] else if (_selectedType == 'Tableau urbain réduit (TUR)') ...[
                  if (_alimentations.isNotEmpty)
                    _buildAlimentationCard(
                      _alimentations[0],
                      'ORIGINE DE LA SOURCE D\'ALIMENTATION',
                    ),
                  if (_protectionTete != null)
                    _buildAlimentationCard(
                      _protectionTete!,
                      'PROTECTION DE TÊTE DE COFFRET/ARMOIRE',
                      isProtectionTete: true,
                    ),
                ] else ...[
                  if (_alimentations.isNotEmpty)
                    _buildAlimentationCard(
                      _alimentations[0],
                      'ORIGINE DE LA SOURCE D\'ALIMENTATION',
                    ),
                  if (_protectionTete != null)
                    _buildAlimentationCard(
                      _protectionTete!,
                      'PROTECTION DE TÊTE DE COFFRET/ARMOIRE',
                      isProtectionTete: true,
                    ),
                ],
                SizedBox(height: 24),
              ],

              // Points de vérification
              if (_selectedType != null && _pointsVerification.isNotEmpty) ...[
                Text(
                  'POINTS DE VÉRIFICATION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 16),

                ..._pointsVerification.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  return _buildPointWithPriorityAndObservation(point, index);
                }).toList(),
                SizedBox(height: 24),
              ],

              // Observations libres avec photos
               if(!widget.isEdition)
              _buildObservationsSection(),
               if(!widget.isEdition)
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isMultiline = false,
    bool isRequired = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        maxLines: isMultiline ? 3 : 1,
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ce champ est obligatoire';
                }
                return null;
              }
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _repereController.dispose();
    _observationController.dispose();
    super.dispose();
  }
}