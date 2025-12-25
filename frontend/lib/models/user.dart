class User {
  final int id;
  final String username;
  final String email;
  final String avatarEmoji;
  final String inviteId;
  final String? connectionStatus; // NONE, PENDING, ACCEPTED
  final List<dynamic>? profilePhotos;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarEmoji,
    required this.inviteId,
    this.connectionStatus,
    this.profilePhotos,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      avatarEmoji: json['avatar_emoji'],
      inviteId: json['invite_id'] ?? '',
      connectionStatus: json['connection_status'],
      profilePhotos: json['profile_photos'],
    );
  }
}
