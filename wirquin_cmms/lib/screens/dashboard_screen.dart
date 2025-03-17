import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../models/equipment.dart';
import '../helpers/reset_data.dart';
import 'equipment_detail_screen.dart';
import 'equipment_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  // Set up a refresh timer to periodically update the dashboard
  @override
  void initState() {
    super.initState();
    
    // Animation controller for card animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    
    // Force a provider refresh when dashboard is opened
    Future.delayed(Duration.zero, () {
      if (mounted) {
        final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
        equipmentProvider.reloadData();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {}); // Force UI update
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Refreshing dashboard...'),
                  backgroundColor: theme.colorScheme.secondary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              );
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'Refreshing data...',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
              
              // Reset application data
              final equipmentProvider = 
                Provider.of<EquipmentProvider>(context, listen: false);
              await equipmentProvider.reloadData();
              
              if (context.mounted) {
                // Close loading dialog
                Navigator.of(context).pop();
                
                // Force UI update
                setState(() {});
                _animationController.reset();
                _animationController.forward();
                
                // Show snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Dashboard refreshed'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            tooltip: 'Refresh Data',
          )
        ],
      ),
      body: Consumer<EquipmentProvider>(
        builder: (context, equipmentProvider, child) {
          final equipment = equipmentProvider.equipmentList;
          
          if (equipment.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No equipment available',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some equipment to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Count equipment by status using EXACT string comparison
          int operational = 0;
          int maintenance = 0;
          int outOfService = 0;
          int unknown = 0;
          
          // Log all equipment statuses in detail
          debugPrint('======== EQUIPMENT STATUS CHECK ========');
          debugPrint('Total equipment count: ${equipment.length}');
          
          for (var item in equipment) {
            final status = item.status;
            debugPrint('Equipment: ${item.name} | Raw Status: "$status"');
            
            // Exact string comparison
            if (status == "Operational") {
              operational++;
              debugPrint('→ Counted as: OPERATIONAL');
            } else if (status == "Maintenance") {
              maintenance++;
              debugPrint('→ Counted as: MAINTENANCE');
            } else if (status == "Out of Service") {
              outOfService++;
              debugPrint('→ Counted as: OUT OF SERVICE');
            } else {
              unknown++;
              debugPrint('→ Unknown status: $status');
            }
          }
          
          debugPrint('Final counts:');
          debugPrint('- Operational: $operational');
          debugPrint('- Maintenance: $maintenance');
          debugPrint('- Out of Service: $outOfService');
          debugPrint('- Unknown: $unknown');
          debugPrint('========================================');
          
          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () async {
              // Force update when pulled down
              setState(() {});
              _animationController.reset();
              _animationController.forward();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Dashboard refreshed'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Summary
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Equipment Overview',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FadeTransition(
                                opacity: _animationController,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatusSummary(
                                      'Operational',
                                      operational,
                                      const Color(0xFF43A047),
                                      Icons.check_circle_rounded,
                                    ),
                                    _buildStatusSummary(
                                      'Toilet Seat',
                                      outOfService,
                                      const Color(0xFFE53935),
                                      Icons.do_not_disturb_on_rounded,
                                    ),
                                    _buildStatusSummary(
                                      'Maintenance',
                                      maintenance,
                                      const Color(0xFFFB8C00),
                                      Icons.build_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Recently Updated Equipment
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Equipment Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EquipmentListScreen(),
                                ),
                              ).then((_) => setState(() {})); // Refresh after returning
                            },
                            icon: const Icon(Icons.view_list_rounded),
                            label: const Text('View All'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Equipment Grid
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 450, // Increased height
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9, // Slightly taller cards
                              ),
                              itemCount: equipment.length,
                              itemBuilder: (context, index) {
                                final delay = index * 0.2;
                                final slideAnimation = Tween<Offset>(
                                  begin: const Offset(0, 0.5),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      delay.clamp(0.0, 0.9),
                                      (delay + 0.4).clamp(0.0, 1.0),
                                      curve: Curves.easeOutQuart,
                                    ),
                                  ),
                                );
                                
                                return SlideTransition(
                                  position: slideAnimation,
                                  child: FadeTransition(
                                    opacity: _animationController,
                                    child: _buildEquipmentCard(equipment[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSummary(String status, int count, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    Color statusColor;
    IconData statusIcon;
    String displayStatus = equipment.status;
    
    // Use exact string matching for statuses
    final status = equipment.status;
    debugPrint('Card status: "$status"');
    
    switch (status) {
      case 'Operational':
        statusColor = const Color(0xFF43A047);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Maintenance':
        statusColor = const Color(0xFFFB8C00);
        statusIcon = Icons.engineering_rounded;
        break;
      case 'Out of Service':
        statusColor = const Color(0xFFE53935);
        statusIcon = Icons.do_not_disturb_on_rounded;
        displayStatus = 'Toilet Seat';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        debugPrint('Unknown status in card: $status');
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentDetailScreen(equipment: equipment),
            ),
          ).then((_) => setState(() {})); // Refresh after returning
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                statusColor.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      equipment.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.location_on_outlined, equipment.location),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today_outlined, equipment.lastMaintenanceDate),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      displayStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
} 