class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final int bookCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.bookCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? json['id_show'] ?? json['_id'] ?? '').toString(),
      name: json['title'] ?? json['name'] ?? 'عام',
      icon: json['logo'] ?? json['icon'],
      bookCount: json['books_count'] ?? json['bookCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'bookCount': bookCount,
    };
  }
}
