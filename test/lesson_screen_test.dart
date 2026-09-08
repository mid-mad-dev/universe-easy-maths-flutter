import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:universe_easy_maths/models/lesson.dart';
import 'package:universe_easy_maths/screens/lesson_screen.dart';

void main() {
  testWidgets('LessonScreen lays out without crashing (no video)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 850));

    final lesson = Lesson(
      id: 'lesson-1',
      chapterId: 'chapter-1',
      number: 1,
      title: 'Introduction',
      description: 'A first lesson without any uploaded video.',
      videoUrl: null,
      thumbnailUrl: null,
      durationSeconds: 60,
      published: true,
      premium: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, lessons: [lesson]),
      ),
    );
    await tester.pumpAndSettle();

    // The lesson header and bottom info panel must be visible (layout OK).
    expect(find.text('LESSON 1'), findsOneWidget);
    expect(find.text('Introduction'), findsOneWidget);
    expect(find.text('MARK AS COMPLETE'), findsOneWidget);
    expect(find.text('NEXT LESSON →'), findsOneWidget);
  });

  testWidgets('LessonScreen shows a retry instead of spinning forever',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 850));

    final lesson = Lesson(
      id: 'lesson-2',
      chapterId: 'chapter-1',
      number: 2,
      title: 'No backend',
      description: 'Supabase is not initialized in this test.',
      videoUrl: 'lesson-videos/lesson-2/1.mp4',
      thumbnailUrl: null,
      durationSeconds: 60,
      published: true,
      premium: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, lessons: [lesson]),
      ),
    );
    // Give async work time to fail and land in the error state.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.textContaining('Video error'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
  });
}
