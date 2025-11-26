import 'package:flutter/material.dart';
import 'package:inspec_app/screens/pages/home/home_screen.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../models/verificateur.dart';
import '../constants/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _matriculeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureMatricule = true; // Pour gérer la visibilité du matricule
  String? _errorMessage;

  @override
  void dispose() {
    _nomController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

Future<void> _login() async {
  // Réinitialiser le message d'erreur
  setState(() {
    _errorMessage = null;
  });

  // Valider le formulaire
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  final nom = _nomController.text.trim();
  final matricule = _matriculeController.text.trim();

  try {
// 1️⃣ Vérifier si l'utilisateur existe localement (par matricule)
final allUsers = HiveService.getAllUsers();
Verificateur? localUser;
try {
  localUser = allUsers.firstWhere(
    (user) => user.matricule.toUpperCase() == matricule.toUpperCase(),
  );
} catch (e) {
  localUser = null;
}

if (localUser != null) {
  if (localUser.nom.toLowerCase() == nom.toLowerCase()) {
    // Connexion locale réussie
    await HiveService.saveCurrentUser(localUser);
    _navigateToHome(localUser);
    return;
  } else {
    setState(() {
      _errorMessage = 'Nom ou matricule incorrect';
      _isLoading = false;
    });
    return;
  }
}

    // 2️⃣ Première connexion → Vérifier la connexion internet
    final hasConnection = await SupabaseService.testConnection();
    if (!hasConnection) {
      setState(() {
        _errorMessage = 'Aucune connexion Internet.\nVeuillez vous connecter pour la première fois.';
        _isLoading = false;
      });
      return;
    }

    // 3️⃣ Vérifier l'utilisateur sur Supabase
    final user = await SupabaseService.verifyUser(nom, matricule);
    if (user != null) {
      // Utilisateur trouvé → Sauvegarder localement
      await HiveService.saveCurrentUser(user);
      _navigateToHome(user);
    } else {
      setState(() {
        _errorMessage = 'Utilisateur non trouvé.\nVérifiez votre nom et matricule.';
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Erreur de connexion : ${e.toString()}';
      _isLoading = false;
    });
  }
}

  void _navigateToHome(Verificateur user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/
                  Image.asset("assets/icon/app_icon.png", height: 100),
                  const SizedBox(height: 16),

                  // Titre
                  Text(
                    'Inspection App',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Sous-titre
                  Text(
                    'Connectez-vous pour continuer',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),

                  // Champ Nom
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      hintText: 'Ex: Jean Dupont',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      if (value.trim().length < 3) {
                        return 'Le nom doit contenir au moins 3 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ Matricule (avec visibilité)
                  TextFormField(
                    controller: _matriculeController,
                    obscureText: _obscureMatricule,
                    decoration: InputDecoration(
                      labelText: 'Matricule',
                      hintText: 'Ex: VER001',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureMatricule
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureMatricule = !_obscureMatricule;
                          });
                        },
                        tooltip: _obscureMatricule
                            ? 'Afficher le matricule'
                            : 'Masquer le matricule',
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre matricule';
                      }
                      if (value.trim().length < 3) {
                        return 'Le matricule doit contenir au moins 3 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Message d'erreur
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bouton de connexion
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Se connecter'),
                  ),
                  const SizedBox(height: 24),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Première connexion ?\nUne connexion Internet est requise.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}