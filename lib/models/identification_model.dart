import 'package:hive/hive.dart';

part 'identification_model.g.dart';

@HiveType(typeId: 1)
class IdentificationModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imageUrl;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final String type; // 'flora' atau 'fauna'

  @HiveField(4)
  final String commonName;

  @HiveField(5)
  final String scientificName;

  @HiveField(6)
  final double confidenceLevel;

  @HiveField(7)
  final String description;

  @HiveField(8)
  final String habitat;

  @HiveField(9)
  final Map<String, String> taxonomy;

  @HiveField(10)
  final String conservationStatus;

  @HiveField(11)
  final bool hasQuiz;

  IdentificationModel({
    required this.id,
    required this.imageUrl,
    required this.type,
    required this.commonName,
    required this.scientificName,
    required this.confidenceLevel,
    required this.description,
    required this.habitat,
    required this.taxonomy,
    required this.conservationStatus,
    DateTime? createdAt,
    this.hasQuiz = false,
  }) : createdAt = createdAt ?? DateTime.now();

  IdentificationModel copyWith({
    String? id,
    String? imageUrl,
    String? type,
    String? commonName,
    String? scientificName,
    double? confidenceLevel,
    String? description,
    String? habitat,
    Map<String, String>? taxonomy,
    String? conservationStatus,
    DateTime? createdAt,
    bool? hasQuiz,
  }) {
    return IdentificationModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      commonName: commonName ?? this.commonName,
      scientificName: scientificName ?? this.scientificName,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      description: description ?? this.description,
      habitat: habitat ?? this.habitat,
      taxonomy: taxonomy ?? this.taxonomy,
      conservationStatus: conservationStatus ?? this.conservationStatus,
      createdAt: createdAt ?? this.createdAt,
      hasQuiz: hasQuiz ?? this.hasQuiz,
    );
  }
} 