class Note {
  int? id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  bool isFavorite;
  String category;
  int colorIndex;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.category = 'Personal',
    this.colorIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
      'category': category,
      'colorIndex': colorIndex,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      category: map['category'] ?? 'Personal',
      colorIndex: map['colorIndex'] ?? 0,
    );
  }
}