import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'db.g.dart';

@HiveType(typeId: 0)
class Notate extends HiveObject {
  @HiveField(0)
  final String _id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  Notate({
    String? id,
    required this.title,
    required this.content,
  }) : _id = id ?? const Uuid().v4();

  String get id => _id;

  Notate copyWith({String? title, String? content}) => Notate(
        title: title ?? this.title,
        content: content ?? this.content,
        id: id,
      );
}
