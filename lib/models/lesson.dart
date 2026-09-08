class Lesson {
  final String id;
  final String chapterId;
  final int number;
  final String title;
  final String description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final bool published;
  final bool premium;

  const Lesson({
    required this.id,
    required this.chapterId,
    required this.number,
    required this.title,
    required this.description,
    this.videoUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    required this.published,
    required this.premium,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: '${map['id'] ?? ''}',
      chapterId: '${map['chapter_id'] ?? ''}',
      number: (map['lesson_number'] as num?)?.toInt() ?? 0,
      title: '${map['title'] ?? ''}',
      description: '${map['description'] ?? ''}',
      videoUrl: map['video_url']?.toString(),
      thumbnailUrl: map['thumbnail_url']?.toString(),
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      published: map['published'] != false,
      premium: map['premium'] == true,
    );
  }
}
