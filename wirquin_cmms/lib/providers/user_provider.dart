import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole {
  admin,
  operator,
  none,
}

class UserProvider extends ChangeNotifier {
  UserRole _currentRole = UserRole.none;
  bool _isAuthenticated = false;
  
  UserRole get currentRole => _currentRole;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentRole == UserRole.admin;
  bool get isOperator => _currentRole == UserRole.operator;
  
  UserProvider() {
    _loadUserRole();
  }
  
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString('user_role');
    
    debugPrint('Loading user role, stored value: $roleString');
    
    if (roleString != null) {
      _currentRole = UserRole.values.firstWhere(
        (role) => role.toString() == roleString,
        orElse: () => UserRole.none,
      );
      _isAuthenticated = _currentRole != UserRole.none;
      debugPrint('User role set to: $_currentRole, isAuthenticated: $_isAuthenticated');
      notifyListeners();
    }
  }
  
  Future<void> setUserRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = role.toString();
    debugPrint('Setting user role to: $roleString');
    
    await prefs.setString('user_role', roleString);
    
    _currentRole = role;
    _isAuthenticated = role != UserRole.none;
    debugPrint('User role updated: $_currentRole, isAuthenticated: $_isAuthenticated');
    notifyListeners();
  }
  
  Future<void> logout() async {
    debugPrint('Logging out user');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    
    _currentRole = UserRole.none;
    _isAuthenticated = false;
    debugPrint('User logged out, role reset to: $_currentRole');
    notifyListeners();
  }
} 