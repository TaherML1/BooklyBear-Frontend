class BookList {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> bookIds;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookList({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.bookIds,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookList.fromJson(Map<String, dynamic> json) {
    return BookList(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      ownerId: json['ownerId'] as String,
      bookIds: (json['bookIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'bookIds': bookIds,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}