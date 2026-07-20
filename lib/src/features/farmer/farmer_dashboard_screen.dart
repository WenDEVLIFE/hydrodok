import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/repositories/issue_report_repository.dart';
import '../../core/repositories/nutrient_task_repository.dart';
import '../../core/service/product_service.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import 'add_product_dialog.dart';
import 'batch_pooling_screen.dart';
import 'farm_listing_screen.dart';
import 'farm_settings_screen.dart';
import 'farmer_orders_screen.dart';
import 'farmer_requests_screen.dart';
import 'issue_reports_screen.dart';
import '../onboarding/farm_map_picker_dialog.dart';
import '../user/forum/forum_screen.dart';
import '../user/map/map_screen.dart';
import '../user/pooling/pooling_screen.dart';
import '../user/profile/profile_screen.dart';

/// Central Dashboard for Hydroponic Farmers
///
/// Farm overview with real-time metrics, quick actions, and
/// today's maintenance schedule. Light theme consistent with
/// the rest of the app (Pooling, Forum, etc.).
class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _currentTabIndex = 0;

  late final NutrientTaskRepository _nutrientTaskRepo;
  late final IssueReportRepository _issueReportRepo;

  // ── Realtime streams ─────────────────────────────────────────────────────
  late final Stream<List<Map<String, dynamic>>> _farmStream;
  late final Stream<List<Map<String, dynamic>>> _productsStream;
  late final Stream<List<Map<String, dynamic>>> _ordersStream;
  late final Stream<List<Map<String, dynamic>>> _issueReportsStream;

  // ── Products, Orders, Tasks & Nutrient Logs ─────────────────────────────
  List<Map<String, dynamic>> _myProducts = [];
  List<Map<String, dynamic>> _myOrders = [];
  List<Map<String, dynamic>> _myTasks = [];
  List<Map<String, dynamic>> _myNutrientLogs = [];
  // ── Initial Farm State ──────────────────────────────────────────────────
  Map<String, dynamic>? _initialFarm;

  @override
  void initState() {
    super.initState();
    _nutrientTaskRepo = SupabaseNutrientTaskRepository();
    _issueReportRepo = IssueReportRepository();
    _initStream();
    _loadInitialFarmAndData();
    _loadProductsAndOrders();
  }

  Future<void> _loadInitialFarmAndData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await Supabase.instance.client
          .from('farms')
          .select('*')
          .eq('owner_id', user.id)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _initialFarm = res;
        });
        final farmId = res['id'] as String?;
        if (farmId != null) {
          _loadTasksAndLogs(farmId);
        }
      }
    } catch (e) {
      debugPrint('Error loading initial farm REST: $e');
    }
  }

  void _initStream() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final client = Supabase.instance.client;

    _farmStream = client
        .from('farms')
        .stream(primaryKey: ['id'])
        .eq('owner_id', user.id);

    _productsStream = client
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    _ordersStream = client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    _issueReportsStream = _issueReportRepo.watchIssueReports();
  }

  Future<void> _loadProductsAndOrders() async {
    try {
      final service = ProductService(supabase: Supabase.instance.client);

      final products = await service.getMyProducts();
      final orders = await service.getMyOrders();

      if (mounted) {
        setState(() {
          _myProducts = products;
          _myOrders = orders;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadTasksAndLogs(String farmId) async {
    try {
      final tasks = await _nutrientTaskRepo.getFarmTasks(farmId);
      final logs = await _nutrientTaskRepo.getNutrientLogs(farmId);

      if (mounted) {
        setState(() {
          _myTasks = tasks;
          _myNutrientLogs = logs;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTabIndex != 0) {
      return Theme(
        data: _lightTheme,
        child: Scaffold(
          body: IndexedStack(
            index: _currentTabIndex - 1,
            children: const [
              MapScreen(),
              ForumScreen(),
              PoolingScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      );
    }

    return Theme(
      data: _lightTheme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: ColorUtils.forestGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.sprout,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farmer Dashboard',
                    style: AppTypography.heading3(
                      color: ColorUtils.darkText,
                      fontSize: 18,
                    ),
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _farmStream,
                    builder: (context, snapshot) {
                      final farm = snapshot.data?.isNotEmpty == true
                          ? snapshot.data!.first
                          : null;
                      return Text(
                        farm?['farm_name'] as String? ?? 'Loading...',
                        style: AppTypography.bodySmall(color: Colors.grey.shade600),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.bell, color: ColorUtils.darkText),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new alerts')),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _farmStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _initialFarm == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final farm = (snapshot.data?.isNotEmpty == true
                ? snapshot.data!.first
                : null) ?? _initialFarm;
            final farmName = farm?['farm_name'] as String? ?? 'No Farm Registered';
            final farmAddress = farm?['address'] as String? ?? '';
            final verificationStatus = farm?['verification_status'] as String? ?? 'unverified';
            final types = farm?['produce_types'];
            final produceTypes = types is List ? types.cast<String>() : <String>[];

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadProductsAndOrders();
                  setState(() {});
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Farm Status & Verification Card ──────────────────────
                      _buildFarmStatusCard(
                        farmName: farmName,
                        farmAddress: farmAddress,
                        verificationStatus: verificationStatus,
                      ),
                      const SizedBox(height: 20),

                      // ── Key Farm Metrics Grid ─────────────────────────────────
                      Text(
                        'Farm Overview',
                        style: AppTypography.heading3(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildMetricCard(
                            title: 'Active Batches',
                            value: '${produceTypes.length} Crops',
                            subtitle: produceTypes.isNotEmpty
                                ? produceTypes.join(', ')
                                : 'No crops registered',
                            icon: LucideIcons.leaf,
                            color: ColorUtils.forestGreen,
                          ),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: (farm?['id'] as String?) != null
                                ? _nutrientTaskRepo.watchFarmTasks(farm!['id'] as String)
                                : null,
                            builder: (context, taskSnap) {
                              final tasks = (taskSnap.hasData && taskSnap.data!.isNotEmpty)
                                  ? taskSnap.data!
                                  : _myTasks;
                              final pendingCount = tasks.where((t) => t['status'] != 'completed').length;
                              final completedCount = tasks.where((t) => t['status'] == 'completed').length;
                              final val = tasks.isEmpty
                                  ? '0 Tasks'
                                  : '$pendingCount Pending';
                              final sub = tasks.isEmpty
                                  ? 'Tap to add maintenance task'
                                  : '$completedCount of ${tasks.length} completed';

                              return GestureDetector(
                                onTap: () {
                                  final farmId = farm?['id'] as String?;
                                  if (farmId != null) _showAddTaskDialog(farmId);
                                },
                                child: _buildMetricCard(
                                  title: 'Tasks',
                                  value: val,
                                  subtitle: sub,
                                  icon: LucideIcons.checkSquare,
                                  color: ColorUtils.terracotta,
                                ),
                              );
                            },
                          ),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _issueReportsStream,
                            builder: (context, issueSnap) {
                              final allIssues = issueSnap.data ?? [];
                              final farmId = farm?['id'] as String?;
                              final user = Supabase.instance.client.auth.currentUser;

                              final myIssues = allIssues.where((i) {
                                final isMyFarm = farmId != null && i['farm_id'] == farmId;
                                final isMyReport = user != null && i['reporter_id'] == user.id;
                                final status = (i['status'] as String? ?? '').toLowerCase();
                                return (isMyFarm || isMyReport) && status != 'resolved';
                              }).toList();

                              final activeCount = myIssues.length;
                              final val = '$activeCount Active';
                              final sub = activeCount == 0
                                  ? 'All systems operational'
                                  : '$activeCount unresolved issue report${activeCount > 1 ? 's' : ''}';
                              final color = activeCount == 0
                                  ? const Color(0xFF81C784)
                                  : ColorUtils.terracotta;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const IssueReportsScreen()),
                                  );
                                },
                                child: _buildMetricCard(
                                  title: 'Issue Alerts',
                                  value: val,
                                  subtitle: sub,
                                  icon: activeCount == 0 ? LucideIcons.shieldCheck : LucideIcons.alertTriangle,
                                  color: color,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Quick Actions ────────────────────────────────────────
                      Text(
                        'Quick Actions',
                        style: AppTypography.heading3(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickActionButton(
                            label: 'Log Nutrients',
                            icon: LucideIcons.droplets,
                            onTap: () {
                              final farmId = farm?['id'] as String?;
                              if (farmId != null && farmId.isNotEmpty) {
                                _showLogNutrientsDialog(farmId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please complete farm onboarding first.')),
                                );
                              }
                            },
                          ),
                          _buildQuickActionButton(
                            label: 'Add Task',
                            icon: LucideIcons.calendarPlus,
                            onTap: () {
                              final farmId = farm?['id'] as String?;
                              if (farmId != null && farmId.isNotEmpty) {
                                _showAddTaskDialog(farmId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please complete farm onboarding first.')),
                                );
                              }
                            },
                          ),
                          _buildQuickActionButton(
                            label: 'Report Issue',
                            icon: LucideIcons.alertTriangle,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const IssueReportsScreen()),
                              );
                            },
                          ),
                          _buildQuickActionButton(
                            label: 'Farm Map',
                            icon: LucideIcons.mapPin,
                            onTap: () {
                              setState(() => _currentTabIndex = 1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Set Farm Location Button ──────────────────────────────
                     SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(LucideIcons.mapPin, size: 18),
                          label: const Text('Set Farm Location on Map'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorUtils.forestGreen,
                            side: const BorderSide(color: ColorUtils.forestGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tasks',
                            style: AppTypography.heading3(
                              color: ColorUtils.darkText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              final farmId = farm?['id'] as String?;
                              if (farmId != null) _showAddTaskDialog(farmId);
                            },
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Add Task'),
                            style: TextButton.styleFrom(
                              foregroundColor: ColorUtils.forestGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: (farm?['id'] as String?) != null
                            ? _nutrientTaskRepo.watchFarmTasks(farm!['id'] as String)
                            : null,
                        builder: (context, taskSnapshot) {
                          final tasksList = (taskSnapshot.hasData && taskSnapshot.data!.isNotEmpty)
                              ? taskSnapshot.data!
                              : _myTasks;
                          if (tasksList.isEmpty) {
                            return _buildEmptyState('No maintenance tasks scheduled. Tap "Add Task" to create one.');
                          }

                          return Column(
                            children: tasksList.map((t) {
                              final taskId = t['id'] as String;
                              final farmId = farm?['id'] as String?;
                              final title = t['title'] as String? ?? 'Task';
                              final desc = t['description'] as String? ?? '';
                              final isCompleted = t['status'] == 'completed';
                              final priority = t['priority'] as String? ?? 'medium';

                              return _buildScheduleTile(
                                time: '',
                                title: title,
                                subtitle: desc,
                                isDone: isCompleted,
                                priority: priority,
                                onToggle: () async {
                                  final nextStatus = isCompleted ? 'pending' : 'completed';
                                  await _nutrientTaskRepo.updateTaskStatus(taskId, nextStatus);
                                  if (farmId != null) _loadTasksAndLogs(farmId);
                                },
                                onDelete: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Task'),
                                      content: Text('Are you sure you want to delete "$title"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _nutrientTaskRepo.deleteTask(taskId);
                                    if (farmId != null) _loadTasksAndLogs(farmId);
                                  }
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Nutrient Logs ─────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nutrient Logs',
                            style: AppTypography.heading3(
                              color: ColorUtils.darkText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              final farmId = farm?['id'] as String?;
                              if (farmId != null) _showLogNutrientsDialog(farmId);
                            },
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Log Nutrient'),
                            style: TextButton.styleFrom(
                              foregroundColor: ColorUtils.forestGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: (farm?['id'] as String?) != null
                            ? _nutrientTaskRepo.watchNutrientLogs(farm!['id'] as String)
                            : null,
                        builder: (context, logsSnapshot) {
                          final logsList = logsSnapshot.data ?? _myNutrientLogs;
                          if (logsList.isEmpty) {
                            return _buildEmptyState('No nutrient logs recorded yet. Tap "Log Nutrient" to record one.');
                          }

                          return Column(
                            children: logsList.map((log) {
                              final nutrientName = log['nutrient_name'] as String? ?? 'Nutrient';
                              final amount = (log['amount'] as num?)?.toDouble() ?? 0;
                              final notes = log['notes'] as String? ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: ColorUtils.forestGreen.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.droplets, color: ColorUtils.forestGreen, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nutrientName,
                                            style: AppTypography.bodyMedium(
                                              color: ColorUtils.darkText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (notes.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              notes,
                                              style: AppTypography.bodySmall(color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: ColorUtils.forestGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${amount % 1 == 0 ? amount.toInt() : amount} g/ml',
                                        style: AppTypography.bodySmall(
                                          color: ColorUtils.forestGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── My Products ──────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Products',
                            style: AppTypography.heading3(
                              color: ColorUtils.darkText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddProductDialog(),
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Add'),
                            style: TextButton.styleFrom(
                              foregroundColor: ColorUtils.forestGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _productsStream,
                        builder: (context, prodSnapshot) {
                          final user = Supabase.instance.client.auth.currentUser;
                          final farmId = farm?['id'] as String?;

                          final rawStream = prodSnapshot.data ?? [];
                          final filtered = rawStream.where((p) {
                            if (user != null && p['farmer_id'] == user.id) return true;
                            if (farmId != null && p['farm_id'] == farmId) return true;
                            return false;
                          }).toList();

                          final productsList = filtered.isNotEmpty
                              ? filtered
                              : (rawStream.isNotEmpty ? rawStream : _myProducts);

                          if (productsList.isEmpty) {
                            return _buildEmptyState('No products yet. Tap "Add" to create one.');
                          }

                          return Column(
                            children: productsList.map((p) => _buildProductCard(p)).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Incoming Orders ─────────────────────────────────────
                      Text(
                        'Incoming Orders',
                        style: AppTypography.heading3(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _ordersStream,
                        builder: (context, orderSnapshot) {
                          final user = Supabase.instance.client.auth.currentUser;
                          final rawStream = orderSnapshot.data ?? [];
                          final filtered = rawStream.where((o) {
                            if (user != null && o['farmer_id'] == user.id) return true;
                            return false;
                          }).toList();

                          final ordersList = filtered.isNotEmpty
                              ? filtered
                              : (rawStream.isNotEmpty ? rawStream : _myOrders);

                          if (ordersList.isEmpty) {
                            return _buildEmptyState('No orders yet.');
                          }

                          return Column(
                            children: ordersList.map((o) => _buildOrderCard(o)).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────

  ThemeData get _lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: ColorUtils.offWhite,
        colorScheme: ColorUtils.lightColorScheme,
        useMaterial3: true,
      );

  // ── Map Location Picker ────────────────────────────────────────────────

  Future<void> _openMapPicker() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final result = await Navigator.of(context).push<MapLocationResult>(
      MaterialPageRoute(
        builder: (_) => const FarmMapPickerDialog(),
      ),
    );

    if (result == null) return;

    // Save coordinates to the farm
    try {
      await Supabase.instance.client.from('farms').update({
        'latitude': result.latLng.latitude,
        'longitude': result.latLng.longitude,
        'address': result.address,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('owner_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm location updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save location: $e')),
        );
      }
    }
  }

  // ── Log Nutrients Dialog ──────────────────────────────────────────────────

  void _showLogNutrientsDialog(String farmId) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.droplets, color: ColorUtils.forestGreen),
            SizedBox(width: 8),
            Text('Log Hydroponic Nutrient'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nutrient Name',
                  hintText: 'e.g. Masterblend 4-18-38, pH Down',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (g or ml)',
                  hintText: 'e.g. 50.0',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. Added during reservoir top-up',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
            onPressed: () async {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (name.isEmpty) return;

              try {
                await _nutrientTaskRepo.logNutrient(
                  farmId: farmId,
                  nutrientName: name,
                  amount: amount,
                  notes: notesController.text.trim(),
                );
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nutrient log recorded!'),
                      backgroundColor: ColorUtils.forestGreen,
                    ),
                  );
                  _loadTasksAndLogs(farmId);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging nutrient: $e')),
                  );
                }
              }
            },
            child: const Text('Save Log', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Add Task Dialog ───────────────────────────────────────────────────────

  void _showAddTaskDialog(String farmId) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(LucideIcons.calendarPlus, color: ColorUtils.forestGreen),
              SizedBox(width: 8),
              Text('Add Maintenance Task'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'e.g. Reservoir pH & EC Test',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description / Instructions',
                    hintText: 'e.g. Check water quality and clean filter',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
                    DropdownMenuItem(value: 'high', child: Text('High Priority')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedPriority = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                try {
                  await _nutrientTaskRepo.addTask(
                    farmId: farmId,
                    title: title,
                    description: descController.text.trim(),
                    dueDate: DateTime.now(),
                    priority: selectedPriority,
                  );
                  if (mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task added to schedule!'),
                        backgroundColor: ColorUtils.forestGreen,
                      ),
                    );
                    _loadTasksAndLogs(farmId);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding task: $e')),
                    );
                  }
                }
              },
              child: const Text('Add Task', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Product Dialog ────────────────────────────────────────────────

  void _showAddProductDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductDialog(
        onProductAdded: _loadProductsAndOrders,
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        message,
        style: AppTypography.bodyMedium(color: Colors.grey.shade500),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Product Card ──────────────────────────────────────────────────────

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] as String? ?? '';
    final price = (product['price_per_kg'] as num?)?.toDouble() ?? 0;
    final unit = product['unit'] as String? ?? 'kg';
    final stock = product['stock_quantity'] as int? ?? 0;
    final status = product['status'] as String? ?? 'pending';

    final (String statusLabel, Color statusColor) = switch (status) {
      'approved' => ('Approved', ColorUtils.sageGreen),
      'rejected' => ('Rejected', Colors.red),
      _ => ('Pending', ColorUtils.terracotta),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorUtils.forestGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.leaf, color: ColorUtils.forestGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyMedium(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PHP ${price.toStringAsFixed(0)} / $unit  •  $stock in stock',
                  style: AppTypography.bodySmall(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: AppTypography.bodySmall(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Order Card ────────────────────────────────────────────────────────

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final totalPrice = (order['total'] as num?)?.toDouble() ??
        (order['total_price'] as num?)?.toDouble() ?? 0;
    final createdAt = order['created_at'] as String? ?? '';
    final product = order['products'] as Map<String, dynamic>?;
    final productName = product?['name'] as String? ?? 'Unknown Product';

    // Legacy single-product orders have quantity on the order row;
    // normalized orders store items in order_items.
    int quantity = order['quantity'] as int? ?? 0;
    if (quantity == 0) {
      final items = List<Map<String, dynamic>>.from(order['order_items'] as List<dynamic>? ?? []);
      quantity = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0));
    }

    final (String statusLabel, Color statusColor) = switch (status) {
      'confirmed' => ('Confirmed', ColorUtils.sageGreen),
      'delivered' => ('Delivered', const Color(0xFF64B5F6)),
      'cancelled' => ('Cancelled', Colors.red),
      _ => ('Pending', ColorUtils.terracotta),
    };

    // Format date
    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = '${dt.month}/${dt.day}/${dt.year}';
      } catch (_) {
        dateStr = createdAt.substring(0, 10);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorUtils.terracotta.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.shoppingBag, color: ColorUtils.terracotta, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: AppTypography.bodyMedium(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: $quantity  •  PHP ${totalPrice.toStringAsFixed(0)}  •  $dateStr',
                  style: AppTypography.bodySmall(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: AppTypography.bodySmall(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Farm Status Card ────────────────────────────────────────────────────

  Widget _buildFarmStatusCard({
    required String farmName,
    required String farmAddress,
    required String verificationStatus,
  }) {
    // Determine status badge based on verification_status
    final (String statusLabel, Color statusColor, IconData statusIcon) =
        switch (verificationStatus) {
      'verified' => ('Verified', ColorUtils.sageGreen, LucideIcons.badgeCheck),
      'pending' => ('Pending', ColorUtils.terracotta, LucideIcons.clock),
      'rejected' => ('Rejected', Colors.red, LucideIcons.xCircle),
      _ => ('Unverified', Colors.grey, LucideIcons.badgeAlert),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ColorUtils.mainGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  farmName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2(
                    color: ColorUtils.pureWhite,
                    fontSize: 20,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: AppTypography.bodySmall(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (farmAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    farmAddress,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                verificationStatus == 'verified'
                    ? 'System Status: Optimal'
                    : 'Verification: $statusLabel',
                style: AppTypography.bodyMedium(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Last synced just now',
                style: AppTypography.bodySmall(color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Metric Card ─────────────────────────────────────────────────────────

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall(color: Colors.grey.shade600),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.heading3(
                  color: ColorUtils.darkText,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Action Button ─────────────────────────────────────────────────

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: ColorUtils.forestGreen.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: ColorUtils.forestGreen, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.bodySmall(
              color: ColorUtils.darkText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Maintenance Schedule Tile ───────────────────────────────────────────

  Widget _buildScheduleTile({
    required String time,
    required String title,
    required String subtitle,
    required bool isDone,
    VoidCallback? onToggle,
    VoidCallback? onDelete,
    String? priority,
  }) {
    Color priorityColor = Colors.grey;
    if (priority == 'high') priorityColor = Colors.red;
    if (priority == 'medium') priorityColor = Colors.orange;
    if (priority == 'low') priorityColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? ColorUtils.sageGreen.withValues(alpha: 0.5)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  isDone ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  color: isDone ? ColorUtils.forestGreen : Colors.grey.shade300,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.bodyMedium(
                                color: ColorUtils.darkText,
                                fontWeight: FontWeight.w600,
                              ).copyWith(
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (priority != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: priorityColor, width: 0.5),
                              ),
                              child: Text(
                                priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(LucideIcons.trash2, size: 18, color: Colors.grey.shade400),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Navigation ──────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ColorUtils.forestGreen,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, LucideIcons.layoutDashboard, 'Dashboard'),
          _buildNavItem(1, LucideIcons.map, 'Map'),
          _buildNavItem(2, LucideIcons.messageSquare, 'Forum'),
          _buildNavItem(3, LucideIcons.users, 'Pooling'),
          _buildNavItem(4, LucideIcons.user, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isSelected ? Colors.white : Colors.black, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
