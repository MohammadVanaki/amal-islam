class SliderModel {
  final String id;
  final String? title;
  final String? description;
  final String imageUrl;
  final String? link;
  final String? bookId;
  final String? actionText;

  const SliderModel({
    required this.id,
    this.title,
    this.description,
    required this.imageUrl,
    this.link,
    this.bookId,
    this.actionText,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    final idVal = (json['id'] ?? json['id_show'] ?? json['_id'] ?? '').toString();

    final rawImage = json['photo_url'] ??
        json['image'] ??
        json['image_url'] ??
        json['photo'] ??
        json['banner'] ??
        json['cover'] ??
        json['thumbnail'] ??
        '';

    String img = rawImage.toString().trim();
    if (img.isNotEmpty && !img.startsWith('http')) {
      img = 'https://library.dijlah.org/upload_list/source/$img';
    }

    final rawLink = json['link'] ??
        json['url'] ??
        json['link_url'] ??
        json['target_url'] ??
        json['web_url'] ??
        json['href'] ??
        json['action_url'];

    return SliderModel(
      id: idVal,
      title: json['title']?.toString() ?? json['name']?.toString(),
      description: json['description']?.toString() ??
          json['subtitle']?.toString() ??
          json['content']?.toString(),
      imageUrl: img,
      link: rawLink?.toString().trim(),
      bookId: (json['book_id'] ?? json['bookId'] ?? json['book'])?.toString(),
      actionText: json['action_text']?.toString() ?? json['btn_text']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'link': link,
      'bookId': bookId,
      'actionText': actionText,
    };
  }
}

