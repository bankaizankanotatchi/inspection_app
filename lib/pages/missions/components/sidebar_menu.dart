import 'package:flutter/material.dart';
import '../../../models/verificateur.dart';
import '../../../models/mission.dart';
import '../../../services/hive_service.dart';
import '../../../constants/app_theme.dart';
import '../../login_screen.dart';

class SidebarMenu extends StatelessWidget {
  final bool showSidebar;
  final Verificateur user;
  final List<Mission> filteredMissions;
  final String selectedFilter;
  final String searchQuery;
  final int currentPageIndex;
  final Function(int) onNavigationItemSelected;
  final VoidCallback onClose;
  final String lastSyncInfo; // NOUVEAU : Info de dernière synchronisation

  const SidebarMenu({
    super.key,
    required this.showSidebar,
    required this.user,
    required this.filteredMissions,
    required this.selectedFilter,
    required this.searchQuery,
    required this.currentPageIndex,
    required this.onNavigationItemSelected,
    required this.onClose,
    required this.lastSyncInfo, // Requis maintenant
  });

  Future<void> _logout(BuildContext context) async {
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
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: showSidebar ? 0 : -280,
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
                      child: Icon(
                        Icons.person,
                        size: 45,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Matricule: ${user.matricule}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    
                    
                    // Indicateurs de filtre/recherche
                    if (selectedFilter != 'Tous' || searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selectedFilter != 'Tous'
                              ? 'Filtre: $selectedFilter'
                              : 'Recherche active',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    
                    // Info missions
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${filteredMissions.length} mission(s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation items
              const SizedBox(height: 20),
              _buildNavigationItem(
                icon: Icons.home_outlined,
                title: 'Accueil',
                isSelected: currentPageIndex == 0,
                onTap: () => onNavigationItemSelected(0),
              ),
              _buildNavigationItem(
                icon: Icons.bar_chart_outlined,
                title: 'Statistiques',
                isSelected: currentPageIndex == 1,
                onTap: () => onNavigationItemSelected(1),
              ),

              // Section info synchronisation
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.lightBlue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.autorenew, size: 16, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          const Text(
                            'Synchronisation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La synchronisation se fait automatiquement toutes les 24 heures.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dernière: $lastSyncInfo',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Espace vide
              Expanded(child: Container()),

              // Bouton de déconnexion
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
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

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryBlue)
          : null,
      onTap: onTap,
    );
  }
}