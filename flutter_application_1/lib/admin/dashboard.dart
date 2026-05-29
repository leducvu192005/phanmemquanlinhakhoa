import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  String? _error;

  List<Doctor> _doctors = [];

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
      final doctors = await DoctorService().getDoctors(query: q);

      setState(() {
        _doctors = doctors;
      });
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

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bác sĩ này không?'),
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
      await DoctorService().deleteDoctor(id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa thành công')));

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _showEditDialog(Doctor doctor) async {
    final nameCtrl = TextEditingController(text: doctor.fullName);

    final phoneCtrl = TextEditingController(text: doctor.phone);

    final specialtyCtrl = TextEditingController(text: doctor.specialty);

    bool status = doctor.status;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa bác sĩ'),
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
                    controller: specialtyCtrl,
                    decoration: const InputDecoration(labelText: 'Chuyên khoa'),
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

    final body = {
      "full_name": nameCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "specialty": specialtyCtrl.text.trim(),
      "status": status,
    };

    try {
      await DoctorService().updateDoctor(doctor.id, body);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9FC),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Quản lí bác sĩ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Quản lí thông tin bác sĩ',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),

              IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
            ],
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _StatCard(title: 'Tổng bác sĩ', value: '${_doctors.length}'),

              _StatCard(
                title: 'Đang hoạt động',
                value: '${_doctors.where((e) => e.status).length}',
                valueColor: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search),
                      hintText: 'Tìm bác sĩ...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (v) => _loadData(q: v.trim()),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              ElevatedButton.icon(
                onPressed: () async {},
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text('Lỗi: $_error'),
                      )
                    else if (_doctors.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('Không có bác sĩ'),
                      )
                    else
                      for (var doctor in _doctors) ...[
                        _UserRow(
                          avatarText: doctor.fullName
                              .split(' ')
                              .map((e) => e[0])
                              .take(2)
                              .join(),

                          name: doctor.fullName,

                          email: doctor.email,

                          phone: doctor.phone,

                          active: doctor.status,

                          onEdit: () => _showEditDialog(doctor),

                          onDelete: () => _confirmDelete(doctor.id),
                        ),

                        const Divider(),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
  final bool active;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _UserRow({
    required this.avatarText,
    required this.name,
    required this.email,
    required this.phone,
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
                    const Icon(Icons.email, size: 14, color: Colors.black45),

                    const SizedBox(width: 6),

                    Text(email, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(phone), const SizedBox(height: 4)],
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
