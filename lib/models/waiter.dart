class Waiter {
  final String name;
  final String mobileNo;
  final String username;
  final String password;

  Waiter({
    required this.name,
    required this.mobileNo,
    required this.username,
    required this.password,
  });

  factory Waiter.fromMap(Map<String, dynamic> data) {
    return Waiter(
      name: data['name'] ?? '',
      mobileNo: data['mobile no'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobile no': mobileNo,
      'username': username,
      'password': password,
    };
  }
}
