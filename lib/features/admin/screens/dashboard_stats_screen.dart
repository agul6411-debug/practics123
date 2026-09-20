import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/admin_service.dart';

/// DashboardStatsScreen
/// Displays statistical count cards for total vendors, customers, parts, requests, and pending approvals.
class DashboardStatsScreen extends StatefulWidget {
  final Function(int)? onTabChanged;

  const DashboardStatsScreen({super.key, this.onTabChanged});

  @override
  State<DashboardStatsScreen> createState() => _DashboardStatsScreenState();
}

class _DashboardStatsScreenState extends State<DashboardStatsScreen> {
  final AdminService _adminService = AdminService();
  AdminDashboardStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final stats = await _adminService.getDashboardStats(token);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showSalesProofDialog() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _adminService.getSalesProof(token),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading sales proof: ${snapshot.error}'));
              }

              final sales = snapshot.data ?? [];

              return Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verified Platform Sales Proof',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${sales.length} Verified Deliveries & Completed Sales',
                              style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: sales.isEmpty
                        ? const Center(
                            child: Text(
                              'No parts delivered yet.\nOnce customers confirm delivery or scan QR, sales will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sales.length,
                            itemBuilder: (context, index) {
                              final sale = sales[index];
                              final double price = double.tryParse((sale['total_amount'] ?? sale['part_price'] ?? 0).toString()) ?? 0.0;
                              final verifiedDate = sale['verified_at'] != null ? sale['verified_at'].toString().split('T').first : 'Delivered';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            sale['model_name'] ?? 'Part Component',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        Text(
                                          'Rs. ${price.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Brand: ${sale['brand_name'] ?? 'N/A'} • Type: ${sale['part_type_name'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.storefront_rounded, size: 14, color: Colors.purple),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Vendor: ${sale['shop_name']} (${sale['vendor_city'] ?? ''})',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_rounded, size: 14, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Buyer: ${sale['customer_name']} (${sale['customer_phone'] ?? ''})',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '✅ SALE COMPLETED',
                                            style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Text(
                                          'Date: $verifiedDate',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required dynamic value,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    String? subtitle,
    bool isCurrency = false,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: accentColor),
                  ),
                  if (subtitle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isCurrency ? 'Rs. ${value.toStringAsFixed(0)}' : value.toString(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load stats', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadStats, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // System Status Header Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xffE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.analytics_rounded, color: theme.primaryColor, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Platform Live Analytics',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Real-time metrics for inventory, users & leads',
                                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                                onPressed: _loadStats,
                                tooltip: 'Refresh Analytics',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Key Performance Metrics',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Stats Grid (optimized childAspectRatio to 1.25 to prevent text overflow on mobile)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.25,
                          children: [
                            _buildStatCard(
                              label: 'Total Vendors',
                              value: _stats!.totalVendors,
                              icon: Icons.storefront_rounded,
                              accentColor: theme.primaryColor,
                              subtitle: 'ACTIVE SHOPS',
                              onTap: () => widget.onTabChanged?.call(1), // Navigates to Vendor Management
                            ),
                            _buildStatCard(
                              label: 'Total Customers',
                              value: _stats!.totalCustomers,
                              icon: Icons.group_rounded,
                              accentColor: theme.primaryColor,
                              subtitle: 'BUYERS',
                              onTap: () => widget.onTabChanged?.call(2), // Navigates to User Directory
                            ),
                            _buildStatCard(
                              label: 'Parts Listed',
                              value: _stats!.totalParts,
                              icon: Icons.build_circle_rounded,
                              accentColor: theme.primaryColor,
                              subtitle: 'INVENTORY',
                              onTap: () => widget.onTabChanged?.call(3), // Navigates to Category Manager
                            ),
                            _buildStatCard(
                              label: 'Part Requests',
                              value: _stats!.totalRequests,
                              icon: Icons.receipt_long_rounded,
                              accentColor: theme.primaryColor,
                              subtitle: 'LEADS',
                              onTap: () => widget.onTabChanged?.call(4), // Navigates to Commission Review
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Featured Parts Sold / Verified Deliveries Card
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showSalesProofDialog,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xff00E676).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xff00E676).withValues(alpha: 0.35), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xff00E676),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_rounded, color: Colors.black, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${_stats!.totalPartsSold} Parts Sold & Verified',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: theme.textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xff00E676).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'LIVE FEED',
                                                style: TextStyle(color: Color(0xff00E676), fontWeight: FontWeight.bold, fontSize: 9),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tap to view all customer purchases, buyer names, shops & barcode proofs',
                                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xff00E676), size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),


                        // Pending Approvals Banner (Clickable)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onTabChanged?.call(1), // Navigates to Vendor Management
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _stats!.pendingVendorApprovals > 0
                                    ? const Color(0xffD97706).withValues(alpha: 0.12)
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _stats!.pendingVendorApprovals > 0
                                      ? const Color(0xffD97706).withValues(alpha: 0.4)
                                      : const Color(0xffE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.pending_actions_rounded,
                                    color: _stats!.pendingVendorApprovals > 0
                                        ? const Color(0xffD97706)
                                        : Colors.grey,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_stats!.pendingVendorApprovals} Pending Vendor Approvals',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _stats!.pendingVendorApprovals > 0
                                                ? const Color(0xffD97706)
                                                : theme.textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _stats!.pendingVendorApprovals > 0
                                              ? 'Action required: Review documents in Vendor Management'
                                              : 'All vendor applications up to date',
                                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
