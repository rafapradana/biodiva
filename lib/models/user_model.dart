import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final int identifiedCount;

  @HiveField(3)
  final int quizCount;

  UserModel({
    required this.name,
    DateTime? createdAt,
    this.identifiedCount = 0,
    this.quizCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  UserModel copyWith({
    String? name,
    DateTime? createdAt,
    int? identifiedCount,
    int? quizCount,
  }) {
    return UserModel(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      identifiedCount: identifiedCount ?? this.identifiedCount,
      quizCount: quizCount ?? this.quizCount,
    );
  }
} 