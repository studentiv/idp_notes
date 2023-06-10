import 'package:hive_flutter/hive_flutter.dart';
import 'package:idp_notes/db/db.dart';
import 'package:idp_notes/repository.dart';

class RepositoryImpl implements DatabaseRepository {
  static const _notatesKey = 'notates';
  final Box<Notate> _box = Hive.box<Notate>(_notatesKey);

  @override
  Future<void> addNotate(Notate notate) async {
    await _box.add(notate);
  }

  @override
  Future<void> deleteNotate(Notate notate) async {
    await notate.delete();
  }

  @override
  Future<List<Notate>> fetchNotate() async {
    return _box.values.toList();
  }

  @override
  Future<void> updateNotate(Notate notate) async {
    try {
      final currentNotate = _box.values.firstWhere((n) => n.id == notate.id);
      await _box.put(currentNotate.key, notate);
    } catch (error) {
      throw HiveError('Notate with id ${notate.id} does not exist');
    }
  }
}
