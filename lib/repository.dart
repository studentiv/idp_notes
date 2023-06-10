import 'db/db.dart';

abstract class DatabaseRepository {
  Future<void> addNotate(Notate notate);

  Future<void> updateNotate(Notate notate);

  Future<void> deleteNotate(Notate notate);

  Future<List<Notate>> fetchNotate();
}
