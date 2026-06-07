import 'package:flutter/material.dart';
import 'payment_model.dart';
import 'payment_service.dart';

class PaymentController extends ChangeNotifier {
  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Filters
  String _searchQuery = '';
  DateTime? _filterDate;
  String _statusFilter = 'all'; // all, unpaid, paid, partially_paid

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  String get searchQuery => _searchQuery;
  DateTime? get filterDate => _filterDate;
  String get statusFilter => _statusFilter;

  Future<void> loadPayments() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _payments = await PaymentService.getPayments();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateFilter(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterDate = null;
    _statusFilter = 'all';
    notifyListeners();
  }

  List<PaymentModel> getFilteredPayments() {
    return _payments.where((p) {
      // Search filter (name, phone, patient code, or booking ID)
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          p.patientName.toLowerCase().contains(query) ||
          p.patientPhone.contains(query) ||
          p.patientCode.toLowerCase().contains(query) ||
          p.bookingId.toLowerCase().contains(query);

      // Date filter
      bool matchesDate = true;
      if (_filterDate != null) {
        // Assume format is yyyy-MM-dd
        final dateStr = '${_filterDate!.year}-${_filterDate!.month.toString().padLeft(2, '0')}-${_filterDate!.day.toString().padLeft(2, '0')}';
        matchesDate = p.bookingDate == dateStr;
      }

      // Status filter
      final matchesStatus = _statusFilter == 'all' || p.paymentStatus == _statusFilter;

      return matchesSearch && matchesDate && matchesStatus;
    }).toList();
  }

  Future<bool> payBill(String id, String method, double discount) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await PaymentService.processPayment(id, method: method, discount: discount);
      // Update local array item
      final index = _payments.indexWhere((p) => p.id == id);
      if (index != -1) {
        _payments[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
