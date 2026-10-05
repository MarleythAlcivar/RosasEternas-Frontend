class AuthUser {
  const AuthUser({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String password;
  final String role;

  Map<String, String> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'role': role,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    name: json['name'] as String,
    email: json['email'] as String,
    password: json['password'] as String,
    role: json['role'] as String,
  );
}
