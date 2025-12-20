import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/hive_service.dart';

class NoteProvider with ChangeNotifier {
  final List<Note> _notes = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  NoteProvider() {
    loadNotes();
  }
  
  Future<void> loadNotes() async {
    if (_isLoading) return; // Prevent concurrent loads
    
    try {
      _isLoading = true;
      _errorMessage = null;
      
      final notes = HiveService.instance.getNotes();
      _notes.clear();
      _notes.addAll(notes);
      _isLoading = false;
      
      // Only notify if we have a widget tree
      if (WidgetsBinding.instance.isRootWidgetAttached) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
      // If database table doesn't exist, use mock service or empty state
      if (e.toString().contains('PGRST205') || e.toString().contains('table') || e.toString().contains('notes')) {
        debugPrint('Notes table not found, using empty state');
        _notes.clear(); // Start with empty notes
      } else {
        _errorMessage = 'Failed to load notes: $e';
      }
      _isLoading = false;
      
      if (WidgetsBinding.instance.isRootWidgetAttached) {
        notifyListeners();
      }
    }
  }
  
  Future<void> addNote(Note note) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      debugPrint('Adding note: ${note.title}');
      await HiveService.instance.addNote(note);
      _notes.insert(0, note); // Add to beginning for newest first
      debugPrint('Note added successfully: ${note.id}');
    } catch (e) {
      _errorMessage = 'Failed to add note: $e';
      debugPrint('Error adding note: $e');
      // Add locally as fallback
      _notes.insert(0, note);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateNote(Note note) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await HiveService.instance.updateNote(note);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
      }
    } catch (e) {
      _errorMessage = 'Failed to update note: $e';
      debugPrint('Error updating note: $e');
      // Update locally as fallback
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> deleteNote(String noteId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await HiveService.instance.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
    } catch (e) {
      _errorMessage = 'Failed to delete note: $e';
      debugPrint('Error deleting note: $e');
      // Delete locally as fallback
      _notes.removeWhere((note) => note.id == noteId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<Note>> searchNotes(String query) async {
    try {
      final searchQuery = query.toLowerCase();
      return _notes.where((note) {
        return note.title.toLowerCase().contains(searchQuery) ||
               note.content.toLowerCase().contains(searchQuery) ||
               (note.habitName?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    } catch (e) {
      _errorMessage = 'Failed to search notes: $e';
      debugPrint('Error searching notes: $e');
      return [];
    }
  }
  
  Future<List<Note>> getNotesForHabit(String habitId) async {
    try {
      final notes = HiveService.instance.getNotesForHabit(habitId);
      return notes;
    } catch (e) {
      _errorMessage = 'Failed to load habit notes: $e';
      debugPrint('Error loading habit notes: $e');
      return _notes.where((note) => note.habitId == habitId).toList();
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
