import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../models/user_admin_model.dart';
import '../services/admin_service.dart';

/// UserManagementScreen
/// Allows admins to view registered users, filter by role, and toggle account status between active and blocked.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  String _selectedRole = 'all';
  List<UserAdminModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final list = await _adminService.getAllUsers(token, roleFilter: _selectedRole);
      setState(() {
        _users = list;
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

  Future<void> _handleBlockToggle(UserAdminModel user) async {
    final bool isBlocking = user.status.toLowerCase() == 'active';
    final actionName = isBlocking ? 'Block' : 'Unblock';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$actionName Account Access', style: const TextStyle(color: Color(0xff212121))),
        content: Text(
          'Are you sure you want to $actionName user "${user.name}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocking ? const Color(0xffFF5252) : const Color(0xff00E676),
            ),
            child: Text(
              actionName,
              style: TextStyle(
                color: isBlocking ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      if (isBlocking) {
        await _adminService.blockUser(token, user.id);
      } else {
        await _adminService.unblockUser(token, user.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User "${user.name}" $actionName\'d successfully')),
        );
        _loadUsers();
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

  Future<void> _handleDeleteUser(UserAdminModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⚠️ Permanently Delete User', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to PERMANENTLY DELETE user "${user.name}" (${user.role.toUpperCase()})?\n\nThis will permanently delete their account, parts, requests, and platform records. This action CANNOT be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await _adminService.deleteUser(token, user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User "${user.name}" was permanently deleted.'), backgroundColor: Colors.red),
        );
        _loadUsers();
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

  Future<void> _showUser360Dialog(UserAdminModel user) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _adminService.getUser360(token, user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading 360 profile: ${snapshot.error}'));
              }

              final responseData = snapshot.data ?? {};
              final role = responseData['role'] ?? user.role;
              final data = responseData['data'] ?? {};
              final stats = data['stats'] ?? {};

              return Column(
                children: [
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.name} — 360° Insight',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${role.toUpperCase()} • ${user.email}',
                                style: TextStyle(fontSize: 12, color: _getRoleColor(role), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user.isDeletionRequested)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '🚨 ACCOUNT DELETION REQUESTED: User has requested to delete this account.',
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ================= VENDOR 360 VIEW =================
                          if (role == 'vendor') ...[
                            _buildSectionHeader('Shop Identity & Location'),
                            _buildDetailRow('Shop Name', data['vendor']?['shop_name'] ?? 'N/A'),
                            _buildDetailRow('Owner Phone', user.phone ?? 'N/A'),
                            _buildDetailRow('City', data['vendor']?['city'] ?? 'N/A'),
                            _buildDetailRow('Complete Address', data['vendor']?['address'] ?? 'N/A'),
                            _buildDetailRow('Deposit Status', (stats['securityDepositStatus'] ?? 'unpaid').toString().toUpperCase()),
                            const SizedBox(height: 16),

                            _buildSectionHeader('Vendor Platform Performance & Sales'),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.6,
                              children: [
                                _buildMiniStat('📦 Parts Listed', '${stats['totalParts'] ?? 0} Items', Colors.blue),
                                _buildMiniStat('💰 Parts Sold', '${stats['totalSold'] ?? 0} Verified', Colors.green),
                                _buildMiniStat('💵 Gross Earnings', 'Rs. ${(stats['totalEarnings'] ?? 0).toStringAsFixed(0)}', Colors.green),
                                _buildMiniStat('❌ Order Cancels', '${stats['cancellationsCount'] ?? 0} / 3 Max', Colors.orange),
                                _buildMiniStat('🏷️ Comm. Payable', 'Rs. ${(stats['totalCommissionPayable'] ?? 0).toStringAsFixed(0)}', Colors.purple),
                                _buildMiniStat('💳 Comm. Paid', 'Rs. ${(stats['totalCommissionPaid'] ?? 0).toStringAsFixed(0)}', Colors.teal),
                              ],
                            ),
                          ],

                          // ================= CUSTOMER 360 VIEW =================
                          if (role == 'customer') ...[
                            _buildSectionHeader('Customer Identity & Details'),
                            _buildDetailRow('Customer Name', user.name),
                            _buildDetailRow('Phone Number', user.phone ?? 'N/A'),
                            _buildDetailRow('Primary City', data['customer']?['city'] ?? 'N/A'),
                            _buildDetailRow('Email Verified', user.isEmailVerified ? '✅ Verified' : '❌ Unverified'),
                            const SizedBox(height: 16),

                            _buildSectionHeader('Customer Purchasing History & Activity'),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.6,
                              children: [
                                _buildMiniStat('🛒 Requests Placed', '${stats['totalRequests'] ?? 0} Orders', Colors.blue),
                                _buildMiniStat('✅ Purchases Completed', '${stats['totalCompleted'] ?? 0} Delivered', Colors.green),
                                _buildMiniStat('💳 Total Money Spent', 'Rs. ${(stats['totalSpent'] ?? 0).toStringAsFixed(0)}', Colors.green),
                                _buildMiniStat('⭐ Reviews Given', '${stats['totalReviews'] ?? 0} Reviews', Colors.amber.shade800),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),
                          _buildSectionHeader('Administrative Actions'),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _handleBlockToggle(user);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: user.status.toLowerCase() == 'active' ? Colors.orange : Colors.green,
                                ),
                                icon: Icon(user.status.toLowerCase() == 'active' ? Icons.block_rounded : Icons.check_circle_rounded),
                                label: Text(user.status.toLowerCase() == 'active' ? 'Block User' : 'Unblock User'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _handleDeleteUser(user);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                                label: const Text('Delete Account Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff2563EB)),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xff00E5FF);
      case 'vendor':
        return const Color(0xff2563EB);
      case 'customer':
      default:
        return const Color(0xff16A34A);
    }
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'deletion_pending') return const Color(0xffDC2626);
    return status.toLowerCase() == 'active' ? const Color(0xff16A34A) : const Color(0xffDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Segment Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: const Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
            ),
            child: Row(
              children: [
                Icon(Icons.group_work_rounded, color: theme.primaryColor, size: 20),
                const SizedBox(width: 10),
                Text('Role Filter:', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        dropdownColor: Theme.of(context).cardColor,
                        isExpanded: true,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Accounts')),
                          DropdownMenuItem(value: 'customer', child: Text('Customers Only')),
                          DropdownMenuItem(value: 'vendor', child: Text('Vendors Only')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRole = val);
                            _loadUsers();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User Cards List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found for selected filter',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final bool isActive = user.status.toLowerCase() == 'active';
                            final roleColor = _getRoleColor(user.role);
                            final statusColor = _getStatusColor(user.status);

                            return InkWell(
                              onTap: () => _showUser360Dialog(user),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14.0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: user.isDeletionRequested
                                        ? Colors.red
                                        : const Color(0xffE2E8F0),
                                    width: user.isDeletionRequested ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: roleColor.withValues(alpha: 0.15),
                                          child: Icon(
                                            user.role == 'vendor'
                                                ? Icons.storefront_rounded
                                                : user.role == 'admin'
                                                    ? Icons.admin_panel_settings_rounded
                                                    : Icons.person_rounded,
                                            color: roleColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Text(
                                                    user.name,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.textTheme.bodyLarge?.color,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: roleColor.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      user.role.toUpperCase(),
                                                      style: TextStyle(
                                                        color: roleColor,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 9,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(user.email, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                                              if (user.phone != null && user.phone!.isNotEmpty)
                                                Text('Phone: ${user.phone}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                            ],
                                          ),
                                        ),

                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            user.isDeletionRequested ? '🚨 DELETION REQ' : user.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),

                                    // Action Buttons Row with Wrap to avoid overflow
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showUser360Dialog(user),
                                          icon: const Icon(Icons.visibility_rounded, size: 16),
                                          label: const Text('View 360° Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                        if (user.role != 'admin')
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextButton(
                                                onPressed: () => _handleBlockToggle(user),
                                                child: Text(
                                                  isActive ? 'Block' : 'Unblock',
                                                  style: TextStyle(
                                                    color: isActive ? Colors.orange.shade800 : Colors.green,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                                tooltip: 'Delete User Permanently',
                                                onPressed: () => _handleDeleteUser(user),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

