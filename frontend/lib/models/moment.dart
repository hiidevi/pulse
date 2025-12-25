class Reply {
  final int id;
  final int senderId;
  final String senderName;
  final String text;
  final String emoji;
  final DateTime createdAt;

  Reply({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.emoji,
    required this.createdAt,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'],
      senderId: json['sender']['id'],
      senderName: json['sender']['username'] ?? 'Somebody',
      text: json['text'],
      emoji: json['emoji'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Moment {
  final int id;
  final int senderId;
  final String senderName;
  final String text;
  final String emoji;
  final String? imageUrl;
  final DateTime createdAt;
  final List<Reply> replies;

  Moment({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.emoji,
    this.imageUrl,
    required this.createdAt,
    this.replies = const [],
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    var repliesList = json['replies'] as List? ?? [];
    List<Reply> replies = repliesList.map((r) => Reply.fromJson(r)).toList();

    return Moment(
      id: json['id'],
      senderId: json['sender']['id'],
      senderName: json['sender']['username'] ?? 'Somebody',
      text: json['text'],
      emoji: json['emoji'],
      imageUrl: json['image'],
      createdAt: DateTime.parse(json['created_at']),
      replies: replies,
    );
  }
}
