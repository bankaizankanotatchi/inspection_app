import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';

class AjouterCarteScreen extends StatefulWidget {
  final List<String> champs;
  final Map<String, String>? carte;

  const AjouterCarteScreen({
    super.key,
    required this.champs,
    this.carte,
  });

  @override
  State<AjouterCarteScreen> createState() => _AjouterCarteScreenState();
}

class _AjouterCarteScreenState extends State<AjouterCarteScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    for (var champ in widget.champs) {
      _controllers[champ] = TextEditingController(
        text: widget.carte?[champ] ?? '',
      );
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _sauvegarder() {
    // Pas de validation obligatoire pour tous les champs
    final nouvelleCarte = <String, String>{};
    for (var champ in widget.champs) {
      nouvelleCarte[champ] = _controllers[champ]!.text.trim();
    }
    Navigator.of(context).pop(nouvelleCarte);
  }

  void _annuler() {
    Navigator.of(context).pop();
  }

  // Vérifie si c'est un champ d'observations (multiligne)
  bool _estChampObservations(String champ) {
    return champ.toLowerCase().contains('observation') || 
           champ.toLowerCase().contains('remarque') ||
           champ.toLowerCase().contains('note');
  }

  @override
  Widget build(BuildContext context) {
    final isEdition = widget.carte != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdition ? 'Modifier la carte' : 'Ajouter une carte'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _annuler,
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ListView(
            children: [
              ...widget.champs.map((champ) {
                final estObservations = _estChampObservations(champ);
                
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        champ,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      estObservations
                          ? TextFormField(
                              controller: _controllers[champ],
                              maxLines: 4,
                              minLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Saisissez vos observations...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, 
                                  vertical: 12,
                                ),
                              ),
                            )
                          : TextFormField(
                              controller: _controllers[champ],
                              decoration: InputDecoration(
                                hintText: 'Saisissez ${champ.toLowerCase()}...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, 
                                  vertical: 16,
                                ),
                              ),
                            ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 20),
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
        ),
      ),
    );
  }
}