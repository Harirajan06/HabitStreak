import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/habit.dart';
import '../models/note.dart';
import '../models/user.dart';

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return Habit.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 1;

  @override
  Note read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return Note.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class AppUserAdapter extends TypeAdapter<AppUser> {
  @override
  final int typeId = 2;

  @override
  AppUser read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AppUser.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, AppUser obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class SettingsAdapter extends TypeAdapter<Map<String, dynamic>> {
  @override
  final int typeId = 3;

  @override
  Map<String, dynamic> read(BinaryReader reader) {
    final jsonStr = reader.readString();
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  @override
  void write(BinaryWriter writer, Map<String, dynamic> obj) {
    writer.writeString(jsonEncode(obj));
  }
}
