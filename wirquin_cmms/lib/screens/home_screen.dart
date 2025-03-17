import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'maintenance_screen.dart';
import 'oee_dashboard_screen.dart';
import 'role_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static final List<Widget> _screens = [
    const OEEDashboardScreen(),
    const MaintenanceScreen(),
  ];

  static final List<String> _screenTitles = [
    'Dashboard',
    'Maintenance Management',
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 1000;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.water_drop, color: Colors.white),
            SizedBox(width: 10),
            Text(_screenTitles[_selectedIndex]),
          ],
        ),
        elevation: 2,
        actions: [
          // User role indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Chip(
                avatar: const Icon(
                  Icons.admin_panel_settings,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Color(0xFF6E0E0A), // Darker red
              ),
            ),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, userProvider),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Navigation Rail for larger screens, Drawer for mobile
          if (isLargeScreen) ...[
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              extended: true,
              minExtendedWidth: 200,
              labelType: NavigationRailLabelType.none,
              backgroundColor: Colors.white,
              selectedIconTheme: IconThemeData(
                color: theme.primaryColor,
              ),
              selectedLabelTextStyle: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Colors.grey[700],
              ),
              unselectedIconTheme: IconThemeData(
                color: Colors.grey[600],
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.water_drop),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.plumbing),
                  label: Text('Maintenance'),
                ),
              ],
            ),
            // Vertical divider
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
          ],
          // Main content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      // Only show drawer on smaller screens
      drawer: isLargeScreen
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      image: DecorationImage(
                        image: NetworkImage('https://www.wirquin.com/sites/default/files/styles/banniere_large/public/2020-08/header_wirquin_purity.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.red.withOpacity(0.7),
                          BlendMode.multiply,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wirquin CMMS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Sanitary Solutions Management',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.water_drop, color: Color(0xFFE32118)),
                    title: const Text('Dashboard', style: TextStyle(color: Color(0xFFE32118))),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      _onDestinationSelected(0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.plumbing, color: Color(0xFFE32118)),
                    title: const Text('Maintenance', style: TextStyle(color: Color(0xFFE32118))),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      _onDestinationSelected(1);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFE32118)),
                    title: const Text('Logout', style: TextStyle(color: Color(0xFFE32118))),
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context, userProvider);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              userProvider.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const RoleSelectionScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }
} 