class UserModel {
  final String? id;
  final String? username;
  final String? email;
  final String? token;
  final String? refreshToken;
  final bool isAdmin;

  const UserModel({
    this.id,
    this.username,
    this.email,
    this.token,
    this.refreshToken,
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final nestedUser =
        json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : null;
    final source = nestedUser ?? json;

    return UserModel(
      id: (source['_id'] ?? source['id'])?.toString(),
      username: source['username']?.toString(),
      email: source['email']?.toString(),
      token: (json['token'] ?? source['token'])?.toString(),
      refreshToken:
          (json['refreshToken'] ?? source['refreshToken'])?.toString(),
      isAdmin: source['isAdmin'] == true || source['is_admin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (token != null) 'token': token,
      if (refreshToken != null) 'refreshToken': refreshToken,
      'isAdmin': isAdmin,
    };
  }
}
