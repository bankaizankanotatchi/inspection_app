import 'package:flutter/material.dart';
import '../models/verificateur.dart';
import '../models/mission.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../constants/app_theme.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Verificateur user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Mission> _missions = [];
  List<Mission> _filteredMissions = [];
  bool _isSyncing = false;
  String? _syncMessage;
  bool _showSidebar = false;
  
  // Variables pour la recherche et le filtre
  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  final List<String> _filterOptions = [
    'Tous',
    'Par nom client',
    'Par date d\'intervention',
    'Par date de création',
    'Par date de modification',
    'Par nature de mission',
    'Par activité client',
    'Par statut'
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalMissions();
  }

  void _loadLocalMissions() {
    setState(() {
      _missions = HiveService.getMissionsByMatricule(widget.user.matricule);
      _filteredMissions = _missions;
    });
  }

  // Méthode pour normaliser le statut (gérer les fautes de frappe)
  String _normalizeStatus(String status) {
    final lowerStatus = status.toLowerCase().trim();
    
    if (lowerStatus.contains('encour') || lowerStatus.contains('en cours')) {
      return 'En cours';
    } else if (lowerStatus.contains('termine') || lowerStatus.contains('terminé')) {
      return 'Terminé';
    } else if (lowerStatus.contains('attente')) {
      return 'En attente';
    } else {
      // Retourner le statut original avec première lettre en majuscule
      return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  // Méthode pour obtenir la couleur du badge selon le statut
  Color _getStatusColor(String status) {
    final normalizedStatus = _normalizeStatus(status);
    
    switch (normalizedStatus) {
      case 'En attente':
        return Colors.orange;
      case 'En cours':
        return Colors.blue;
      case 'Terminé':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Méthode pour appliquer les filtres et la recherche
  void _applyFiltersAndSearch() {
    List<Mission> filtered = _missions;

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((mission) {
        final query = _searchQuery.toLowerCase();
        return mission.nomClient.toLowerCase().contains(query) ||
            (mission.activiteClient?.toLowerCase().contains(query) ?? false) ||
            (mission.adresseClient?.toLowerCase().contains(query) ?? false) ||
            (mission.natureMission?.toLowerCase().contains(query) ?? false) ||
            mission.status.toLowerCase().contains(query);
      }).toList();
    }

    // Appliquer le filtre sélectionné
    switch (_selectedFilter) {
      case 'Par date de création':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Par date de modification':
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'Par date d\'intervention':
        filtered.sort((a, b) {
          if (a.dateIntervention == null && b.dateIntervention == null) return 0;
          if (a.dateIntervention == null) return 1;
          if (b.dateIntervention == null) return -1;
          return b.dateIntervention!.compareTo(a.dateIntervention!);
        });
        break;
      case 'Par nom client':
        filtered.sort((a, b) => a.nomClient.compareTo(b.nomClient));
        break;
      case 'Par nature de mission':
        filtered.sort((a, b) {
          if (a.natureMission == null && b.natureMission == null) return 0;
          if (a.natureMission == null) return 1;
          if (b.natureMission == null) return -1;
          return a.natureMission!.compareTo(b.natureMission!);
        });
        break;
      case 'Par activité client':
        filtered.sort((a, b) {
          if (a.activiteClient == null && b.activiteClient == null) return 0;
          if (a.activiteClient == null) return 1;
          if (b.activiteClient == null) return -1;
          return a.activiteClient!.compareTo(b.activiteClient!);
        });
        break;
      case 'Par statut':
        filtered.sort((a, b) => _normalizeStatus(a.status).compareTo(_normalizeStatus(b.status)));
        break;
      case 'Tous':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {
      _filteredMissions = filtered;
    });
  }

  // Afficher le dialogue de filtre
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Filtrer les missions', style: TextStyle(fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0),
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final option = _filterOptions[index];
              return RadioListTile<String>(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(option),
                value: option,
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.of(context).pop();
                  _applyFiltersAndSearch();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'Tous';
              });
              Navigator.of(context).pop();
              _applyFiltersAndSearch();
            },
            child: const Text('Réinitialiser'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Afficher le dialogue de recherche
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Rechercher une mission', style: TextStyle(fontSize: 14)),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'par nom, activité, adresse, statut...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            _applyFiltersAndSearch();
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                _applyFiltersAndSearch();
              },
              child: const Text('Effacer'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Afficher le dialogue de tri
    IconData _getSortOptionIcon(String option) {
    switch (option) {
      case 'Tous les statuts':
      case 'Toutes les périodes':
        return Icons.all_inclusive;
      case 'En attente':
        return Icons.pending_actions;
      case 'En cours':
        return Icons.play_arrow;
      case 'Terminé':
        return Icons.check_circle;
      case 'Aujourd\'hui':
        return Icons.today;
      case 'Cette semaine':
        return Icons.calendar_view_week;
      case 'Ce mois':
        return Icons.calendar_view_month;
      case 'Cette année':
        return Icons.event_note;
      case 'Période personnalisée':
        return Icons.date_range;
      default:
        return Icons.sort;
    }
  }

// Afficher le dialogue de tri
void _showSortDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('Trier les missions', style: TextStyle(fontSize: 18)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tri par statut
              _buildSortSection(
                title: 'Par statut',
                icon: Icons.flag_outlined,
                options: ['En attente', 'En cours', 'Terminé'],
                onSelected: (value) {
                  _filterByStatus(value);
                },
              ),
              const Divider(height: 24),
              
              // Tri par période
              _buildSortSection(
                title: 'Par période',
                icon: Icons.calendar_today_outlined,
                options: ['Aujourd\'hui', 'Cette semaine', 'Ce mois', 'Cette année', 'Période personnalisée'],
                onSelected: (value) {
                  _filterByPeriod(value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedFilter = 'Tous';
            });
            Navigator.of(context).pop();
            _applyFiltersAndSearch();
          },
          child: const Text('Réinitialiser'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

Widget _buildSortSection({
  required String title,
  required IconData icon,
  required List<String> options,
  required Function(String) onSelected,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      ...options.map((option) => RadioListTile<String>(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        dense: true,
        title: Text(option, style: const TextStyle(fontSize: 14)),
        value: option,
        groupValue: _selectedFilter.contains(option) ? option : null,
        onChanged: (value) {
          Navigator.of(context).pop();
          onSelected(value!);
        },
      )),
    ],
  );
}

void _filterByStatus(String status) {
  setState(() {
    _selectedFilter = 'Par statut: $status';
    _filteredMissions = _missions.where((mission) {
      return _normalizeStatus(mission.status) == status;
    }).toList();
  });
}

void _filterByPeriod(String period) {
  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (period) {
    case 'Aujourd\'hui':
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case 'Cette semaine':
      // Début de la semaine (lundi)
      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      break;
    case 'Ce mois':
      startDate = DateTime(now.year, now.month, 1);
      break;
    case 'Cette année':
      startDate = DateTime(now.year, 1, 1);
      break;
    case 'Période personnalisée':
      _showCustomDateRangeDialog();
      return;
    default:
      startDate = DateTime(now.year, now.month, now.day);
  }

  setState(() {
    _selectedFilter = 'Par période: $period';
    _filteredMissions = _missions.where((mission) {
      // Utiliser createdAt pour le filtrage
      final missionDate = mission.createdAt;
      return missionDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
             missionDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();
  });
}

void _showCustomDateRangeDialog() {
  DateTime? startDate;
  DateTime? endDate;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Période personnalisée', style: TextStyle(fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                  title: const Text('Date de début'),
                  subtitle: Text(
                    startDate != null ? _formatDate(startDate!) : 'Non sélectionnée',
                    style: TextStyle(
                      color: startDate != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (selectedDate != null) {
                      setDialogState(() {
                        startDate = selectedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                  title: const Text('Date de fin'),
                  subtitle: Text(
                    endDate != null ? _formatDate(endDate!) : 'Non sélectionnée',
                    style: TextStyle(
                      color: endDate != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (selectedDate != null) {
                      setDialogState(() {
                        endDate = selectedDate;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              onPressed: startDate != null && endDate != null
                  ? () {
                      if (startDate!.isAfter(endDate!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('La date de début doit être avant la date de fin'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop(); // Fermer le dialog personnalisé
                      _applyCustomDateRange(startDate!, endDate!);
                    }
                  : null,
              child: const Text('Appliquer'),
            ),
          ],
        );
      },
    ),
  );
}

void _applyCustomDateRange(DateTime startDate, DateTime endDate) {
  // S'assurer que la date de début commence à 00:00:00
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  // S'assurer que la date de fin termine à 23:59:59
  final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
  
  setState(() {
    _selectedFilter = 'Période: ${_formatDate(startDate)} - ${_formatDate(endDate)}';
    _filteredMissions = _missions.where((mission) {
      final missionDate = mission.createdAt;
      return missionDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
             missionDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  });
}
  Future<void> _syncMissions() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    try {
      final hasConnection = await SupabaseService.testConnection();

      if (!hasConnection) {
        setState(() {
          _syncMessage = 'Aucune connexion Internet';
          _isSyncing = false;
        });
        return;
      }

      print('Matricule utilisé pour sync: ${widget.user.matricule}');
      final onlineMissions = await SupabaseService.getMissionsByMatricule(widget.user.matricule);
      print('Missions récupérées en ligne: ${onlineMissions.length}');

      int newMissionsCount = 0;
      for (var mission in onlineMissions) {
        if (!HiveService.missionExists(mission.id)) {
          await HiveService.saveMission(mission);
          newMissionsCount++;
          print('Nouvelle mission ajoutée: ${mission.nomClient}');
        }
      }

      _loadLocalMissions();
      _applyFiltersAndSearch();

      setState(() {
        if (newMissionsCount > 0) {
          _syncMessage = '✓ $newMissionsCount nouvelle(s) mission(s) synchronisée(s)';
        } else {
          _syncMessage = '✓ Synchronisation terminée - ${onlineMissions.length} mission(s) disponibles';
        }
        _isSyncing = false;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _syncMessage = null;
          });
        }
      });
    } catch (e) {
      print('Erreur détaillée: $e');
      setState(() {
        _syncMessage = 'Erreur de synchronisation: $e';
        _isSyncing = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  // Widget pour le sidebar menu avec animation
  Widget _buildSidebarMenu() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: _showSidebar ? 0 : -280,
      top: 0,
      bottom: 0,
      width: 280,
      child: Material(
        elevation: 16,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header du sidebar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 45, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.user.nom,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Matricule: ${widget.user.matricule}',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.assignment_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_filteredMissions.length} mission(s)',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedFilter != 'Tous' || _searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _selectedFilter != 'Tous' ? 'Filtre: $_selectedFilter' : 'Recherche active',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Espace vide
              Expanded(child: Container()),
              
              // Bouton de déconnexion
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
      body: Stack(
        children: [
          // Contenu principal
          Column(
            children: [
              // AppBar personnalisé
              Container(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _showSidebar = !_showSidebar;
                          });
                        },
                        tooltip: 'Profil utilisateur',
                      ),
                      const SizedBox(
                        child: Text(
                          'Mes Missions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'filter') {
                            _showFilterDialog();
                          } else if (value == 'search') {
                            _showSearchDialog();
                          } else if (value == 'sort') {
                            _showSortDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'filter',
                            child: Row(
                              children: [
                                Icon(Icons.filter_list, color: AppTheme.primaryBlue),
                                SizedBox(width: 8),
                                Text('Filtrer'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'search',
                            child: Row(
                              children: [
                                Icon(Icons.search, color: AppTheme.primaryBlue),
                                SizedBox(width: 8),
                                Text('Rechercher'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'sort',
                            child: Row(
                              children: [
                                Icon(Icons.sort, color: AppTheme.primaryBlue),
                                SizedBox(width: 8),
                                Text('Trier'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Corps de l'application
              Expanded(
                child: Container(
                  color: Colors.grey.shade50,
                  child: Column(
                    children: [
                      // Message de synchronisation
                      if (_syncMessage != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _syncMessage!.startsWith('✓') ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _syncMessage!.startsWith('✓') ? Colors.green.shade200 : Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _syncMessage!.startsWith('✓') ? Icons.check_circle_outline : Icons.info_outline,
                                color: _syncMessage!.startsWith('✓') ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_syncMessage!, style: TextStyle(
                                color: _syncMessage!.startsWith('✓') ? Colors.green.shade700 : Colors.orange.shade700,
                              ))),
                            ],
                          ),
                        ),

                      // Indicateurs de filtre/recherche actifs
                      if (_selectedFilter != 'Tous' || _searchQuery.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedFilter != 'Tous' 
                                    ? 'Filtre: $_selectedFilter (${_filteredMissions.length} résultat(s))'
                                    : 'Recherche: "$_searchQuery" (${_filteredMissions.length} résultat(s))',
                                  style: TextStyle(fontSize: 14, color: AppTheme.darkBlue),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _selectedFilter = 'Tous';
                                    _searchQuery = '';
                                  });
                                  _applyFiltersAndSearch();
                                },
                              ),
                            ],
                          ),
                        ),

                      // Liste des missions
                      Expanded(
                        child: _filteredMissions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 80,
                                      color: AppTheme.greyDark.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _missions.isEmpty ? 'Aucune mission disponible' : 'Aucun résultat trouvé',
                                      style: TextStyle(fontSize: 16, color: AppTheme.greyDark),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _missions.isEmpty 
                                        ? 'Appuyez sur le bouton pour synchroniser'
                                        : 'Modifiez vos critères de recherche',
                                      style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredMissions.length,
                                itemBuilder: (context, index) {
                                  final mission = _filteredMissions[index];
                                  return _buildMissionCard(mission);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        // Floating Action Button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _isSyncing ? null : _syncMissions,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync),
            label: Text(_isSyncing ? 'Synchronisation...' : 'Synchroniser'),
          ),
        ),

          // Overlay flou quand le sidebar est ouvert
          if (_showSidebar)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showSidebar = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),

          // Sidebar menu
          _buildSidebarMenu(),
          
        ],
      ),
      
    );
  }

  Widget _buildMissionCard(Mission mission) {
    final normalizedStatus = _normalizeStatus(mission.status);
    final statusColor = _getStatusColor(mission.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mission: ${mission.nomClient} - Statut: $normalizedStatus'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (mission.logoClient != null)
                    Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: AppTheme.greyLight,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          mission.logoClient!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.business, color: AppTheme.primaryBlue);
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.nomClient,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (mission.activiteClient != null)
                          Text(
                            mission.activiteClient!,
                            style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Badge de statut
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  normalizedStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (mission.adresseClient != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppTheme.greyDark),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mission.adresseClient!,
                        style: TextStyle(fontSize: 13, color: AppTheme.greyDark),
                      ),
                    ),
                  ],
                ),
              ],
              if (mission.dateIntervention != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.greyDark),
                    const SizedBox(width: 4),
                    Text(
                      'Intervention: ${_formatDate(mission.dateIntervention!)}',
                      style: TextStyle(fontSize: 13, color: AppTheme.greyDark),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.greyDark),
                  const SizedBox(width: 4),
                  Text(
                    'Créé: ${_formatDate(mission.createdAt)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.greyDark),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.update, size: 14, color: AppTheme.greyDark),
                  const SizedBox(width: 4),
                  Text(
                    'Modifié: ${_formatDate(mission.updatedAt)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.greyDark),
                  ),
                ],
              ),
              if (mission.natureMission != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    mission.natureMission!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildLocalUsersSection() {
  final localUsers = HiveService.getAllUsers();
  
  if (localUsers.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: AppTheme.greyDark.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune mission disponible',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.greyDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur le bouton pour synchroniser',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Utilisateurs locaux (${localUsers.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkBlue,
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: localUsers.length,
          itemBuilder: (context, index) {
            final user = localUsers[index];
            return _buildUserCard(user);
          },
        ),
      ),
    ],
  );
}

// Widget pour afficher une carte utilisateur
Widget _buildUserCard(Verificateur user) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Matricule: ${user.matricule}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          // Badge pour l'utilisateur actuel
          if (user.matricule == widget.user.matricule)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Actuel',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}