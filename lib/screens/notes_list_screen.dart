import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_helper.dart';
import 'add_edit_note_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  String _sortBy = 'date';
  String _filterCategory = 'Todas';
  final _searchController = TextEditingController();

  static const List<Color> noteColors = [
    Color(0xFFFFF9C4), // amarillo
    Color(0xFFB2EBF2), // celeste
    Color(0xFFC8E6C9), // verde
    Color(0xFFFFCCBC), // naranja
    Color(0xFFE1BEE7), // morado
    Color(0xFFFFCDD2), // rojo
  ];

  static const List<String> categories = [
    'Todas', 'Personal', 'Trabajo', 'Estudio', 'Ideas'
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_filterNotes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await _databaseHelper.getAllNotes();
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
        _filterNotes();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) {
        final matchSearch = note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
        final matchCategory = _filterCategory == 'Todas' ||
            note.category == _filterCategory;
        return matchSearch && matchCategory;
      }).toList();

      if (_sortBy == 'date') {
        _filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } else if (_sortBy == 'alpha') {
        _filteredNotes.sort((a, b) => a.title.compareTo(b.title));
      } else if (_sortBy == 'favorites') {
        _filteredNotes.sort((a, b) => b.isFavorite ? 1 : -1);
      }
    });
  }

  Future<void> _deleteNote(int id) async {
    await _databaseHelper.deleteNote(id);
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota eliminada'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleFavorite(Note note) async {
    note.isFavorite = !note.isFavorite;
    await _databaseHelper.updateNote(note);
    _loadNotes();
  }

  void _showDeleteDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Estás seguro de que quieres eliminar esta nota?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteNote(note.id!); },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _notes.where((n) => n.isFavorite).length;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          title: const Text('📝 Mis Notas', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (val) { setState(() => _sortBy = val); _filterNotes(); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'date', child: Text('📅 Por fecha')),
                const PopupMenuItem(value: 'alpha', child: Text('🔤 Alfabético')),
                const PopupMenuItem(value: 'favorites', child: Text('⭐ Favoritos primero')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Stats bar
            Container(
              color: Colors.green[700],
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _statChip('📋 ${_notes.length} notas'),
                  const SizedBox(width: 8),
                  _statChip('⭐ $favorites favoritos'),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar notas...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _filterNotes(); })
                      : null,
                ),
              ),
            ),
            // Category filter
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final selected = _filterCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) { setState(() => _filterCategory = cat); _filterNotes(); },
                      selectedColor: Colors.green[300],
                      backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Notes list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredNotes.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _notes.isEmpty ? 'No hay notas.\nToca + para crear una.' : 'No se encontraron notas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadNotes,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filteredNotes.length,
                  itemBuilder: (_, index) {
                    final note = _filteredNotes[index];
                    final color = noteColors[note.colorIndex % noteColors.length];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: _isDarkMode ? Colors.grey[800] : color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[700],
                          child: Text(note.title[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                            if (note.isFavorite) const Icon(Icons.star, color: Colors.amber, size: 18),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(note.category, style: TextStyle(fontSize: 11, color: Colors.green[800])),
                                ),
                                const SizedBox(width: 8),
                                Text(_formatDate(note.updatedAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => AddEditNoteScreen(note: note),
                              )).then((_) => _loadNotes());
                            } else if (value == 'delete') {
                              _showDeleteDialog(note);
                            } else if (value == 'favorite') {
                              _toggleFavorite(note);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'favorite', child: Row(children: [Icon(note.isFavorite ? Icons.star_border : Icons.star, color: Colors.amber), const SizedBox(width: 8), Text(note.isFavorite ? 'Quitar favorito' : 'Favorito')])),
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Editar')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddEditNoteScreen(note: note),
                          )).then((_) => _loadNotes());
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AddEditNoteScreen(),
            )).then((_) => _loadNotes());
          },
          backgroundColor: Colors.green[700],
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nueva nota', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _statChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}