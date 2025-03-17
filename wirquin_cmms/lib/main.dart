import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/checklist_provider.dart';
import 'providers/user_provider.dart';
import 'providers/oee_data_provider.dart';
import 'screens/home_screen.dart';
import 'screens/role_selection_screen.dart';
import 'models/maintenance_category.dart';
import 'models/checklist_item.dart';
import 'helpers/reset_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => EquipmentProvider()),
        ChangeNotifierProvider(create: (ctx) => ChecklistProvider()),
        ChangeNotifierProvider(create: (ctx) => UserProvider()),
        ChangeNotifierProvider(create: (ctx) => OEEDataProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (ctx, userProvider, _) {
          return MaterialApp(
            title: 'Wirquin CMMS',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.red,
              primaryColor: Color(0xFFE32118), // Wirquin red
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: Color(0xFFE32118),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardTheme: CardTheme(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textTheme: TextTheme(
                titleLarge: TextStyle(
                  color: Color(0xFFE32118),
                  fontWeight: FontWeight.bold,
                ),
                titleMedium: TextStyle(
                  color: Color(0xFFE32118),
                ),
                bodyLarge: TextStyle(
                  color: Color(0xFFE32118),
                ),
              ),
              useMaterial3: true,
            ),
            home: DevOptionsWrapper(child: _determineHomeScreen(userProvider)),
          );
        },
      ),
    );
  }

  Widget _determineHomeScreen(UserProvider userProvider) {
    if (!userProvider.isAuthenticated) {
      return const RoleSelectionScreen();
    }
    
    // For now, always return HomeScreen regardless of role
    return const HomeScreen();
  }
}

// A wrapper widget to add development options to any screen
class DevOptionsWrapper extends StatelessWidget {
  final Widget child;
  
  const DevOptionsWrapper({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show dialog to confirm reset
          final shouldReset = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Reset Application Data'),
              content: const Text(
                'This will delete all equipment, checklists, and categories. ' +
                'The app will reload with sample data. Continue?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reset Data'),
                ),
              ],
            ),
          ) ?? false;
          
          if (shouldReset) {
            // Get the equipment provider
            final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
            
            // Reset and reload the data
            await resetAndReload(equipmentProvider);
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data reset and reloaded with fresh sample data!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        tooltip: 'Reset App Data',
        backgroundColor: Colors.red,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
