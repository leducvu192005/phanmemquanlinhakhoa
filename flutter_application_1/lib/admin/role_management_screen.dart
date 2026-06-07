import 'package:flutter/material.dart';
import 'role_management_controller.dart';
import 'user_role_model.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final RoleManagementController _controller = RoleManagementController();
  final TextEditingController _searchController = TextEditingController();

  final Color primaryTeal = const Color(0xFF00A896);
  final Color darkTeal = const Color(0xFF028090);
  final Color lightTeal = const Color(0xFFF0FDFA);
  final Color bgGrey = const Color(0xFFF8FAFC);
  final Color accentOrange = const Color(0xFFF59E0B);

  // Track dropdown role changes locally per user ID before saving
  final Map<int, String> _tempRoles = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.loadUsers();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _saveRole(UserRoleModel user) async {
    final newRole = _tempRoles[user.id] ?? user.role;
    if (newRole == user.role) return;

    try {
      await _controller.saveUserRole(user.id, newRole);
      // Clean temp role mapping on success
      setState(() {
        _tempRoles.remove(user.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật phân quyền của "${user.fullName}" thành "${newRole.toUpperCase()}"!'),
            backgroundColor: darkTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Staff';
      case 'doctor':
        return 'Doctor';
      case 'patient':
        return 'Patient';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 750;
    final list = _controller.filteredUsers;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý phân quyền',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 20),
            ),
            Text(
              'Quản lý vai trò bảo mật của các tài khoản trong hệ thống',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
            onPressed: () {
              setState(() {
                _tempRoles.clear();
              });
              _controller.loadUsers();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _controller.isLoading && _controller.users.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : Column(
              children: [
                // 1. FILTER & SEARCH HEADER BAR
                _buildFilterHeader(),

                // 2. MAIN VIEW AREA (DATATABLE OR CARD LIST)
                Expanded(
                  child: _controller.errorMessage != null && _controller.users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text('Lỗi: ${_controller.errorMessage}'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _controller.loadUsers,
                                child: const Text('Tải lại'),
                              ),
                            ],
                          ),
                        )
                      : list.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  const Text('Không tìm thấy tài khoản nào phù hợp', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: isWide
                                    ? _buildDesktopDataTable(list)
                                    : _buildMobileCardList(list),
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  // 1. Search Bar & Filter Chips Header
  Widget _buildFilterHeader() {
    final filters = ['Tất cả', 'Admin', 'Staff', 'Doctor', 'Patient'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tài khoản theo họ tên, email...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _controller.updateSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: bgGrey,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryTeal, width: 1.5),
              ),
            ),
            onChanged: (val) => _controller.updateSearchQuery(val),
          ),
          const SizedBox(height: 12),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final bool selected = _controller.roleFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(f, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    selected: selected,
                    selectedColor: primaryTeal.withOpacity(0.15),
                    checkmarkColor: primaryTeal,
                    labelStyle: TextStyle(color: selected ? darkTeal : const Color(0xFF64748B)),
                    backgroundColor: bgGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                    onSelected: (_) => _controller.setRoleFilter(f),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Desktop DataTable
  Widget _buildDesktopDataTable(List<UserRoleModel> list) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: const Color(0xFFF1F5F9)),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            headingRowHeight: 52,
            dataRowMaxHeight: 64,
            dataRowMinHeight: 56,
            columns: [
              DataColumn(
                label: Text(
                  'ID',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800], fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  'Họ tên',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800], fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  'Email',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800], fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  'Vai trò (Role)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800], fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  'Trạng thái',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800], fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  'Thao tác',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800], fontSize: 13),
                ),
              ),
            ],
            rows: list.map((user) {
              final activeRole = _tempRoles[user.id] ?? user.role;
              final bool changed = activeRole != user.role;

              return DataRow(
                cells: [
                  DataCell(Text('#${user.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataCell(Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(Text(user.email, style: const TextStyle(fontSize: 13))),
                  DataCell(
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: activeRole.toLowerCase(),
                          items: ['admin', 'staff', 'doctor', 'patient'].map((roleStr) {
                            return DropdownMenuItem<String>(
                              value: roleStr,
                              child: Text(_getRoleLabel(roleStr), style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _tempRoles[user.id] = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isActive ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: user.isActive ? const Color(0xFF137333) : const Color(0xFFC5221F),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: changed ? primaryTeal : Colors.grey[100],
                        foregroundColor: changed ? Colors.white : Colors.grey[400],
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: changed ? () => _saveRole(user) : null,
                      child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // 3. Mobile Card View
  Widget _buildMobileCardList(List<UserRoleModel> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final user = list[index];
        final activeRole = _tempRoles[user.id] ?? user.role;
        final bool changed = activeRole != user.role;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: bgGrey,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    Text('#${user.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Vai trò:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: activeRole.toLowerCase(),
                          items: ['admin', 'staff', 'doctor', 'patient'].map((roleStr) {
                            return DropdownMenuItem<String>(
                              value: roleStr,
                              child: Text(_getRoleLabel(roleStr), style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _tempRoles[user.id] = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isActive ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: user.isActive ? const Color(0xFF137333) : const Color(0xFFC5221F),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: changed ? primaryTeal : Colors.grey[200],
                        foregroundColor: changed ? Colors.white : Colors.grey[500],
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: changed ? () => _saveRole(user) : null,
                      child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
