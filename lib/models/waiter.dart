class Waiter {
  final String name;
  final String mobileNo;
  final String username;
  final String password;

  /// When false, waiter cannot log in or use device auto-login.
  final bool active;

  Waiter({
    required this.name,
    required this.mobileNo,
    required this.username,
    required this.password,
    this.active = true,
  });

  factory Waiter.fromMap(Map<String, dynamic> data) {
    return Waiter(
      name: data['name'] ?? '',
      mobileNo: data['mobile no'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      active: data['active'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobile no': mobileNo,
      'username': username,
      'password': password,
      'active': active,
    };
  }
}
