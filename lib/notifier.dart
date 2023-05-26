import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'db.dart';

class NotateProvider extends ChangeNotifier {
  static const _notatesKey = 'notates';
  final Box<Notate> _box = Hive.box<Notate>(_notatesKey);

  List<Notate> _notates = [];

  List<Notate> get notates => _notates;

  NotateProvider() {
    fetchNotate();
  }

  Future<void> addNotate({
    required String title,
    required String content,
  }) async {
    final notate = Notate(title: title, content: content);

    await _box.add(notate);
    _notates.add(notate);
    notifyListeners();
  }

  Future<void> updateNotate(Notate notate) async {
    try {
      final currentNotate = _box.values.firstWhere((n) => n.id == notate.id);
      await _box.put(currentNotate.key, notate);
      fetchNotate();
    } catch (error) {
      throw HiveError('Notate with id ${notate.id} does not exist');
    }
  }

  Future<void> deleteNotate(Notate notate) async {
    await notate.delete();
    _notates.remove(notate);
    notifyListeners();
  }

  Future<void> fetchNotate() async {
    _notates = _box.values.toList();
    notifyListeners();
  }
}
