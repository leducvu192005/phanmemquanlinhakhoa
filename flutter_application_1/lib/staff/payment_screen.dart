import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_controller.dart';
import 'payment_model.dart';
import 'payment_detail_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentController _controller = PaymentController();
  final Color primaryColor = const Color(0xFF0D9488);
  final Color accentColor = const Color(0xFF2DD4BF);
  final Color unpaidColor = Colors.amber.shade800;
  final Color paidColor = Colors.green.shade700;
  final Color partiallyPaidColor = Colors.orange.shade700;

  @override
  void initState() {
    super.initState();
    _controller.loadPayments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    if (status == 'paid') return paidColor;
    if (status == 'partially_paid') return partiallyPaidColor;
    return unpaidColor;
  }

  String _getStatusText(String status) {
    if (status == 'paid') return 'Đã thanh toán';
    if (status == 'partially_paid') return 'Thanh toán một phần';
    return 'Chưa thanh toán';
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;
    final bool isMedium =
        MediaQuery.of(context).size.width > 600 &&
        MediaQuery.of(context).size.width <= 900;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final filteredList = _controller.getFilteredPayments();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Quản lý thanh toán hóa đơn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: primaryColor.withOpacity(0.2),
                height: 1.0,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: primaryColor),
                onPressed: () => _controller.loadPayments(),
              ),
            ],
          ),
          body: _controller.isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _controller.errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    'Lỗi: ${_controller.errorMessage}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterSection(context),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Không có hóa đơn thanh toán nào phù hợp.',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : isWide
                            ? _buildWebDataTable(filteredList)
                            : isMedium
                            ? _buildTabletTable(filteredList)
                            : _buildMobileListView(filteredList),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final dateText = _controller.filterDate == null
        ? 'Chọn ngày'
        : DateFormat('dd/MM/yyyy').format(_controller.filterDate!);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Ô tìm kiếm bệnh nhân
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (val) => _controller.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo Tên, SĐT, Mã BN hoặc Mã lịch...',
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Lọc theo ngày
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _controller.filterDate ?? DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    _controller.setDateFilter(picked);
                  },
                  icon: Icon(
                    Icons.calendar_month,
                    color: primaryColor,
                    size: 18,
                  ),
                  label: Text(
                    dateText,
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                if (_controller.filterDate != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () => _controller.setDateFilter(null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Trạng thái thanh toán chips
            Row(
              children: [
                const Text(
                  'Trạng thái:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip('all', 'Tất cả'),
                        const SizedBox(width: 8),
                        _buildStatusChip('unpaid', 'Chưa thanh toán'),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          'partially_paid',
                          'Thanh toán một phần',
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip('paid', 'Đã thanh toán'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _controller.statusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      onSelected: (_) => _controller.setStatusFilter(value),
      selectedColor: primaryColor,
      checkmarkColor: Colors.white,
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
    );
  }

  Widget _buildWebDataTable(List<PaymentModel> list) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMaxHeight: 64,
          columns: const [
            DataColumn(
              label: Text(
                'Mã lịch khám',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Bệnh nhân',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Bác sĩ phụ trách',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Ngày khám',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Tổng chi phí',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Trạng thái',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Thao tác',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: list.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    item.bookingId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Mã: ${item.patientCode}',
                        style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text('BS. ${item.doctorName}')),
                DataCell(Text(item.bookingDate)),
                DataCell(
                  Text(
                    '${NumberFormat('#,###', 'vi_VN').format(item.totalAmount)}đ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                DataCell(_buildStatusBadge(item.paymentStatus)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _navigateToDetail(item, isViewOnly: true),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      if (item.paymentStatus != 'paid') ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _navigateToDetail(item, isViewOnly: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Thanh toán',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabletTable(List<PaymentModel> list) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMaxHeight: 60,
          columnSpacing: 20,
          columns: const [
            DataColumn(
              label: Text(
                'Lịch khám',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Bệnh nhân',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Tổng tiền',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Trạng thái',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Thao tác',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: list.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    item.bookingId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    item.patientName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    '${NumberFormat('#,###', 'vi_VN').format(item.totalAmount)}đ',
                  ),
                ),
                DataCell(_buildStatusBadge(item.paymentStatus)),
                DataCell(
                  IconButton(
                    icon: Icon(
                      item.paymentStatus == 'paid'
                          ? Icons.visibility_outlined
                          : Icons.payment_outlined,
                      color: primaryColor,
                    ),
                    onPressed: () => _navigateToDetail(
                      item,
                      isViewOnly: item.paymentStatus == 'paid',
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileListView(List<PaymentModel> list) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final item = list[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.bookingId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    _buildStatusBadge(item.paymentStatus),
                  ],
                ),
                const Divider(height: 20),
                _buildMobileRow(
                  Icons.person_outline,
                  'Bệnh nhân:',
                  item.patientName,
                ),
                const SizedBox(height: 6),
                _buildMobileRow(
                  Icons.medical_services_outlined,
                  'Bác sĩ:',
                  'BS. ${item.doctorName}',
                ),
                const SizedBox(height: 6),
                _buildMobileRow(
                  Icons.calendar_month_outlined,
                  'Ngày khám:',
                  item.bookingDate,
                ),
                const SizedBox(height: 6),
                _buildMobileRow(
                  Icons.currency_exchange_outlined,
                  'Tổng chi phí:',
                  '${NumberFormat('#,###', 'vi_VN').format(item.totalAmount)}đ',
                  isBoldVal: true,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          _navigateToDetail(item, isViewOnly: true),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Xem chi tiết',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (item.paymentStatus != 'paid') ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            _navigateToDetail(item, isViewOnly: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Thanh toán',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileRow(
    IconData icon,
    String label,
    String value, {
    bool isBoldVal = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black38),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.black45, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBoldVal ? FontWeight.bold : FontWeight.normal,
              color: isBoldVal ? primaryColor : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  void _navigateToDetail(PaymentModel payment, {required bool isViewOnly}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentDetailScreen(
          payment: payment,
          isViewOnly: isViewOnly,
          controller: _controller,
        ),
      ),
    ).then((_) => _controller.loadPayments());
  }
}
