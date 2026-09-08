class Chapter {
  final String id;
  final int number;
  final String name;
  final String description;
  final String? thumbnailUrl;
  final int totalLessons;
  final bool published;
  final bool premium;

  const Chapter({
    required this.id,
    required this.number,
    required this.name,
    required this.description,
    this.thumbnailUrl,
    required this.totalLessons,
    required this.published,
    required this.premium,
  });

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: '${map['id'] ?? ''}',
      number: (map['chapter_number'] as num?)?.toInt() ?? 0,
      name: '${map['chapter_name'] ?? ''}',
      description: '${map['description'] ?? ''}',
      thumbnailUrl: map['thumbnail_url']?.toString(),
      totalLessons: (map['total_lessons'] as num?)?.toInt() ?? 0,
      published: map['published'] != false,
      premium: map['premium'] == true,
    );
  }
}
