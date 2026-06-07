import 'package:flutter/material.dart';
import 'user_role_model.dart';
import 'role_management_repository.dart';

class RoleManagementController extends ChangeNotifier {
  final RoleManagementRepository _repository = RoleManagementRepository();

  List<UserRoleModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _roleFilter = 'Tất cả'; // 'Tất cả', 'Admin', 'Staff', 'Doctor', 'Patient'

  // Getters
  List<UserRoleModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get roleFilter => _roleFilter;

  // Filtered list based on search query and role filter chip
  List<UserRoleModel> get filteredUsers {
    List<UserRoleModel> list = List.from(_users);

    // Apply role filter chip
    if (_roleFilter != 'Tất cả') {
      final filterLower = _roleFilter.toLowerCase();
      list = list.where((u) => u.role.toLowerCase() == filterLower).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((u) {
        return u.fullName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            u.id.toString() == query;
      }).toList();
    }

    return list;
  }

  // Load all users
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _repository.getUsers();
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
    notifyListeners();
  }

  // Set role filter chip
  void setRoleFilter(String filter) {
    _roleFilter = filter;
    notifyListeners();
  }

  // Save role to database
  Future<void> saveUserRole(int userId, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _repository.updateUserRole(userId, role);
      // Update local list
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
