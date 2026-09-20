import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/notification_bell_icon.dart';
import '../../auth/services/auth_provider.dart';
import '../models/part_model.dart';
import '../services/vendor_service.dart';

import 'vendor_dashboard_screen.dart';
import '../../../routes.dart';

/// MyPartsScreen
/// Displays vendor inventory list with dual tabs: Active Inventory & Sold Parts History.
class MyPartsScreen extends StatefulWidget {
  const MyPartsScreen({super.key});

  @override
  State<MyPartsScreen> createState() => _MyPartsScreenState();
}

class _MyPartsScreenState extends State<MyPartsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VendorService _vendorService = VendorService();
  
  List<PartModel> _parts = [];
  List<Map<String, dynamic>> _soldParts = [];
  bool _isLoading = true;
  bool _isLoadingSold = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _soldParts.isEmpty && !_isLoadingSold) {
        _loadSoldParts();
      }
      setState(() {});
    });
    _loadParts();
    _loadSoldParts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadParts() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final list = await _vendorService.getMyParts(token);
      if (mounted) {
        setState(() {
          _parts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadSoldParts() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoadingSold = true);

    try {
      final list = await _vendorService.getMySoldParts(token);
      if (mounted) {
        setState(() {
          _soldParts = list;
          _isLoadingSold = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSold = false);
      }
    }
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Inventory Part', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this part listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5252)),
            child: const Text('Delete Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await _vendorService.deletePart(token, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Part deleted successfully')),
        );
        _loadParts();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: const Text('Parts Inventory & Sales', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_outlined),
              text: 'Active Inventory (${_parts.length})',
            ),
            Tab(
              icon: const Icon(Icons.verified_outlined),
              text: 'Sold Parts (${_soldParts.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_rounded, color: Color(0xff00E5FF)),
            tooltip: 'Browse Marketplace Page',
            onPressed: () {
              final dashboard = VendorDashboardScreen.of(context);
              if (dashboard != null) {
                dashboard.setTab(0);
              } else {
                Get.toNamed(AppRoutes.vendorDashboard, arguments: 0);
              }
            },
          ),
          const NotificationBellIcon(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadParts();
              _loadSoldParts();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveInventoryTab(),
          _buildSoldPartsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xff7C4DFF),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Part', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final result = await Get.toNamed(AppRoutes.addEditPart);
                if (result == true || mounted) {
                  _loadParts();
                }
              },
            )
          : null,
    );
  }

  Widget _buildActiveInventoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_parts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 48, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'No parts listed in inventory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 6),
            Text('Start listing phone components for customer search', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Get.toNamed(AppRoutes.addEditPart);
                if (result == true || mounted) {
                  _loadParts();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Part'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadParts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _parts.length,
        itemBuilder: (context, index) {
          final part = _parts[index];
          final isAvailable = part.status == 'available';
          final imageUrl = part.originalPhotoUrl != null
              ? '${ApiConstants.baseUrl}${part.originalPhotoUrl}'
              : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffCCCCCC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xffCCCCCC)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                              )
                            : const Icon(Icons.image_search_rounded, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  part.modelName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Rs. ${part.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${part.brandName ?? 'Brand #${part.brandId}'} • ${part.partTypeName ?? 'Type #${part.partTypeId}'}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          if (part.barcodeNumber != null && part.barcodeNumber!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Barcode: ${part.barcodeNumber}',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            part.conditionType.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Stock: ${part.stockQuantity}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xff00E676).withValues(alpha: 0.15)
                            : const Color(0xffFF5252).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAvailable
                              ? const Color(0xff00E676).withValues(alpha: 0.4)
                              : const Color(0xffFF5252).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        part.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? const Color(0xff00E676) : const Color(0xffFF5252),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xffCCCCCC), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Get.toNamed(AppRoutes.addEditPart, arguments: part);
                        if (result == true || mounted) {
                          _loadParts();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xffCCCCCC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xffFF5252), size: 20),
                      onPressed: () => _handleDelete(part.id),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSoldPartsTab() {
    if (_isLoadingSold) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_soldParts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff00E676).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, size: 48, color: Color(0xff00E676)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Sold Parts Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'When customers purchase your parts and delivery is verified via Barcode/QR scan, they will be tracked here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSoldParts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _soldParts.length,
        itemBuilder: (context, index) {
          final item = _soldParts[index];
          final price = double.tryParse(item['part_price']?.toString() ?? '0') ?? 0.0;
          final totalAmount = double.tryParse(item['total_amount']?.toString() ?? '0') ?? price;
          final customerName = item['customer_name'] ?? 'Customer';
          final customerPhone = item['customer_phone'] ?? '';
          final customerCity = item['customer_city'] ?? '';
          final verifiedBarcode = item['verified_barcode'] ?? item['barcode_number'] ?? '';
          final verifiedAt = item['verified_at'] ?? item['order_created_at'] ?? '';
          final deliveryType = item['delivery_type'] ?? 'pickup';
          final photoUrl = item['original_photo_url'] ?? item['image_url'];
          final fullPhotoUrl = photoUrl != null ? '${ApiConstants.baseUrl}$photoUrl' : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xff00E676).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xffCCCCCC)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: fullPhotoUrl != null
                            ? Image.network(
                                fullPhotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                              )
                            : const Icon(Icons.check_circle_outline_rounded, color: Color(0xff00E676)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['model_name'] ?? 'Sold Part',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Rs. ${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff00E676),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['brand_name'] ?? ''} • ${item['part_type_name'] ?? ''}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xff00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: Color(0xff00E676)),
                                SizedBox(width: 4),
                                Text(
                                  'PURCHASE DELIVERED & VERIFIED',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xff00E676)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xffCCCCCC), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Buyer: $customerName ($customerCity)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    if (customerPhone.isNotEmpty)
                      Text(
                        customerPhone,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Delivery: ${deliveryType == 'home_delivery' ? 'Home Delivery' : 'Pickup at Shop'}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    const Spacer(),
                    if (verifiedBarcode.isNotEmpty)
                      Text(
                        'Barcode: $verifiedBarcode',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontFamily: 'monospace'),
                      ),
                  ],
                ),
                if (verifiedAt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Completed: $verifiedAt',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

