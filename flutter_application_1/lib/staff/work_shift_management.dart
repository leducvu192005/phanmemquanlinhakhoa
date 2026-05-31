import 'package:flutter/material.dart';
import '../models/work_shift.dart';
import '../services/work_shift.dart';

class WorkShiftManagementScreen extends StatefulWidget {
  const WorkShiftManagementScreen({super.key});

  @override
  State<WorkShiftManagementScreen> createState() =>
      _WorkShiftManagementScreenState();
}

class _WorkShiftManagementScreenState extends State<WorkShiftManagementScreen> {
  List<WorkShift> shifts = [];
  List<WorkShift> filteredShifts = [];
  final TextEditingController searchController = TextEditingController();
  final Color primaryColor = const Color(0xFF0F766E);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadShifts();
  }

  Future<void> loadShifts() async {
    setState(() => _isLoading = true);
    try {
      final data = await WorkShiftApi.getAllShifts();
      setState(() {
        shifts = data;
        filteredShifts = data;
      });
    } catch (e) {
      _showSnackBar('Không thể tải danh sách ca làm việc', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void searchShift(String keyword) {
    setState(() {
      filteredShifts = WorkShiftApi.searchShifts(shifts, keyword);
    });
  }

  Future<void> deleteShift(int id) async {
    try {
      final success = await WorkShiftApi.deleteShift(id);
      if (success) {
        loadShifts();
        _showSnackBar('Xóa ca làm việc thành công', Colors.green);
      } else {
        _showSnackBar('Xóa ca làm việc thất bại', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Lỗi khi xóa ca làm việc', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
      ),
    );
  }

  void showDetail(WorkShift shift) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              shift.shiftName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('Mã ca:', shift.shiftCode),
              _buildDetailRow('Thời gian bắt đầu:', shift.startTime),
              _buildDetailRow('Thời gian kết thúc:', shift.endTime),
              _buildDetailRow(
                'Số bệnh nhân tối đa:',
                '${shift.maxPatients} người',
              ),
              _buildDetailRow(
                'Trạng thái:',
                shift.status ? 'Đang hoạt động' : 'Ngừng hoạt động',
                isStatus: true,
                statusValue: shift.status,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isStatus = false,
    bool statusValue = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusValue ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: statusValue ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  void openFormDialog({WorkShift? shift}) {
    final isEdit = shift != null;
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: isEdit ? shift.shiftCode : '');
    final nameCtrl = TextEditingController(text: isEdit ? shift.shiftName : '');
    final startCtrl = TextEditingController(
      text: isEdit ? shift.startTime : '',
    );
    final endCtrl = TextEditingController(text: isEdit ? shift.endTime : '');
    final maxCtrl = TextEditingController(
      text: isEdit ? shift.maxPatients.toString() : '',
    );
    bool currentStatus = isEdit ? shift.status : true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit ? 'Cập Nhật Ca Làm Việc' : 'Thêm Ca Làm Việc Mới',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: codeCtrl,
                      decoration: _buildInputDecoration(
                        'Mã ca (VD: CA01)',
                        Icons.qr_code_rounded,
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Vui lòng nhập mã ca'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: _buildInputDecoration(
                        'Tên ca (VD: Ca Sáng)',
                        Icons.badge_outlined,
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Vui lòng nhập tên ca'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: startCtrl,
                            decoration: _buildInputDecoration(
                              'Bắt đầu (VD: 08:00)',
                              Icons.access_time,
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Nhập giờ bắt đầu'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: endCtrl,
                            decoration: _buildInputDecoration(
                              'Kết thúc (VD: 12:00)',
                              Icons.access_time_filled,
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Nhập giờ kết thúc'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(
                        'Số bệnh nhân tối đa',
                        Icons.people_outline,
                      ),
                      validator: (v) => (v == null || int.tryParse(v) == null)
                          ? 'Vui lòng nhập một số hợp lệ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trạng thái hoạt động:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Switch(
                          value: currentStatus,
                          activeColor: primaryColor,
                          onChanged: (value) {
                            setDialogState(() {
                              currentStatus = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  if (isEdit) {
                    await WorkShiftApi.updateShift(
                      id: shift.id,
                      shiftCode: codeCtrl.text.trim(),
                      shiftName: nameCtrl.text.trim(),
                      startTime: startCtrl.text.trim(),
                      endTime: endCtrl.text.trim(),
                      maxPatients: int.parse(maxCtrl.text.trim()),
                      status: currentStatus,
                    );
                    _showSnackBar(
                      'Cập nhật ca làm việc thành công',
                      Colors.green,
                    );
                  } else {
                    await WorkShiftApi.createShift(
                      shiftCode: codeCtrl.text.trim(),
                      shiftName: nameCtrl.text.trim(),
                      startTime: startCtrl.text.trim(),
                      endTime: endCtrl.text.trim(),
                      maxPatients: int.parse(maxCtrl.text.trim()),
                      status: currentStatus,
                    );
                    _showSnackBar(
                      'Thêm ca làm việc mới thành công',
                      Colors.green,
                    );
                  }
                  loadShifts();
                } catch (e) {
                  _showSnackBar('Xử lý dữ liệu thất bại', Colors.red);
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: Text(isEdit ? 'Cập nhật' : 'Thêm mới'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor.withValues(alpha: 0.7)),
      labelStyle: const TextStyle(fontSize: 14),
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quản Lý Ca Làm Việc',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thiết lập cấu hình thời gian và số lượng bệnh nhân giới hạn của các ca khám',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => openFormDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Thêm ca mới',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: TextField(
                        controller: searchController,
                        onChanged: searchShift,
                        decoration: InputDecoration(
                          hintText: "Tìm kiếm tên ca hoặc mã ca...",
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.black45,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'TÊN CA / MÃ CA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'THỜI GIAN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'SL TỐI ĐA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'TRẠNG THÁI',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'THAO TÁC',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              )
                            : filteredShifts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 48,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Không tìm thấy dữ liệu phù hợp',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredShifts.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final shift = filteredShifts[index];
                                  return InkWell(
                                    onTap: () => showDetail(shift),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  shift.shiftName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    shift.shiftCode,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[700],
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.black45,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${shift.startTime} - ${shift.endTime}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.people_alt_outlined,
                                                  size: 16,
                                                  color: Colors.black45,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${shift.maxPatients} BN',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: shift.status
                                                        ? Colors.green
                                                        : Colors.grey,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  shift.status
                                                      ? 'Hoạt động'
                                                      : 'Tạm dừng',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: shift.status
                                                        ? Colors.green[700]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.visibility_outlined,
                                                    size: 18,
                                                  ),
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                  onPressed: () =>
                                                      showDetail(shift),
                                                  tooltip: 'Xem chi tiết',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                  ),
                                                  color: Colors.blue[600],
                                                  onPressed: () =>
                                                      openFormDialog(
                                                        shift: shift,
                                                      ),
                                                  tooltip: 'Sửa ca',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 18,
                                                  ),
                                                  color: Colors.red[600],
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text(
                                                          'Xác nhận xóa',
                                                        ),
                                                        content: Text(
                                                          'Bạn có chắc muốn xóa ca làm việc "${shift.shiftName}" không?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                ),
                                                            child: const Text(
                                                              'Hủy',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                              deleteShift(
                                                                shift.id,
                                                              );
                                                            },
                                                            child: const Text(
                                                              'Xóa',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                  tooltip: 'Xóa ca',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
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
