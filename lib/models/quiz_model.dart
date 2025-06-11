import 'package:hive/hive.dart';

part 'quiz_model.g.dart';

@HiveType(typeId: 2)
class QuizModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final String identificationId;

  @HiveField(4)
  final List<QuizQuestion> questions;

  @HiveField(5)
  final String type; // 'flora' atau 'fauna'

  @HiveField(6)
  final List<QuizAttempt>? attempts;

  QuizModel({
    required this.id,
    required this.title,
    required this.identificationId,
    required this.questions,
    required this.type,
    this.attempts,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  QuizModel copyWith({
    String? id,
    String? title,
    String? identificationId,
    List<QuizQuestion>? questions,
    String? type,
    List<QuizAttempt>? attempts,
    DateTime? createdAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      identificationId: identificationId ?? this.identificationId,
      questions: questions ?? this.questions,
      type: type ?? this.type,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@HiveType(typeId: 3)
class QuizQuestion {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String question;

  @HiveField(2)
  final List<String> options;

  @HiveField(3)
  final int correctOptionIndex;

  @HiveField(4)
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });
}

@HiveType(typeId: 4)
class QuizAttempt {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime attemptDate;

  @HiveField(2)
  final int score;

  @HiveField(3)
  final int totalQuestions;

  @HiveField(4)
  final List<int> userAnswers;

  QuizAttempt({
    required this.id,
    required this.score,
    required this.totalQuestions,
    required this.userAnswers,
    DateTime? attemptDate,
  }) : attemptDate = attemptDate ?? DateTime.now();
} 