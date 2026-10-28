class BlogModel {
  final String? id;
  final String title;
  final String description;
  final String date;
  final String? photo;

  const BlogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.photo,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'description': description,
      'date': date,
      if (photo != null) 'photo': photo,
    };
  }
}
