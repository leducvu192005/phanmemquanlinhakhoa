import 'user_role_model.dart';
import 'role_management_service.dart';

class RoleManagementRepository {
  Future<List<UserRoleModel>> getUsers() {
    return RoleManagementService.fetchUsers();
  }

  Future<UserRoleModel> updateUserRole(int userId, String role) {
    return RoleManagementService.updateUserRole(userId, role);
  }
}
