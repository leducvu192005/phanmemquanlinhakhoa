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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý bác sĩ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Xem, tìm kiếm và cập nhật hồ sơ thông tin của đội ngũ bác sĩ',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 20,
              runSpacing: 16,
              children: [
                _StatCard(
                  title: 'Tổng số bác sĩ',
                  value: '${_allDoctors.length}',
                  icon: Icons.people_alt_outlined,
                  iconColor: Colors.blue,
                  iconBg: Colors.blue.withOpacity(0.1),
                ),
                _StatCard(
                  title: 'Đang hoạt động',
                  value: '${_allDoctors.where((e) => e.status).length}',
                  valueColor: Colors.green,
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.green,
                  iconBg: Colors.green.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _filteredDoctors = _allDoctors;
                                  });
                                },
                              )
                            : null,
                        hintText: 'Tìm theo tên, số điện thoại...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      onChanged: (v) => _applyFilter(v.trim()),
                      onSubmitted: (v) => _applyFilter(v.trim()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
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
                        return const Center(child: CircularProgressIndicator());
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
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 44,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
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
                              const Color(0xFFF8FAFC),
                            ),
                            headingRowHeight: 52,
                            dataRowMaxHeight: 68,
                            dataRowMinHeight: 60,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Thông tin bác sĩ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Chuyên khoa',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Số điện thoại',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Trạng thái',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Mô tả / Tiểu sử',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
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
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1),
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
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
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
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              doctor.email,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 13,
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
                                      style: const TextStyle(
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      doctor.phone,
                                      style: const TextStyle(
                                        color: Color(0xFF334155),
                                      ),
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
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFFEE2E2),
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
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFFB91C1C),
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
                                          color: Color(0xFF64748B),
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
          ],
        ),
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
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
