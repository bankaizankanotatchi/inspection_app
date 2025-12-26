import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onSortPressed;
  final int currentPageIndex;
  final Function(String)? onStatsPeriodSelected; // Callback pour les stats
  final String lastSyncInfo; // NOUVEAU : Info de dernière synchronisation

  const HomeAppBar({
    super.key,
    required this.onMenuPressed,
    required this.onFilterPressed,
    required this.onSearchPressed,
    required this.onSortPressed,
    required this.currentPageIndex,
    this.onStatsPeriodSelected,
    required this.lastSyncInfo, // Requis maintenant
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _getAppBarTitle() {
    switch (currentPageIndex) {
      case 0:
        return 'Mes Missions';
      case 1:
        return 'Statistiques';
      default:
        return 'Mes Missions';
    }
  }

  bool _shouldShowActionButtons() {
    return currentPageIndex == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Menu button
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: onMenuPressed,
              tooltip: 'Menu',
            ),
            
            // Title
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getAppBarTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Info de synchronisation (seulement sur la page d'accueil)
                  if (currentPageIndex == 0 && lastSyncInfo.isNotEmpty)
                    Text(
                      'Dernière sync: $lastSyncInfo',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons
            _shouldShowActionButtons()
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'filter') {
                        onFilterPressed();
                      } else if (value == 'search') {
                        onSearchPressed();
                      } else if (value == 'sort') {
                        onSortPressed();
                      } else if (value == 'sync_info') {
                        _showSyncInfo(context);
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
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'sync_info',
                        child: Row(
                          children: [
                            Icon(Icons.sync, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Info sync: $lastSyncInfo'),
                          ],
                        ),
                      ),
                    ],
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      // Transmettre la sélection via le callback
                      onStatsPeriodSelected?.call(value);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'today',
                        child: Row(
                          children: [
                            Icon(Icons.today, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Aujourd\'hui'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'week',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_view_week, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Cette semaine'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'month',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_view_month, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Ce mois'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'year',
                        child: Row(
                          children: [
                            Icon(Icons.event_note, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Cette année'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'custom',
                        child: Row(
                          children: [
                            Icon(Icons.date_range, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Période personnalisée'),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  void _showSyncInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Information synchronisation'),
        content: Text('Dernière synchronisation: $lastSyncInfo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}