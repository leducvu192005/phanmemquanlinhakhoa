import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import 'doctor_management_detail.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  String? _error;
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doctors = await DoctorService().getDoctors();
      setState(() {
        _allDoctors = doctors;
        _filteredDoctors = doctors;
      });
      if (_searchCtrl.text.trim().isNotEmpty) {
        _applyFilter(_searchCtrl.text.trim());
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _applyFilter(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final nameMatch = doctor.fullName.toLowerCase().contains(query);
        final phoneMatch = doctor.phone.toLowerCase().contains(query);
        final specialtyMatch = (doctor.specialty ?? '').toLowerCase().contains(
          query,
        );
        return nameMatch || phoneMatch || specialtyMatch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản Lý Bác Sĩ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              'Xem, tìm kiếm và cập nhật hồ sơ thông tin của đội ngũ bác sĩ',
              style: TextStyle(fontSize: 12, color: Color(0xFFB2DFDB)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.teal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm nhanh theo tên, số điện thoại, chuyên khoa...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.teal),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: Colors.teal,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _filteredDoctors = _allDoctors;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (v) => _applyFilter(v.trim()),
                onSubmitted: (v) => _applyFilter(v.trim()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _StatCard(
                  title: 'Tổng số bác sĩ',
                  value: '${_allDoctors.length}',
                  icon: Icons.people_alt_outlined,
                  iconColor: Colors.teal,
                  iconBg: Colors.teal[50]!,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Đang hoạt động',
                  value: '${_allDoctors.where((e) => e.status).length}',
                  valueColor: Colors.teal[700],
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.teal[700]!,
                  iconBg: Colors.teal[50]!,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kết quả: ${_filteredDoctors.length} bác sĩ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Builder(
                    builder: (context) {
                      if (_loading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.teal,
                            ),
                          ),
                        );
                      }
                      if (_error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 40,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Lỗi: $_error',
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        );
                      }
                      if (_filteredDoctors.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Không tìm thấy dữ liệu bác sĩ',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: const Color(0xFFF1F5F9)),
                          child: DataTable(
                            showCheckboxColumn: false,
                            headingRowColor: MaterialStateProperty.all(
                              Colors.teal[50]?.withOpacity(0.5),
                            ),
                            headingRowHeight: 52,
                            dataRowMaxHeight: 68,
                            dataRowMinHeight: 60,
                            columns: [
                              DataColumn(
                                label: Text(
                                  'Thông tin bác sĩ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[800],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Chuyên khoa',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[800],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Số điện thoại',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[800],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Trạng thái',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[800],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Mô tả / Tiểu sử',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[800],
                                  ),
                                ),
                              ),
                            ],
                            rows: _filteredDoctors.map((doctor) {
                              final avatarText = doctor.fullName
                                  .split(' ')
                                  .where((e) => e.isNotEmpty)
                                  .map((e) => e[0])
                                  .take(2)
                                  .join()
                                  .toUpperCase();

                              return DataRow(
                                onSelectChanged: (selected) async {
                                  if (selected != null && selected) {
                                    final refresh = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DoctorDetailScreen(doctor: doctor),
                                      ),
                                    );
                                    if (refresh == true) {
                                      _loadData();
                                    }
                                  }
                                },
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.teal[50],
                                          backgroundImage:
                                              (doctor.avatar != null &&
                                                  doctor.avatar!.isNotEmpty)
                                              ? NetworkImage(doctor.avatar!)
                                              : null,
                                          child:
                                              (doctor.avatar == null ||
                                                  doctor.avatar!.isEmpty)
                                              ? Text(
                                                  avatarText,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.teal,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doctor.fullName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              doctor.email,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      (doctor.specialty != null &&
                                              doctor.specialty!.isNotEmpty)
                                          ? doctor.specialty!
                                          : 'Chưa cập nhật',
                                      style: TextStyle(color: Colors.grey[800]),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      doctor.phone,
                                      style: TextStyle(color: Colors.grey[800]),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: doctor.status
                                            ? const Color(0xFFE6F4EA)
                                            : const Color(0xFFFCE8E6),
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Text(
                                        doctor.status
                                            ? 'Hoạt động'
                                            : 'Tạm dừng',
                                        style: TextStyle(
                                          color: doctor.status
                                              ? const Color(0xFF137333)
                                              : const Color(0xFFC5221F),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 250,
                                      child: Text(
                                        (doctor.bio != null &&
                                                doctor.bio!.isNotEmpty)
                                            ? doctor.bio!
                                            : 'Chưa có mô tả',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
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
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.title,
    required this.value,
    this.valueColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
