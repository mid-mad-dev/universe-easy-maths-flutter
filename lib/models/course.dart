class Course {
  final String id;
  final String name;
  final String description;
  final String? thumbnailUrl;
  final double price;
  final bool premium;
  final bool published;

  const Course({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnailUrl,
    required this.price,
    required this.premium,
    required this.published,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: '${map['id'] ?? ''}',
      name: '${map['course_name'] ?? ''}',
      description: '${map['description'] ?? ''}',
      thumbnailUrl: map['thumbnail_url']?.toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      premium: map['premium'] == true,
      published: map['published'] != false,
    );
  }
}
