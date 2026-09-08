class Question {
  final String id;
  final String userId;
  final String? chapterId;
  final String? lessonId;
  final String question;
  final String? imageUrl;
  final String? answer;
  final bool answered;
  final String? teacherAdminId;
  final DateTime createdAt;

  const Question({
    required this.id,
    required this.userId,
    this.chapterId,
    this.lessonId,
    required this.question,
    this.imageUrl,
    this.answer,
    required this.answered,
    this.teacherAdminId,
    required this.createdAt,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    final raw = map['created_at']?.toString();
    return Question(
      id: '${map['id'] ?? ''}',
      userId: '${map['user_id'] ?? ''}',
      chapterId: map['chapter_id']?.toString(),
      lessonId: map['lesson_id']?.toString(),
      question: '${map['question'] ?? ''}',
      imageUrl: map['image_url']?.toString(),
      answer: map['answer']?.toString(),
      answered: map['answered'] == true,
      teacherAdminId: map['teacher_admin_id']?.toString(),
      createdAt: raw == null ? DateTime.now() : DateTime.tryParse(raw) ?? DateTime.now(),
    );
  }
}
