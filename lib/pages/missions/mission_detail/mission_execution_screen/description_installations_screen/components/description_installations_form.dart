// description_installations_form.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/item_detail_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/constants/app_theme.dart';

class DescriptionInstallationsForm extends StatefulWidget {
  final Mission mission;
  final String title;
  final String sectionKey;
  final List<String> champs;
  final List<String> requiredFields;
  final void Function(String sectionKey) onComplete;
  final bool isComplete;

  const DescriptionInstallationsForm({
    super.key,
    required this.mission,
    required this.title,
    required this.sectionKey,
    required this.champs,
    required this.requiredFields,
    required this.onComplete,
    required this.isComplete,
  });

  @override
  State<DescriptionInstallationsForm> createState() => _DescriptionInstallationsFormState();
}

class _DescriptionInstallationsFormState extends State<DescriptionInstallationsForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _photoPaths = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _addingMore = false;
  List<InstallationItem> _items = [];
  
  // Variable pour suivre la validation des photos
  bool _photosValid = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadExistingItems();
  }

  void _initializeForm() {
    // IMPORTANT: Toujours vider et recréer les contrôleurs
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    
    for (var champ in widget.champs) {
      _controllers[champ] = TextEditingController();
    }
    _photoPaths.clear();
    _addingMore = false;
    _photosValid = false; // Les photos sont obligatoires
  }

  Future<void> _loadExistingItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await HiveService.getInstallationItemsFromSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
      );
      
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _photoPaths.add(photo.path);
        _photosValid = _photoPaths.isNotEmpty;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        _photoPaths.add(photo.path);
        _photosValid = _photoPaths.isNotEmpty;
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
      _photosValid = _photoPaths.isNotEmpty;
    });
  }

  // Validation de tous les champs du formulaire
  bool _validateForm() {
    bool isValid = true;
    
    // Vérifier tous les champs textuels
    for (var champ in widget.champs) {
      if (_controllers[champ]!.text.trim().isEmpty) {
        // Pour l'édition, on valide immédiatement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Le champ "$champ" est obligatoire'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        isValid = false;
        break;
      }
    }
    
    // Vérifier les photos (obligatoires aussi)
    if (!_photosValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Au moins une photo est obligatoire'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      isValid = false;
    }
    
    return isValid;
  }

  Future<void> _saveItem() async {
    // Valider le formulaire
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = <String, String>{};
      for (var champ in widget.champs) {
        data[champ] = _controllers[champ]!.text.trim();
      }

      final item = InstallationItem(
        data: data,
        photoPaths: List.from(_photoPaths),
      );

      final success = await HiveService.addInstallationItemToSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
        item: item,
      );

      if (success) {
        // REINITIALISER LE FORMULAIRE TOUJOURS
        _resetForm();
        
        // Demander si on veut ajouter un autre seulement si ce n'est pas en mode "ajouter un autre"
        if (!_addingMore) {
          final addAnother = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Élément ajouté'),
              content: Text('Voulez-vous ajouter un autre élément ?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    // Appeler onComplete pour marquer comme terminé
                    widget.onComplete(widget.sectionKey);
                  },
                  child: Text('Terminer'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Ajouter un autre'),
                ),
              ],
            ),
          );

          if (addAnother != null && addAnother) {
            setState(() {
              _addingMore = true;
            });
          }
        }
      } else {
        throw Exception('Échec de la sauvegarde');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _resetForm() {
    _formKey.currentState?.reset();
    for (var controller in _controllers.values) {
      controller.clear();
    }
    setState(() {
      _photoPaths.clear();
      _photosValid = false;
    });
  }

  void _viewItemDetails(InstallationItem item, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(
          mission: widget.mission,
          sectionKey: widget.sectionKey,
          item: item,
          index: index,
          champs: widget.champs,
          requiredFields: widget.champs, // Tous les champs sont obligatoires
        ),
      ),
    );

    if (result == true) {
      await _loadExistingItems();
    }
  }

  void _showPhotoFullScreen(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Image en plein écran
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(
                  File(_photoPaths[index]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Bouton de fermeture
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Numéro de la photo
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Photo ${index + 1}/${_photoPaths.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Bouton suppression
            Positioned(
              bottom: 40,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto(index);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour obtenir les champs à afficher
  Map<String, String> _getDisplayFields(InstallationItem item) {
    final Map<String, String> result = {};
    int displayed = 0;
    
    // Essayer d'obtenir les 2 premiers champs non vides
    for (var champ in widget.champs) {
      if (displayed >= 2) break;
      
      final value = item.data[champ];
      if (value != null && value.trim().isNotEmpty) {
        // Formater le label pour qu'il soit plus court si nécessaire
        final label = champ.length > 20 ? '${champ.substring(0, 20)}...' : champ;
        result[label] = value;
        displayed++;
      }
    }
    
    // Si on n'a pas assez de champs, ajouter les suivants même s'ils sont vides
    if (result.length < 2) {
      for (var champ in widget.champs) {
        if (result.length >= 2) break;
        if (!result.containsKey(champ)) {
          final value = item.data[champ] ?? '—';
          final label = champ.length > 20 ? '${champ.substring(0, 20)}...' : champ;
          result[label] = value;
        }
      }
    }
    
    return result;
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Titre de la section
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
                  SizedBox(height: 16),

                  // Liste des éléments existants
                  if (_items.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Éléments déjà ajoutés (${_items.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final fields = _getDisplayFields(item);
                              
                              return GestureDetector(
                                onTap: () => _viewItemDetails(item, index),
                                child: Container(
                                  width: 200,
                                  margin: EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Contenu principal
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Indicateur de position
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryBlue,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Élément ${index + 1}',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Spacer(),
                                                if (item.photoPaths.isNotEmpty)
                                                  Container(
                                                    padding: EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.photo,
                                                      size: 14,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            
                                            SizedBox(height: 12),
                                            
                                            // Affichage des champs
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: fields.entries.map((entry) {
                                                  return Padding(
                                                    padding: EdgeInsets.only(bottom: 8),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          entry.key,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.grey.shade600,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        SizedBox(height: 2),
                                                        Text(
                                                          entry.value,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.black87,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Badge pour les photos
                                      if (item.photoPaths.isNotEmpty)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${item.photoPaths.length}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 16),
                      ],
                    ),

                  // Formulaire d'ajout - TOUS LES CHAMPS OBLIGATOIRES
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Champs du formulaire - tous obligatoires
                        ...widget.champs.map((champ) {
                          final isObservationField = champ.toLowerCase().contains('observation') || 
                                                    champ.toLowerCase().contains('note') || 
                                                    champ.toLowerCase().contains('commentaire');
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$champ*', // Astérisque pour tous
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                TextFormField(
                                  controller: _controllers[champ],
                                  maxLines: isObservationField ? 5 : 2,
                                  minLines: isObservationField ? 3 : 1,
                                  decoration: InputDecoration(
                                    hintText: 'Saisissez ${champ.toLowerCase()}...',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: AppTheme.primaryBlue),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, 
                                      vertical: isObservationField ? 12 : 10
                                    ),
                                    alignLabelWithHint: isObservationField,
                                    errorStyle: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    // Tous les champs sont obligatoires
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ce champ est obligatoire';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        // Section photos - OBLIGATOIRE
                        Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Photos*',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '(obligatoire)',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              // Message si pas de photos
                              if (!_photosValid)
                                Container(
                                  padding: EdgeInsets.all(12),
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.red, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Au moins une photo est requise',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              // Boutons pour ajouter des photos
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _takePhoto,
                                      icon: Icon(Icons.camera_alt_outlined),
                                      label: Text('Prendre une photo'),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        side: BorderSide(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _pickFromGallery,
                                      icon: Icon(Icons.photo_library_outlined),
                                      label: Text('Galerie'),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        side: BorderSide(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              
                              // Affichage des photos en grille
                              if (_photoPaths.isNotEmpty)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: _photoPaths.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => _showPhotoFullScreen(index),
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: FileImage(File(_photoPaths[index])),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          // Overlay au survol
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: Colors.black.withOpacity(0.1),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.zoom_in,
                                                  color: Colors.white.withOpacity(0.8),
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Numéro de la photo en bas à gauche
                                          Positioned(
                                            bottom: 4,
                                            left: 4,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Bouton de suppression rapide
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _removePhoto(index),
                                              child: Container(
                                                width: 22,
                                                height: 22,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton d'action (dans le scroll, pas fixe)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveItem,
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
                                Text(_addingMore ? 'AJOUTER UN AUTRE' : 'SAUVEGARDER'),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 20), // Espace en bas pour le scroll
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}