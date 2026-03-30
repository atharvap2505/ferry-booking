class AuthService {
  String? _currentUser;

  Future<String?> signInWithEmail(String email, String password) async {
    if (email.isNotEmpty && password.isNotEmpty) {
      _currentUser = email;
      return _currentUser;
    }
    return null;
  }

  Future<String?> signUpWithEmail(String email, String password) async {
    if (email.isNotEmpty && password.isNotEmpty) {
      _currentUser = email;
      return _currentUser;
    }
    return null;
  }

  void signOut() {
    _currentUser = null;
  }

  String? getCurrentUser() {
    return _currentUser;
  }
}

