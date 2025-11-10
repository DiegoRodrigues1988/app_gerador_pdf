import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotesPdfApp());
}

class NotesPdfApp extends StatelessWidget {
  const NotesPdfApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF fácil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class Note {
  final int? id;
  final String content;
  final String createdAt; // ISO string

  Note({this.id, required this.content, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {'id': id, 'content': content, 'createdAt': createdAt};
  }

  factory Note.fromMap(Map<String, dynamic> m) {
    return Note(
      id: m['id'] as int?,
      content: m['content'] as String,
      createdAt: m['createdAt'] as String,
    );
  }
}

class DbHelper {
  static Database? _db;

  static Future<Database> database() async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/notes.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      },
    );
    return _db!;
  }

  static Future<int> insertNote(Note note) async {
    final db = await database();
    return await db.insert('notes', note.toMap());
  }

  static Future<List<Note>> getAllNotes() async {
    final db = await database();
    final rows = await db.query('notes', orderBy: 'createdAt DESC');
    return rows.map((r) => Note.fromMap(r)).toList();
  }

  static Future<int> deleteNote(int id) async {
    final db = await database();
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      // On Android 11+, apps may need manage external storage - try it as fallback
      if (await Permission.manageExternalStorage.isDenied) {
        final s2 = await Permission.manageExternalStorage.request();
        return s2.isGranted;
      }
      return false;
    }
    // iOS/macOS don't require explicit storage permission for app folders
    return true;
  }

  Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      try {
        // Tenta acessar a pasta Downloads pública do Android
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) {
          return dirs.first;
        }
      } catch (e) {
        // Fallback: tenta pegar o caminho direto para Downloads
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final downloadDir = Directory('${externalDir.path}/Download');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            return downloadDir;
          }
        } catch (_) {}
      }
    }
    // Fallback para iOS ou se Android falhar
    return await getApplicationDocumentsDirectory();
  }

  Future<String?> _generateAndSavePdf(String content) async {
    setState(() => _busy = true);
    try {
      final granted = await _requestStoragePermission();
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de armazenamento negada')),
        );
        return null;
      }

      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(build: (context) => [pw.Text(content)]));

      final dir = await _getSaveDirectory();
      final now = DateTime.now();
      final filename =
          'Texto_${_two(now.day)}${_two(now.month)}${now.year}_${_two(now.hour)}${_two(now.minute)}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(await pdf.save());
      setState(() => _busy = false);
      return file.path;
    } catch (e) {
      setState(() => _busy = false);
      rethrow;
    }
  }

  Future<void> _saveAndGenerate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite algum texto antes de salvar.')),
      );
      return;
    }

    try {
      setState(() => _busy = true);
      final createdAt = DateTime.now().toIso8601String();
      final note = Note(content: text, createdAt: createdAt);
      await DbHelper.insertNote(note);

      final savedPath = await _generateAndSavePdf(text);
      if (savedPath != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF salvo em: $savedPath')));
        _controller.clear();
      }
        if (savedPath != null && mounted) {
          _showShareOptions(savedPath);
        }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

    void _showShareOptions(String filePath) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PDF Gerado com Sucesso!'),
          content: const Text('O que deseja fazer com o PDF?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Share.shareXFiles([XFile(filePath)], text: 'Confira minha anotação em PDF');
              },
              child: const Text('Compartilhar'),
            ),
          ],
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF fácil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HistoryPage())),
            tooltip: 'Histórico',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Cover image (optional) - place your cover image at assets/cover.png
            SizedBox(
              height: 180,
              child: Center(
                child: Image.asset(
                  'assets/cover.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Digite seu texto aqui...',
                ),
                textInputAction: TextInputAction.newline,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _saveAndGenerate,
                    icon: const Icon(Icons.save_alt),
                    label: _busy
                        ? const Text('Processando...')
                        : const Text('Salvar e Gerar PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _notes = await DbHelper.getAllNotes();
    setState(() => _loading = false);
  }

  String _summary(String s) {
    return s.length <= 50 ? s : '${s.substring(0, 50)}...';
  }

  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Anotações')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const Center(child: Text('Nenhuma anotação encontrada.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, i) {
                  final n = _notes[i];
                  return ListTile(
                    title: Text(_summary(n.content)),
                    subtitle: Text(_fmt(n.createdAt)),
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool?>(
                        MaterialPageRoute(
                          builder: (_) => NoteDetailPage(note: n),
                        ),
                      );
                      if (changed == true) _load();
                    },
                  );
                },
              ),
            ),
    );
  }
}

class NoteDetailPage extends StatefulWidget {
  final Note note;
  const NoteDetailPage({Key? key, required this.note}) : super(key: key);

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  bool _busy = false;

  Future<void> _regeneratePdf() async {
    setState(() => _busy = true);
    try {
      final content = widget.note.content;
      final pdfPath = await _generateAndSavePdf(content);
      if (pdfPath != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF salvo em: $pdfPath')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<String?> _generateAndSavePdf(String content) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(build: (context) => [pw.Text(content)]));
    final now = DateTime.now();
    final filename =
        'Texto_${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.pdf';
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de armazenamento negada')),
          );
          return null;
        }
      }
      
      Directory dir;
      if (Platform.isAndroid) {
        try {
          // Tenta acessar a pasta Downloads pública do Android
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          if (dirs != null && dirs.isNotEmpty) {
            dir = dirs.first;
          } else {
            // Fallback: tenta pegar o caminho direto para Downloads
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              dir = Directory('${externalDir.path}/Download');
              if (!await dir.exists()) {
                await dir.create(recursive: true);
              }
            } else {
              dir = await getApplicationDocumentsDirectory();
            }
          }
        } catch (_) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      rethrow;
    }
  }

    Future<void> _shareLastPdf() async {
      setState(() => _busy = true);
      try {
        final content = widget.note.content;
        final pdfPath = await _generateAndSavePdf(content);
        if (pdfPath != null && mounted) {
          await Share.shareXFiles(
            [XFile(pdfPath)],
            text: 'Confira minha anotação em PDF',
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e')),
        );
      } finally {
        setState(() => _busy = false);
      }
    }

  Future<void> _deleteNote() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Excluir anotação'),
          content: const Text('Deseja realmente excluir essa anotação?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await DbHelper.deleteNote(widget.note.id!);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da Anotação'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _regeneratePdf,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Gerar PDF',
          ),
            IconButton(
              onPressed: _busy ? null : _shareLastPdf,
              icon: const Icon(Icons.share),
              tooltip: 'Compartilhar PDF',
            ),
          IconButton(
            onPressed: _deleteNote,
            icon: const Icon(Icons.delete),
            tooltip: 'Excluir',
            color: Colors.red,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(child: Text(widget.note.content)),
      ),
    );
  }
}
