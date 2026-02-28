import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Box? _box;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Box> get database async {
    _box ??= await _initDatabase();
    return _box!;
  }

  Future<Box> _initDatabase() async {
    return await Hive.openBox('notes');
  }

  Future<int> insertNote(Note note) async {
    try {
      final box = await database;
      // Usamos un ID pequeño basado en el conteo de notas
      final id = box.length + 1;
      final newNote = Note(
        id: id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      );
      await box.put(id, newNote.toMap());
      return id;
    } catch (e) {
      print('Error inserting note: $e');
      rethrow;
    }
  }

  Future<List<Note>> getAllNotes() async {
    try {
      final box = await database;
      final notes = box.values
          .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  Future<int> updateNote(Note note) async {
    try {
      final box = await database;
      await box.put(note.id, note.toMap());
      return 1;
    } catch (e) {
      print('Error updating note: $e');
      rethrow;
    }
  }

  Future<int> deleteNote(int id) async {
    try {
      final box = await database;
      await box.delete(id);
      return 1;
    } catch (e) {
      print('Error deleting note: $e');
      rethrow;
    }
  }
}