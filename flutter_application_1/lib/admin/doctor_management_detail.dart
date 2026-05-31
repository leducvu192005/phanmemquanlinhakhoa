import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  late Doctor _currentDoctor;

  @override
  void initState() {
    super.initState();
    _currentDoctor = widget.doctor;
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
          'Bạn có chắc chắn muốn xóa bác sĩ ${_currentDoctor.fullName} khỏi hệ thống? Thao tác này không thể hoàn tác.',
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
      await DoctorService().deleteDoctor(_currentDoctor.id as String);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa bác sĩ thành công'),
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
    final codeCtrl = TextEditingController(text: _currentDoctor.doctorCode);
    final nameCtrl = TextEditingController(text: _currentDoctor.fullName);
    final genderCtrl = TextEditingController(text: _currentDoctor.gender ?? '');
    final dobCtrl = TextEditingController(
      text: _currentDoctor.dateOfBirth ?? '',
    );
    final phoneCtrl = TextEditingController(text: _currentDoctor.phone);
    final emailCtrl = TextEditingController(text: _currentDoctor.email);
    final specialtyCtrl = TextEditingController(
      text: _currentDoctor.specialty ?? '',
    );
    final qualCtrl = TextEditingController(
      text: _currentDoctor.qualification ?? '',
    );
    final expCtrl = TextEditingController(
      text: _currentDoctor.experienceYears?.toString() ?? '',
    );
    final addressCtrl = TextEditingController(
      text: _currentDoctor.address ?? '',
    );
    final bioCtrl = TextEditingController(text: _currentDoctor.bio ?? '');
    bool status = _currentDoctor.status;

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
                'Chỉnh sửa hồ sơ bác sĩ',
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
                width: 600,
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
                                labelText: 'Mã bác sĩ',
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
                              controller: specialtyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Chuyên khoa',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: qualCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Trình độ',
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
                              controller: expCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số năm kinh nghiệm',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: addressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Địa chỉ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: bioCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả / Tiểu sử',
                          border: OutlineInputBorder(),
                        ),
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
      "doctor_code": codeCtrl.text.trim(),
      "full_name": nameCtrl.text.trim(),
      "gender": genderCtrl.text.trim().isEmpty ? null : genderCtrl.text.trim(),
      "date_of_birth": dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "specialty": specialtyCtrl.text.trim().isEmpty
          ? null
          : specialtyCtrl.text.trim(),
      "qualification": qualCtrl.text.trim().isEmpty
          ? null
          : qualCtrl.text.trim(),
      "experience_years": int.tryParse(expCtrl.text.trim()),
      "address": addressCtrl.text.trim().isEmpty
          ? null
          : addressCtrl.text.trim(),
      "bio": bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
      "status": status,
      "avatar": _currentDoctor.avatar,
    };

    try {
      await DoctorService().updateDoctor(_currentDoctor.id as String, body);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _currentDoctor = _currentDoctor.copyWith(
          doctorCode: body["doctor_code"] as String,
          fullName: body["full_name"] as String,
          gender: body["gender"] as String?,
          dateOfBirth: body["date_of_birth"] as String?,
          phone: body["phone"] as String,
          email: body["email"] as String,
          specialty: body["specialty"] as String?,
          qualification: body["qualification"] as String?,
          experienceYears: body["experience_years"] as int?,
          address: body["address"] as String?,
          bio: body["bio"] as String?,
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
              'Quản lý bác sĩ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Quản lý tài khoản và thông tin chi tiết bác sĩ',
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
                                (_currentDoctor.avatar != null &&
                                    _currentDoctor.avatar!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(_currentDoctor.avatar!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              (_currentDoctor.avatar == null ||
                                  _currentDoctor.avatar!.isEmpty)
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
                              'Mã bác sĩ: ',
                              _currentDoctor.doctorCode,
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Họ và tên: ',
                              _currentDoctor.fullName,
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Giới tính: ',
                              _currentDoctor.gender ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Ngày sinh: ',
                              _currentDoctor.dateOfBirth ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Số điện thoại: ',
                              _currentDoctor.phone,
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildInfoText('Email: ', _currentDoctor.email),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Chuyên khoa: ',
                              _currentDoctor.specialty ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Trình độ: ',
                              _currentDoctor.qualification ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Kinh nghiệm: ',
                              _currentDoctor.experienceYears != null
                                  ? '${_currentDoctor.experienceYears} năm'
                                  : 'Chưa cập nhật',
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildInfoText(
                              'Địa chỉ: ',
                              _currentDoctor.address ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
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
                                    color: _currentDoctor.status
                                        ? const Color(0xFFE6F4EA)
                                        : const Color(0xFFFCE8E6),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    _currentDoctor.status
                                        ? 'Đang hoạt động'
                                        : 'Tạm dừng',
                                    style: TextStyle(
                                      color: _currentDoctor.status
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
                        'Mô tả bác sĩ / Tiểu sử',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentDoctor.bio ??
                            'Không có thông tin mô tả chi tiết.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
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
                        'Xóa bác sĩ',
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
}
