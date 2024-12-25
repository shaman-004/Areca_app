class AuthService {
  final String _username = 'farmer';
  final String _password = 'password';

  bool login(String username, String password) {
    return username == _username && password == _password;
  }
}
