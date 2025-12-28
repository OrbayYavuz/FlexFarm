class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['user_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      avatarUrl: json['avatar_url'],
    );
  }

  // Supabase Auth User'dan User'a dönüştürme
  factory User.fromSupabaseAuth(Map<String, dynamic> authUser) {
    return User(
      id: authUser['id'] ?? '',
      email: authUser['email'] ?? '',
      name: authUser['user_metadata']?['name'] ?? authUser['email']?.split('@')[0] ?? '',
      createdAt: DateTime.parse(authUser['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: authUser['updated_at'] != null ? DateTime.parse(authUser['updated_at']) : null,
      avatarUrl: authUser['user_metadata']?['avatar_url'],
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

