import 'package:flutter/material.dart';
import '../../models/patient_model.dart';
import '/services/patient_service.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Patient _currentPatient;
  final _patientService = PatientService();

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
  }

  Future<void> _handleDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xác nhận xóa hồ sơ'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa bệnh nhân ${_currentPatient.fullName} khỏi hệ thống? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Xóa dữ liệu'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _patientService.deletePatient(_currentPatient.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa bệnh nhân thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleEdit() async {
    final codeCtrl = TextEditingController(text: _currentPatient.patientCode);
    final nameCtrl = TextEditingController(text: _currentPatient.fullName);
    final genderCtrl = TextEditingController(
      text: _currentPatient.gender ?? '',
    );
    final dobCtrl = TextEditingController(
      text: _currentPatient.dateOfBirth ?? '',
    );
    final phoneCtrl = TextEditingController(text: _currentPatient.phone);
    final emailCtrl = TextEditingController(text: _currentPatient.email);
    final addressCtrl = TextEditingController(
      text: _currentPatient.address ?? '',
    );
    final bloodCtrl = TextEditingController(
      text: _currentPatient.bloodType ?? '',
    );
    final allergiesCtrl = TextEditingController(
      text: _currentPatient.allergies ?? '',
    );
    final historyCtrl = TextEditingController(
      text: _currentPatient.medicalHistory ?? '',
    );
    final contactNameCtrl = TextEditingController(
      text: _currentPatient.emergencyContactName ?? '',
    );
    final contactPhoneCtrl = TextEditingController(
      text: _currentPatient.emergencyContactPhone ?? '',
    );
    bool status = _currentPatient.status;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Theme(
        data: Theme.of(context).copyWith(
          primaryColor: Colors.teal,
          colorScheme: const ColorScheme.light(primary: Colors.teal),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                'Chỉnh sửa hồ sơ bệnh nhân',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 650,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: codeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Mã bệnh nhân',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Họ và tên',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: genderCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Giới tính',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: dobCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Ngày sinh (YYYY-MM-DD)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: addressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Địa chỉ cư trú',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: bloodCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nhóm máu',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: allergiesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Dị ứng đặc biệt',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: historyCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Tiểu sử bệnh án',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: contactNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Người liên hệ khẩn cấp',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: contactPhoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'SĐT liên hệ khẩn cấp',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text(
                          'Trạng thái hoạt động',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: status,
                        activeColor: Colors.teal,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) {
                          status = v;
                          setStateDialog(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final body = {
      "patient_code": codeCtrl.text.trim(),
      "full_name": nameCtrl.text.trim(),
      "gender": genderCtrl.text.trim().isEmpty ? null : genderCtrl.text.trim(),
      "date_of_birth": dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "address": addressCtrl.text.trim().isEmpty
          ? null
          : addressCtrl.text.trim(),
      "blood_type": bloodCtrl.text.trim().isEmpty
          ? null
          : bloodCtrl.text.trim(),
      "allergies": allergiesCtrl.text.trim().isEmpty
          ? null
          : allergiesCtrl.text.trim(),
      "medical_history": historyCtrl.text.trim().isEmpty
          ? null
          : historyCtrl.text.trim(),
      "emergency_contact_name": contactNameCtrl.text.trim().isEmpty
          ? null
          : contactNameCtrl.text.trim(),
      "emergency_contact_phone": contactPhoneCtrl.text.trim().isEmpty
          ? null
          : contactPhoneCtrl.text.trim(),
      "status": status,
      "avatar": _currentPatient.avatar,
    };

    try {
      await _patientService.updatePatient(_currentPatient.id, body);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _currentPatient = _currentPatient.copyWith(
          patientCode: body["patient_code"] as String,
          fullName: body["full_name"] as String,
          gender: body["gender"] as String?,
          dateOfBirth: body["date_of_birth"] as String?,
          phone: body["phone"] as String,
          email: body["email"] as String,
          address: body["address"] as String?,
          bloodType: body["blood_type"] as String?,
          allergies: body["allergies"] as String?,
          medicalHistory: body["medical_history"] as String?,
          emergencyContactName: body["emergency_contact_name"] as String?,
          emergencyContactPhone: body["emergency_contact_phone"] as String?,
          status: body["status"] as bool,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý bệnh nhân',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Quản lý hồ sơ y tế và thông tin chi tiết bệnh nhân',
              style: TextStyle(fontSize: 12, color: Color(0xFFB2DFDB)),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Container(
            width: 1200,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 180,
                          height: 230,
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFB2DFDB)),
                            image:
                                (_currentPatient.avatar != null &&
                                    _currentPatient.avatar!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(
                                      _currentPatient.avatar!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              (_currentPatient.avatar == null ||
                                  _currentPatient.avatar!.isEmpty)
                              ? const Center(
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    size: 64,
                                    color: Colors.teal,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[50],
                            foregroundColor: Colors.teal[800],
                            elevation: 0,
                            side: BorderSide(color: Colors.teal[100]!),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Đổi ảnh',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoText(
                              'Mã bệnh nhân: ',
                              _currentPatient.patientCode,
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Họ và tên: ',
                              _currentPatient.fullName,
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Giới tính: ',
                              _currentPatient.gender ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Ngày sinh: ',
                              _currentPatient.dateOfBirth ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Số điện thoại: ',
                              _currentPatient.phone,
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            _buildInfoText('Email: ', _currentPatient.email),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Địa chỉ cư trú: ',
                              _currentPatient.address ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Nhóm máu: ',
                              _currentPatient.bloodType ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            Row(
                              children: [
                                Text(
                                  'Trạng thái hệ thống: ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _currentPatient.status
                                        ? const Color(0xFFE6F4EA)
                                        : const Color(0xFFFCE8E6),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    _currentPatient.status
                                        ? 'Đang hoạt động'
                                        : 'Tạm dừng',
                                    style: TextStyle(
                                      color: _currentPatient.status
                                          ? const Color(0xFF137333)
                                          : const Color(0xFFC5221F),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dị ứng đặc biệt',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentPatient.allergies != null &&
                                _currentPatient.allergies!.isNotEmpty
                            ? _currentPatient.allergies!
                            : 'Không ghi nhận thông tin dị ứng.',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _currentPatient.allergies != null &&
                                  _currentPatient.allergies!.isNotEmpty
                              ? const Color(0xFFC5221F)
                              : Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiểu sử bệnh án',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentPatient.medicalHistory != null &&
                                _currentPatient.medicalHistory!.isNotEmpty
                            ? _currentPatient.medicalHistory!
                            : 'Chưa có dữ liệu tiểu sử bệnh án.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin liên hệ khẩn cấp',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEmergencyContactTile(
                              Icons.account_box_outlined,
                              'Người liên hệ khẩn cấp: ',
                              _currentPatient.emergencyContactName ??
                                  'Chưa cập nhật',
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildEmergencyContactTile(
                              Icons.phone_forwarded_outlined,
                              'Số điện thoại liên hệ: ',
                              _currentPatient.emergencyContactPhone ??
                                  'Chưa cập nhật',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _handleDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text(
                        'Xóa bệnh nhân',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _handleEdit,
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text(
                        'Chỉnh sửa thông tin',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            children: [
              TextSpan(text: label),
              TextSpan(
                text: value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
