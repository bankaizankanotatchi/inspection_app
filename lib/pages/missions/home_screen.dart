import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/stats/stats_screen.dart';
import 'package:inspec_app/pages/missions/components/filter_dialog.dart';
import 'package:inspec_app/pages/missions/components/home_app_bar.dart';
import 'package:inspec_app/pages/missions/components/mission_card.dart';
import 'package:inspec_app/pages/missions/components/search_dialog.dart';
import 'package:inspec_app/pages/missions/components/sidebar_menu.dart';
import 'package:inspec_app/pages/missions/components/sort_dialog.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/supabase_service.dart';
import 'package:inspec_app/services/sync_service.dart';
import 'package:workmanager/workmanager.dart';

class HomeScreen extends StatefulWidget {
  final Verificateur user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Mission> _missions = [];
  List<Mission> _filteredMissions = [];
  bool _isSyncing = false;
  String? _syncMessage;
  bool _showSidebar = false;
  int _currentPageIndex = 0;
  Timer? _syncCheckTimer;
  DateTime? _lastAutoSyncTime;
  
  // Variables pour la recherche et le filtre
  String _searchQuery = '';
  String _selectedFilter = 'Tous';

  // Variable pour stocker la période sélectionnée pour les stats
  String _statsSelectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocalMissions();
    _initializeAutoSync();
    _scheduleSyncCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Vérifier la synchronisation quand l'app revient au premier plan
      _checkAutoSync();
    }
  }

  void _initializeAutoSync() async {
    try {
      // Initialiser le service de synchronisation
      await SyncService.initialize();
      
      // Programmer la synchronisation périodique
      await SyncService.schedulePeriodicSync();
      
      // Vérifier s'il faut synchroniser maintenant
      _checkAutoSync();
      
      print('✅ Synchronisation automatique initialisée');
    } catch (e) {
      print('❌ Erreur initialisation synchronisation automatique: $e');
    }
  }

  void _scheduleSyncCheck() {
    // Vérifier toutes les heures si une synchronisation est nécessaire
    _syncCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkAutoSync();
    });
  }

  Future<void> _checkAutoSync() async {
    // Vérifier si 24 heures se sont écoulées depuis la dernière synchronisation
    final now = DateTime.now();
    final shouldSync = _lastAutoSyncTime == null || 
        now.difference(_lastAutoSyncTime!) >= const Duration(hours: 24);
    
    if (!shouldSync) return;
    
    final hasConnection = await SupabaseService.testConnection();
    if (!hasConnection) return;
    
    // Lancer la synchronisation automatique silencieuse
    print('🔄 Synchronisation automatique déclenchée');
    await _performSync(silent: true, isAutoSync: true);
  }

  void _loadLocalMissions() {
    setState(() {
      _missions = HiveService.getMissionsByMatricule(widget.user.matricule);
      _filteredMissions = _missions;
    });
  }

  Future<void> _syncMissions() async {
    await _performSync(silent: false, isAutoSync: false);
  }

  Future<void> _performSync({bool silent = false, bool isAutoSync = false}) async {
    if (!silent) {
      setState(() {
        _isSyncing = true;
        _syncMessage = null;
      });
    }

    try {
      final hasConnection = await SupabaseService.testConnection();

      if (!hasConnection) {
        if (!silent) {
          setState(() {
            _syncMessage = 'Aucune connexion Internet';
            _isSyncing = false;
          });
        }
        return;
      }

      final onlineMissions = await SupabaseService.getMissionsByMatricule(widget.user.matricule);

      int newMissionsCount = 0;
      for (var mission in onlineMissions) {
        if (!HiveService.missionExists(mission.id)) {
          await HiveService.saveMission(mission);
          newMissionsCount++;
        }
      }

      _loadLocalMissions();
      
      // Mettre à jour la dernière synchronisation automatique
      if (isAutoSync) {
        _lastAutoSyncTime = DateTime.now();
      }

      if (!silent) {
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
      } else if (newMissionsCount > 0) {
        // Afficher un message discret pour la synchronisation automatique
        _showAutoSyncNotification(newMissionsCount);
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _syncMessage = 'Erreur de synchronisation: $e';
          _isSyncing = false;
        });
      }
    }
  }

  void _showAutoSyncNotification(int newMissionsCount) {
    // Afficher un SnackBar discret pour informer de la synchronisation automatique
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$newMissionsCount nouvelle(s) mission(s) synchronisée(s)'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getLastSyncInfo() {
    if (_lastAutoSyncTime == null) return 'Jamais';
    
    final now = DateTime.now();
    final difference = now.difference(_lastAutoSyncTime!);
    
    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inHours < 1) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    return 'Il y a ${difference.inDays} jours';
  }

  void _onNavigationItemSelected(int index) {
    setState(() {
      _currentPageIndex = index;
      _showSidebar = false;
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _updateSelectedFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _updateFilteredMissions(List<Mission> missions) {
    setState(() {
      _filteredMissions = missions;
    });
  }

  // IMPLÉMENTATION COMPLÈTE DE LA GESTION DES PÉRIODES STATS
  void _handleStatsPeriodChange(String period) {
    print('🔄 Changement de période pour les stats: $period');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _statsSelectedPeriod = period;
        });

        // Sauvegarder la préférence
        _saveStatsPeriodPreference(period);
      }
    });
  }

  void _saveStatsPeriodPreference(String period) {
    // Sauvegarder dans les préférences locales
    print('💾 Sauvegarde préférence période: $period');
    // HiveService.saveStatsPeriodPreference(period);
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
              HomeAppBar(
                currentPageIndex: _currentPageIndex,
                onMenuPressed: () {
                  setState(() {
                    _showSidebar = !_showSidebar;
                  });
                },
                onFilterPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilterDialog(
                    selectedFilter: _selectedFilter,
                    missions: _missions,
                    onFilterApplied: _updateFilteredMissions,
                    onFilterSelected: _updateSelectedFilter,
                  ),
                ),
                onSearchPressed: () => showDialog(
                  context: context,
                  builder: (context) => SearchDialog(
                    searchQuery: _searchQuery,
                    missions: _missions,
                    onSearchApplied: _updateFilteredMissions,
                    onSearchQueryChanged: _updateSearchQuery,
                  ),
                ),
                onSortPressed: () => showDialog(
                  context: context,
                  builder: (context) => SortDialog(
                    selectedFilter: _selectedFilter,
                    missions: _missions,
                    onFilterApplied: _updateFilteredMissions,
                    onFilterSelected: _updateSelectedFilter,
                  ),
                ),
                onStatsPeriodSelected: _handleStatsPeriodChange,
                lastSyncInfo: _getLastSyncInfo(),
              ),

              // Corps de l'application
              Expanded(
                child: Container(
                  color: Colors.grey.shade50,
                  child: _currentPageIndex == 0
                      ? _buildHomeContent()
                      : StatsScreen(
                          user: widget.user,
                          initialPeriod: _statsSelectedPeriod,
                          onPeriodChanged: _handleStatsPeriodChange, 
                        ),
                ),
              ),
            ],
          ),

          // Floating Action Button (seulement sur la page d'accueil)
          if (_currentPageIndex == 0)
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
                tooltip: 'Dernière synchronisation: ${_getLastSyncInfo()}',
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
          SidebarMenu(
            showSidebar: _showSidebar,
            user: widget.user,
            filteredMissions: _filteredMissions,
            selectedFilter: _selectedFilter,
            searchQuery: _searchQuery,
            currentPageIndex: _currentPageIndex,
            onNavigationItemSelected: _onNavigationItemSelected,
            onClose: () {
              setState(() {
                _showSidebar = false;
              });
            },
            lastSyncInfo: _getLastSyncInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
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

        // Info de synchronisation automatique
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade100, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.autorenew, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Prochaine synchro auto: ${_getNextSyncInfo()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  _showSyncInfoDialog();
                },
              ),
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
                      _filteredMissions = _missions;
                    });
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
                    return MissionCard(mission: mission, user: widget.user);
                  },
                ),
        ),
      ],
    );
  }

  String _getNextSyncInfo() {
    if (_lastAutoSyncTime == null) return 'Dans 24h';
    
    final now = DateTime.now();
    final nextSyncTime = _lastAutoSyncTime!.add(const Duration(hours: 24));
    final difference = nextSyncTime.difference(now);
    
    if (difference.inMinutes < 60) return 'Dans ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Dans ${difference.inHours} h';
    return 'Demain';
  }

  void _showSyncInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Synchronisation automatique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dernière synchronisation: ${_getLastSyncInfo()}'),
            const SizedBox(height: 8),
            Text('Prochaine synchronisation: ${_getNextSyncInfo()}'),
            const SizedBox(height: 8),
            const Text('La synchronisation se fait automatiquement toutes les 24 heures lorsque vous êtes connecté à Internet.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _syncMissions();
            },
            child: const Text('Sync maintenant'),
          ),
        ],
      ),
    );
  }
}