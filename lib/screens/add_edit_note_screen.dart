import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/database_helper.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isSaving = false;
  bool _isFavorite = false;
  String _category = 'Personal';
  int _colorIndex = 0;

  static const List<Color> noteColors = [
    Color(0xFFFFF9C4),
    Color(0xFFB2EBF2),
    Color(0xFFC8E6C9),
    Color(0xFFFFCCBC),
    Color(0xFFE1BEE7),
    Color(0xFFFFCDD2),
  ];

  static const List<String> categories = [
    'Personal', 'Trabajo', 'Estudio', 'Ideas'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _isFavorite = widget.note!.isFavorite;
      _category = widget.note!.category;
      _colorIndex = widget.note!.colorIndex;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      isFavorite: _isFavorite,
      category: _category,
      colorIndex: _colorIndex,
    );

    try {
      if (widget.note == null) {
        await _databaseHelper.insertNote(note);
      } else {
        await _databaseHelper.updateNote(note);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.note == null ? '✅ Nota creada' : '✅ Nota actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _shareNote() {
    final text = '${_titleController.text}\n\n${_contentController.text}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📋 Nota copiada al portapapeles'), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = noteColors[_colorIndex];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Text(widget.note == null ? '✏️ Nueva Nota' : '✏️ Editar Nota'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: Colors.amber),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareNote,
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveNote,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Color picker
              Row(
                children: [
                  const Text('Color: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List.generate(noteColors.length, (i) => GestureDetector(
                    onTap: () => setState(() => _colorIndex = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: noteColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colorIndex == i ? Colors.green[700]! : Colors.grey,
                          width: _colorIndex == i ? 3 : 1,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              // Category selector
              Row(
                children: [
                  const Text('Categoría: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _category,
                    underline: Container(height: 2, color: Colors.green),
                    items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  filled: true,
                  fillColor: Colors.white70,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Por favor ingresa un título' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              // Content
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Contenido',
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Por favor ingresa el contenido' : null,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save),
                  label: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.note == null ? 'Crear Nota' : 'Actualizar Nota', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}