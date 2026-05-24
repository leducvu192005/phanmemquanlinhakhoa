import 'package:flutter/material.dart';

import '../services/api.dart';
import 'patient_management_screen.dart';
import 'dart:convert';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  String? _error;
  List<dynamic> _users = [];
  Map<String, dynamic> _stats = {};
  int _selectedIndex = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? q}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final usersRes = await Api.getAdminUsersWithQuery(q);
      final statsRes = await Api.getAdminStats();

      if (usersRes.statusCode == 200) {
        _users = jsonDecode(usersRes.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load users: ${usersRes.statusCode}');
      }

      if (statsRes.statusCode == 200) {
        _stats = jsonDecode(statsRes.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load stats: ${statsRes.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa người dùng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final res = await Api.deleteUser(id);
      if (!mounted) return;
      if (res.statusCode == 204 || res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
        await _loadData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa: ${res.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> u) async {
    final nameCtrl = TextEditingController(text: u['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: u['phone'] ?? '');
    final roleCtrl = TextEditingController(text: u['role'] ?? '');
    bool status = u['status'] == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa người dùng'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                  ),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                  ),
                  TextField(
                    controller: roleCtrl,
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  Row(
                    children: [
                      const Text('Hoạt động'),
                      Checkbox(
                        value: status,
                        onChanged: (v) {
                          status = v ?? false;
                          setStateDialog(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final body = <String, dynamic>{};
    body['full_name'] = nameCtrl.text.trim();
    body['phone'] = phoneCtrl.text.trim();
    body['role'] = roleCtrl.text.trim();
    body['status'] = status;

    try {
      final res = await Api.updateUser(u['id'], body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
        await _loadData();
      } else {
        String msg = 'Lỗi: ${res.statusCode}';
        try {
          final b = jsonDecode(res.body);
          msg = b['detail'] ?? b['message'] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 900;
            return Row(
              children: [
                // Sidebar
                Container(
                  width: isWide ? 240 : 72,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: isWide
                            ? Row(
                                children: [
                                  Icon(
                                    Icons.medical_services,
                                    color: Colors.redAccent,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Admin Panel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Icon(
                                  Icons.menu,
                                  color: Colors.redAccent,
                                ),
                              ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView(
                          children: [
                            _SidebarItem(
                              icon: Icons.people,
                              label: 'Nhân viên',
                              wide: isWide,
                              selected: _selectedIndex == 0,
                              onTap: () => setState(() {
                                _selectedIndex = 0;
                              }),
                            ),
                            _SidebarItem(
                              icon: Icons.person,
                              label: 'Bệnh nhân',
                              wide: isWide,
                              selected: _selectedIndex == 1,
                              onTap: () => setState(() {
                                _selectedIndex = 1;
                              }),
                            ),
                            _SidebarItem(
                              icon: Icons.calendar_today,
                              label: 'Lịch làm việc',
                              wide: isWide,
                              selected: _selectedIndex == 2,
                              onTap: () => setState(() {
                                _selectedIndex = 2;
                              }),
                            ),
                            _SidebarItem(
                              icon: Icons.folder_shared,
                              label: 'Hồ sơ',
                              wide: isWide,
                              selected: _selectedIndex == 3,
                              onTap: () => setState(() {
                                _selectedIndex = 3;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: Container(
                    color: const Color(0xFFF7F9FC),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedIndex == 0
                                      ? 'Quản lí nhân viên'
                                      : _selectedIndex == 1
                                      ? 'Quản lí bệnh nhân'
                                      : _selectedIndex == 2
                                      ? 'Lịch làm việc'
                                      : 'Hồ sơ',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedIndex == 0
                                      ? 'Quản lí tài khoản nhân viên'
                                      : _selectedIndex == 1
                                      ? 'Quản lí tài khoản bệnh nhân'
                                      : '',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.settings),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        if (_selectedIndex == 0) ...[
                          // Stat cards
                          if (_loading)
                            const Center(child: CircularProgressIndicator())
                          else if (_error != null)
                            Text('Lỗi: ' + (_error ?? ''))
                          else
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                _StatCard(
                                  title: 'Số lượng nhân viên',
                                  value: '${_stats['total'] ?? 0}',
                                ),
                                _StatCard(
                                  title: 'Đang hoạt động',
                                  value: '${_stats['active'] ?? 0}',
                                  valueColor: Colors.green,
                                ),
                                _StatCard(
                                  title: 'Bác sĩ',
                                  value: '${_stats['doctors'] ?? 0}',
                                  valueColor: Colors.blue,
                                ),
                                _StatCard(
                                  title: 'Nhân viên văn phòng',
                                  value: '${_stats['receptionists'] ?? 0}',
                                  valueColor: Colors.purple,
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),

                          // Search + actions
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.search),
                                      hintText: 'Nhập tên, email....',
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (v) => _loadData(q: v.trim()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (_) {
                                      final emailCtrl = TextEditingController();
                                      final nameCtrl = TextEditingController();
                                      final phoneCtrl = TextEditingController();
                                      final roleCtrl = TextEditingController();
                                      final passCtrl = TextEditingController();
                                      bool active = true;
                                      return StatefulBuilder(
                                        builder: (c, setStateDialog) => AlertDialog(
                                          title: const Text('Thêm người dùng'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: emailCtrl,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Email',
                                                      ),
                                                ),
                                                TextField(
                                                  controller: nameCtrl,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Họ và tên',
                                                      ),
                                                ),
                                                TextField(
                                                  controller: phoneCtrl,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Số điện thoại',
                                                      ),
                                                ),
                                                TextField(
                                                  controller: roleCtrl,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Role',
                                                      ),
                                                ),
                                                TextField(
                                                  controller: passCtrl,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Mật khẩu',
                                                      ),
                                                ),
                                                Row(
                                                  children: [
                                                    const Text('Hoạt động'),
                                                    Checkbox(
                                                      value: active,
                                                      onChanged: (v) {
                                                        active = v ?? false;
                                                        setStateDialog(() {});
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(false),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final body = {
                                                  'email': emailCtrl.text
                                                      .trim(),
                                                  'full_name': nameCtrl.text
                                                      .trim(),
                                                  'phone': phoneCtrl.text
                                                      .trim(),
                                                  'role': roleCtrl.text.trim(),
                                                  'password': passCtrl.text,
                                                };
                                                try {
                                                  final res =
                                                      await Api.createUser(
                                                        body,
                                                      );
                                                  if (res.statusCode == 201)
                                                    Navigator.of(c).pop(true);
                                                  else {
                                                    String msg =
                                                        'Lỗi: ${res.statusCode}';
                                                    try {
                                                      final b = jsonDecode(
                                                        res.body,
                                                      );
                                                      msg =
                                                          b['detail'] ??
                                                          b['message'] ??
                                                          msg;
                                                    } catch (_) {}
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(msg),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Lỗi: $e'),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('Tạo'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                  if (result == true) await _loadData();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // User list
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    if (_loading)
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    else if (_error != null)
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text('Lỗi: ' + _error!),
                                      )
                                    else if (_users.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text('Không có người dùng'),
                                      )
                                    else
                                      for (var u in _users) ...[
                                        _UserRow(
                                          avatarText: (u['full_name'] ?? '')
                                              .toString()
                                              .split(' ')
                                              .map(
                                                (s) => s.isNotEmpty ? s[0] : '',
                                              )
                                              .take(2)
                                              .join(),
                                          name:
                                              u['full_name'] ??
                                              u['email'] ??
                                              '',
                                          email: u['email'] ?? '',
                                          phone: u['phone'] ?? '',
                                          role: u['role'] ?? '',
                                          active: u['status'] == true,
                                          onEdit: () => _showEditDialog(u),
                                          onDelete: () =>
                                              _confirmDelete(u['id']),
                                        ),
                                        const Divider(),
                                      ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ] else if (_selectedIndex == 1) ...[
                          const SizedBox(height: 0),
                          Expanded(child: PatientManagementContent()),
                        ] else ...[
                          const SizedBox(height: 20),
                          Expanded(
                            child: Center(
                              child: Text(
                                _selectedIndex == 2
                                    ? 'Lịch làm việc (tạm)'
                                    : 'Hồ sơ (tạm)',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool wide;
  final bool selected;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.wide,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.redAccent : Colors.black54),
      title: wide
          ? Text(
              label,
              style: TextStyle(
                color: selected ? Colors.redAccent : Colors.black87,
              ),
            )
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _StatCard({required this.title, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final String avatarText;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool active;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _UserRow({
    required this.avatarText,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.active,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(child: Text(avatarText)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email, size: 14, color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(email, style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phone),
                const SizedBox(height: 4),
                Text(role, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  active ? 'Hoạt động' : 'Đang tắt',
                  style: TextStyle(color: active ? Colors.green : Colors.red),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Colors.blue),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
