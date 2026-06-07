import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_model.dart';
import 'payment_controller.dart';

class PaymentDetailScreen extends StatefulWidget {
  final PaymentModel payment;
  final bool isViewOnly;
  final PaymentController controller;

  const PaymentDetailScreen({
    super.key,
    required this.payment,
    required this.isViewOnly,
    required this.controller,
  });

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final Color primaryColor = const Color(0xFF0D9488);
  final Color accentColor = const Color(0xFF2DD4BF);
  final _discountController = TextEditingController();

  String _selectedMethod = 'cash'; // cash, transfer, qr
  bool _isProcessing = false;
  double _discountVal = 0.0;

  @override
  void initState() {
    super.initState();
    _discountVal = widget.payment.discount;
    _discountController.text = _discountVal.toInt().toString();
    _discountController.addListener(_onDiscountChanged);
  }

  @override
  void dispose() {
    _discountController.removeListener(_onDiscountChanged);
    _discountController.dispose();
    super.dispose();
  }

  void _onDiscountChanged() {
    final val = double.tryParse(_discountController.text) ?? 0.0;
    if (val != _discountVal) {
      setState(() {
        _discountVal = val;
      });
    }
  }

  String _getMethodLabel(String method) {
    if (method == 'cash') return 'Tiền mặt';
    if (method == 'transfer') return 'Chuyển khoản';
    if (method == 'qr') return 'QR Banking';
    return method;
  }


  Future<void> _confirmPayment() async {
    setState(() => _isProcessing = true);
    
    final success = await widget.controller.payBill(
      widget.payment.id,
      _selectedMethod,
      _discountVal,
    );

    setState(() => _isProcessing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hóa đơn ${widget.payment.bookingId} đã được thanh toán thành công!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thanh toán thất bại: ${widget.controller.errorMessage}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 800;
    final totalAmount = widget.payment.subtotal - _discountVal;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isViewOnly ? 'Chi tiết hóa đơn ${widget.payment.bookingId}' : 'Thanh toán hóa đơn',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildBillDetails(totalAmount)),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _buildPaymentActionPanel(totalAmount)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildBillDetails(totalAmount),
                            const SizedBox(height: 20),
                            _buildPaymentActionPanel(totalAmount),
                          ],
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildBillDetails(double totalAmount) {
    String formattedDate = widget.payment.bookingDate;
    try {
      final parsedDate = DateTime.parse(widget.payment.bookingDate);
      formattedDate = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(parsedDate);
    } catch (_) {}

    return Column(
      children: [
        // Khung thông tin bệnh nhân & bác sĩ
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, color: primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Thông tin bệnh nhân',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow('Họ tên:', widget.payment.patientName),
                const SizedBox(height: 8),
                _buildInfoRow('Số điện thoại:', widget.payment.patientPhone),
                const SizedBox(height: 8),
                _buildInfoRow('Mã bệnh nhân:', widget.payment.patientCode),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Khung thông tin ca khám & chẩn đoán
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined, color: primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Chi tiết khám bệnh',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow('Bác sĩ khám:', 'BS. ${widget.payment.doctorName}'),
                const SizedBox(height: 8),
                _buildInfoRow('Ngày khám:', formattedDate),
                const SizedBox(height: 8),
                _buildInfoRow('Chẩn đoán:', widget.payment.diagnosis),
                const SizedBox(height: 8),
                _buildInfoRow('Ghi chú điều trị:', widget.payment.notes.isNotEmpty ? widget.payment.notes : 'Không có ghi chú thêm'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Danh sách dịch vụ thực hiện
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_outlined, color: primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Dịch vụ sử dụng',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Header Table
                Row(
                  children: const [
                    Expanded(flex: 3, child: Text('Tên dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12), textAlign: TextAlign.right)),
                    Expanded(flex: 1, child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12), textAlign: TextAlign.right)),
                  ],
                ),
                const SizedBox(height: 8),
                ...widget.payment.services.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(item.serviceName, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                      Expanded(flex: 2, child: Text('${NumberFormat('#,###', 'vi_VN').format(item.price)}đ', style: const TextStyle(fontSize: 13), textAlign: TextAlign.right)),
                      Expanded(flex: 1, child: Text('${item.quantity}', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('${NumberFormat('#,###', 'vi_VN').format(item.subtotal)}đ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor), textAlign: TextAlign.right)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentActionPanel(double totalAmount) {
    final formatCurrency = NumberFormat('#,###', 'vi_VN');

    return Column(
      children: [
        // Tổng hợp hóa đơn
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng kết thanh toán',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
                const Divider(height: 24),
                _buildSummaryItem('Tạm tính:', '${formatCurrency.format(widget.payment.subtotal)}đ'),
                const SizedBox(height: 10),
                // Chiết khấu / Giảm giá (có thể chỉnh sửa nếu chưa thanh toán)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Giảm giá (đ):', style: TextStyle(color: Colors.black54)),
                    widget.isViewOnly
                        ? Text('${formatCurrency.format(widget.payment.discount)}đ', style: const TextStyle(fontWeight: FontWeight.bold))
                        : SizedBox(
                            width: 120,
                            height: 38,
                            child: TextField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                    Text(
                      '${formatCurrency.format(totalAmount)}đ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Thanh toán hành động panel
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: widget.isViewOnly
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_user_outlined, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Thông tin giao dịch',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Trạng thái:', 'Đã thanh toán', isValuePrimary: true),
                      const SizedBox(height: 8),
                      _buildInfoRow('Hình thức:', _getMethodLabel(widget.payment.paymentMethod ?? 'cash')),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Thời gian:',
                        widget.payment.paymentTime != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(widget.payment.paymentTime!)
                            : 'Không xác định',
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phương thức thanh toán',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Divider(height: 20),
                      _buildPaymentMethodTile('cash', 'Tiền mặt', Icons.payments_outlined),
                      const SizedBox(height: 8),
                      _buildPaymentMethodTile('transfer', 'Chuyển khoản', Icons.account_balance_outlined),
                      const SizedBox(height: 8),
                      _buildPaymentMethodTile('qr', 'QR Banking', Icons.qr_code_2_outlined),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Xác nhận thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      )
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.black45),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primaryColor : Colors.black87),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20)
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isValuePrimary = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isValuePrimary ? Colors.green.shade700 : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
