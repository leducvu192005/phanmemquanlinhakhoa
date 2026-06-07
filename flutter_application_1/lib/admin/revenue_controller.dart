import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'revenue_model.dart';
import 'revenue_repository.dart';

class RevenueController extends ChangeNotifier {
  final RevenueRepository _repository = RevenueRepository();

  RevenueReport? _report;
  bool _isLoading = false;
  String? _errorMessage;

  DateTime? _startDate;
  DateTime? _endDate;

  // Search, Sort, and Pagination for Transactions
  String _searchQuery = '';
  String _sortColumn = 'paymentTime'; // 'bookingId', 'patientName', 'doctorName', 'paymentTime', 'discountAmount', 'totalAmount'
  bool _sortAscending = false;
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Getters
  RevenueReport? get report => _report;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  String get searchQuery => _searchQuery;
  String get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;

  String get startDateString => _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '';
  String get endDateString => _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '';

  RevenueController() {
    // Default filter: current month range
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    loadReport();
  }

  // Update date range
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _currentPage = 1; // Reset pagination
    notifyListeners();
  }

  // Load report data from backend
  Future<void> loadReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _repository.getRevenueReport(
        startDate: startDateString,
        endDate: endDateString,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
  }

  // Set sort column and order
  void sort(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    notifyListeners();
  }

  // Page navigation
  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  // Filtered and sorted transactions
  List<RevenueTransaction> get filteredTransactions {
    if (_report == null) return [];

    List<RevenueTransaction> list = List.from(_report!.transactions);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((t) {
        return t.bookingId.toLowerCase().contains(query) ||
            t.patientName.toLowerCase().contains(query) ||
            t.doctorName.toLowerCase().contains(query) ||
            t.paymentMethod.toLowerCase().contains(query);
      }).toList();
    }

    // Sort list
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case 'bookingId':
          cmp = a.bookingId.compareTo(b.bookingId);
          break;
        case 'patientName':
          cmp = a.patientName.compareTo(b.patientName);
          break;
        case 'doctorName':
          cmp = a.doctorName.compareTo(b.doctorName);
          break;
        case 'paymentTime':
          cmp = a.paymentTime.compareTo(b.paymentTime);
          break;
        case 'discountAmount':
          cmp = a.discountAmount.compareTo(b.discountAmount);
          break;
        case 'totalAmount':
          cmp = a.totalAmount.compareTo(b.totalAmount);
          break;
        default:
          cmp = a.paymentTime.compareTo(b.paymentTime);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  // Paginated transactions
  List<RevenueTransaction> get paginatedTransactions {
    final list = filteredTransactions;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= list.length) return [];
    final endIndex = startIndex + _itemsPerPage;
    return list.sublist(
      startIndex,
      endIndex > list.length ? list.length : endIndex,
    );
  }

  int get totalPages {
    final count = filteredTransactions.length;
    if (count == 0) return 1;
    return (count / _itemsPerPage).ceil();
  }
}
