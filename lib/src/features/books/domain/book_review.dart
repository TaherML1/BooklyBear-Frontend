class ReviewUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int level;

  ReviewUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.level,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id'],
      username: json['username'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
    );
  }
}

class BookReview {
  final String id;
  final int? rating;
  final String? reviewText;
  final String createdAt;
  final ReviewUser user;

  BookReview({
    required this.id,
    this.rating,
    this.reviewText,
    required this.createdAt,
    required this.user,
  });

  factory BookReview.fromJson(Map<String, dynamic> json) {
    return BookReview(
      id: json['id'],
      rating: json['rating'],
      reviewText: json['reviewText'],
      createdAt: json['createdAt'],
      user: ReviewUser.fromJson(json['user']),
    );
  }
}

class PaginatedReviews {
  final List<BookReview> reviews;
  final int total;
  final int page;
  final int pages;

  PaginatedReviews({
    required this.reviews,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory PaginatedReviews.fromJson(Map<String, dynamic> json) {
    return PaginatedReviews(
      reviews: (json['reviews'] as List).map((r) => BookReview.fromJson(r)).toList(),
      total: json['total'],
      page: json['page'],
      pages: json['pages'],
    );
  }
}
