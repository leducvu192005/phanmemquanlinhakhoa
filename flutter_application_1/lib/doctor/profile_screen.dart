import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import '../services/api.dart';

class DoctorProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onProfileUpdated;

  const DoctorProfileScreen({
    Key? key,
    this.isEmbedded = false,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _doctorService = DoctorService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  Doctor? _doctor;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _gender;
  DateTime? _dob;
  String? _uploadedAvatarUrl;

  final Color primaryTeal = const Color(0xFF0F766E);
  final Color lightTeal = const Color(0xFFE6F7F6);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _specialtyCtrl.dispose();
    _qualificationCtrl.dispose();
    _experienceCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _doctorService.getMyProfile();
      setState(() {
        _doctor = doc;
        _nameCtrl.text = doc.fullName;
        _phoneCtrl.text = doc.phone;
        _specialtyCtrl.text = doc.specialty ?? '';
        _qualificationCtrl.text = doc.qualification ?? '';
        _experienceCtrl.text = doc.experienceYears?.toString() ?? '0';
        _addressCtrl.text = doc.address ?? '';
        _bioCtrl.text = doc.bio ?? '';
        _gender = doc.gender;
        if (doc.dateOfBirth != null) {
          _dob = DateTime.tryParse(doc.dateOfBirth!);
        }
        _uploadedAvatarUrl = doc.avatar;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải hồ sơ: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Chọn và tải ảnh đại diện lên
  Future<void> _pickAndUploadAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // Lấy bytes cho mọi nền tảng
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        final name = file.name;

        if (bytes != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          final relativeUrl = await _doctorService.uploadAvatar(bytes, name);

          Navigator.pop(context); // Đóng loading dialog

          setState(() {
            _uploadedAvatarUrl = relativeUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tải ảnh đại diện lên thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Bảo đảm đóng loading nếu crash
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh đại diện: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Lưu thông tin cập nhật
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày sinh'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'full_name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'gender': _gender,
      'date_of_birth': _dob != null
          ? DateFormat('yyyy-MM-dd').format(_dob!)
          : null,
      'specialty': _specialtyCtrl.text.trim().isEmpty
          ? null
          : _specialtyCtrl.text.trim(),
      'qualification': _qualificationCtrl.text.trim().isEmpty
          ? null
          : _qualificationCtrl.text.trim(),
      'experience_years': int.tryParse(_experienceCtrl.text) ?? 0,
      'address': _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      'avatar': _uploadedAvatarUrl,
    };

    try {
      final updatedDoc = await _doctorService.updateMyProfile(payload);
      setState(() {
        _doctor = updatedDoc;
      });
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ bác sĩ thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu hồ sơ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Lấy đường dẫn ảnh hoàn chỉnh
  String _getAvatarUrl() {
    if (_uploadedAvatarUrl == null || _uploadedAvatarUrl!.isEmpty) {
      return 'https://i.pravatar.cc/300';
    }
    if (_uploadedAvatarUrl!.startsWith('http')) {
      return _uploadedAvatarUrl!;
    }
    return '${Api.baseUrl}$_uploadedAvatarUrl';
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Hồ sơ Bác sĩ'),
              backgroundColor: primaryTeal,
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48.0 : 16.0,
                vertical: 24.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card chứa Ảnh đại diện và thông tin cơ bản
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: lightTeal,
                                      backgroundImage: NetworkImage(
                                        _getAvatarUrl(),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        backgroundColor: primaryTeal,
                                        radius: 18,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          onPressed: _pickAndUploadAvatar,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _doctor?.fullName ?? 'Bác sĩ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _doctor?.doctorCode ?? 'BS999',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form điền thông tin chi tiết
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'THÔNG TIN CÁ NHÂN CHI TIẾT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Họ và tên & Số điện thoại
                                _buildResponsiveRow(isWide, [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nameCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Họ và tên *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                          ? 'Vui lòng nhập tên'
                                          : null,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Số điện thoại *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                          ? 'Vui lòng nhập số điện thoại'
                                          : null,
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 16),

                                // Giới tính & Ngày sinh
                                _buildResponsiveRow(isWide, [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _gender,
                                      decoration: InputDecoration(
                                        labelText: 'Giới tính *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Nam',
                                          child: Text('Nam'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Nữ',
                                          child: Text('Nữ'),
                                        ),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _gender = v),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Vui lòng chọn giới tính'
                                          : null,
                                    ),
                                  ),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.calendar_month),
                                      label: Text(
                                        _dob == null
                                            ? 'Chọn ngày sinh *'
                                            : 'Ngày sinh: ${DateFormat('dd/MM/yyyy').format(_dob!)}',
                                        style: TextStyle(
                                          color: _dob == null
                                              ? Colors.black54
                                              : primaryTeal,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _dob ?? DateTime(1990, 1, 1),
                                          firstDate: DateTime(1950),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setState(() => _dob = picked);
                                        }
                                      },
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 16),

                                // Chuyên khoa & Trình độ học vấn
                                _buildResponsiveRow(isWide, [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _specialtyCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Chuyên khoa *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? 'Vui lòng nhập chuyên khoa'
                                          : null,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _qualificationCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Học vị / Học hàm *',
                                        hintText:
                                            'Ví dụ: Bác sĩ CKI, Thạc sĩ...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? 'Vui lòng nhập học vị / học hàm'
                                          : null,
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 16),

                                // Số năm kinh nghiệm & Địa chỉ
                                _buildResponsiveRow(isWide, [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _experienceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Số năm kinh nghiệm *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? 'Vui lòng nhập số năm kinh nghiệm'
                                          : null,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _addressCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Địa chỉ liên hệ *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? 'Vui lòng nhập địa chỉ liên hệ'
                                          : null,
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 16),

                                // Giới thiệu bản thân / Tiểu sử
                                TextFormField(
                                  controller: _bioCtrl,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Giới thiệu bản thân / Tiểu sử bác sĩ *',
                                    hintText:
                                        'Nhập thông tin giới thiệu để bệnh nhân hiểu rõ về bạn...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Vui lòng nhập giới thiệu bản thân / tiểu sử'
                                      : null,
                                ),
                                const SizedBox(height: 32),

                                // Nút lưu
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryTeal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.save_as_rounded),
                                              SizedBox(width: 8),
                                              Text(
                                                'Lưu thay đổi hồ sơ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildResponsiveRow(bool isWide, List<Widget> children) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            children
                .expand((widget) => [widget, const SizedBox(width: 16)])
                .toList()
              ..removeLast(),
      );
    } else {
      return Column(
        children:
            children
                .expand((widget) => [widget, const SizedBox(height: 16)])
                .toList()
              ..removeLast(),
      );
    }
  }
}
