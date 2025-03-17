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
import 'data/machine_checklists.dart';

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
          // Show dialog to enter machine details
          final shouldCreate = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Create New Machine'),
              content: const Text(
                'This will create a new machine with all three checklist types (IM, BT, and TER).'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Create Machine'),
                ),
              ],
            ),
          ) ?? false;
          
          if (shouldCreate) {
            // Get the equipment provider
            final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
            
            // Create a new machine
            await createNewMachineWithChecklists(
              equipmentProvider,
              'Production Machine ${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 12)}',
              'Machine',
              'Production Floor'
            );
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New machine created with default checklists!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        tooltip: 'Create Machine',
        heroTag: 'createMachine',
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
