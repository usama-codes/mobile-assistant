import 'package:objectbox/objectbox.dart';

@Entity()
class MemoryEntity {

  MemoryEntity({
    required this.fact, required this.importance, required this.createdAt, this.id = 0,
    this.embedding,
  });
  @Id()
  int id = 0;

  String fact;
  double importance;
  
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @HnswIndex(dimensions: 768)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;
}
