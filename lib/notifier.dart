import 'package:flutter/material.dart';

import 'db/db.dart';
import 'repository.dart';

class NotateProvider extends ChangeNotifier {
  final DatabaseRepository _db;

  List<Notate> _notates = [];

  List<Notate> get notates => _notates;

  NotateProvider(this._db) {
    fetchNotate();
  }

  Future<void> addNotate({
    required String title,
    required String content,
  }) async {
    final notate = Notate(title: title, content: content);
    _db.addNotate(notate);
    _notates.add(notate);
    notifyListeners();
  }

  Future<void> updateNotate(Notate notate) async {
    await _db.updateNotate(notate);
    fetchNotate();
  }

  Future<void> deleteNotate(Notate notate) async {
    _db.deleteNotate(notate);
    _notates.remove(notate);
    notifyListeners();
  }

  Future<void> fetchNotate() async {
    _notates = await _db.fetchNotate();
    notifyListeners();
  }
}
