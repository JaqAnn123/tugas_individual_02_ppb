import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────
class NoteItem {
  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  String title;
  String content;
  bool isPinned;
  final DateTime createdAt;
  DateTime updatedAt;
}

// ─────────────────────────────────────────────────────────
// Notes list screen
// ─────────────────────────────────────────────────────────
class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.notes,
    required this.onNotesChanged,
    required this.onBack,
  });

  final List<NoteItem> notes;
  final ValueChanged<List<NoteItem>> onNotesChanged;
  final VoidCallback onBack;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const String _fontAlt = 'MontserratAlternates';
  static const Color _dustLavender = AppColors.dustLavender;
  static const Color _cardBg = Color(0xFF0D1240);

  late List<NoteItem> _notes;

  @override
  void initState() {
    super.initState();
    _notes = List<NoteItem>.from(widget.notes);
    _sort();
  }

  void _sort() {
    _notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  void _syncToParent() => widget.onNotesChanged(List<NoteItem>.from(_notes));

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openNote({NoteItem? note}) async {
    final result = await Navigator.of(context).push<NoteItem?>(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
    if (result != null) {
      setState(() {
        if (note == null) {
          _notes.insert(0, result);
        } else {
          final idx = _notes.indexWhere((n) => n.id == result.id);
          if (idx >= 0) _notes[idx] = result;
        }
        _sort();
      });
      _syncToParent();
    }
  }

  Future<void> _deleteNote(NoteItem note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Catatan',
          style: TextStyle(fontFamily: 'Caudex', color: AppColors.moonCream, fontSize: 18),
        ),
        content: const Text(
          'Yakin ingin menghapus catatan ini?',
          style: TextStyle(fontFamily: _fontAlt, color: AppColors.dustLavender, fontSize: 13),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.dustLavender)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFFF7A7A))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _notes.removeWhere((n) => n.id == note.id));
      _syncToParent();
    }
  }

  void _togglePin(NoteItem note) {
    setState(() {
      note.isPinned = !note.isPinned;
      _sort();
    });
    _syncToParent();
  }

  // ── Build helpers ──────────────────────────────────────

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 12, color: _dustLavender.withValues(alpha: 0.55)),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontFamily: _fontAlt,
            fontSize: 11,
            color: _dustLavender.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(NoteItem note) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A7A).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF7A7A), size: 22),
      ),
      confirmDismiss: (_) async {
        await _deleteNote(note);
        return false;
      },
      child: GestureDetector(
        onTap: () => _openNote(note: note),
        onLongPress: () => _togglePin(note),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: note.isPinned
                ? Border.all(color: _dustLavender.withValues(alpha: 0.20), width: 1)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.sticky_note_2_outlined, size: 18, color: AppColors.dustLavender),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      note.title.isEmpty ? '(tanpa judul)' : note.title,
                      style: const TextStyle(
                        fontFamily: _fontAlt,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.moonCream,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.content.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        note.content,
                        style: TextStyle(
                          fontFamily: _fontAlt,
                          fontSize: 11,
                          color: _dustLavender,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(note.updatedAt),
                      style: TextStyle(
                        fontFamily: _fontAlt,
                        fontSize: 10,
                        color: _dustLavender.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              note.isPinned
                  ? const Icon(Icons.push_pin_rounded, size: 15, color: AppColors.dustLavender)
                  : const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.dustLavender),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    final List<NoteItem> pinned = _notes.where((n) => n.isPinned).toList();
    final List<NoteItem> unpinned = _notes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        if (pinned.isNotEmpty) ...<Widget>[
          _buildSectionLabel('Disematkan', Icons.push_pin_rounded),
          const SizedBox(height: 8),
          for (final NoteItem n in pinned) ...<Widget>[
            _buildNoteCard(n),
            const SizedBox(height: 10),
          ],
        ],
        if (unpinned.isNotEmpty) ...<Widget>[
          if (pinned.isNotEmpty) const SizedBox(height: 4),
          _buildSectionLabel('Catatan', Icons.sticky_note_2_outlined),
          const SizedBox(height: 8),
          for (final NoteItem n in unpinned) ...<Widget>[
            _buildNoteCard(n),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.nightSky),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                // App bar — no "+ Tambah" button, FAB on homepage handles creation
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.moonCream,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Notes',
                          style: TextStyle(
                            fontFamily: 'Caudex',
                            fontSize: 22,
                            color: AppColors.moonCream,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tekan lama catatan untuk menyematkan',
                    style: TextStyle(
                      fontFamily: _fontAlt,
                      fontSize: 11,
                      color: _dustLavender.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // List
                Expanded(
                  child: _notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.sticky_note_2_outlined,
                                size: 48,
                                color: _dustLavender.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'belum ada catatan',
                                style: TextStyle(
                                  fontFamily: _fontAlt,
                                  fontSize: 13,
                                  color: AppColors.dustLavender,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildNotesList(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _openNote(),
        child: Container(
          width: 52, height: 52,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.loginButton),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Note detail / edit screen
// ─────────────────────────────────────────────────────────
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, this.note});
  final NoteItem? note;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final DateTime _createdAt;
  DateTime? _updatedAt;
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
    _createdAt = widget.note?.createdAt ?? DateTime.now();
    _updatedAt = widget.note?.updatedAt;
    _titleCtrl.addListener(_onChanged);
    _contentCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() => _edited = true);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  String _formatFull(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  void _save() {
    final now = DateTime.now();
    final saved = NoteItem(
      id: widget.note?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      createdAt: _createdAt,
      updatedAt: now,
      isPinned: widget.note?.isPinned ?? false,
    );
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.note == null;
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.nightSky),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.moonCream,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isNew ? 'Catatan Baru' : 'Edit Catatan',
                          style: const TextStyle(
                            fontFamily: 'Caudex',
                            fontSize: 20,
                            color: AppColors.moonCream,
                          ),
                        ),
                      ),
                      if (_edited || isNew)
                        GestureDetector(
                          onTap: _save,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: AppColors.loginButton,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Simpan',
                              style: TextStyle(
                                fontFamily: 'MontserratAlternates',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Date info — only shown when editing an existing note
                if (!isNew) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.dustLavender.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Diubah ${_formatFull(_updatedAt ?? _createdAt)}',
                          style: TextStyle(
                            fontFamily: 'MontserratAlternates',
                            fontSize: 10,
                            color: AppColors.dustLavender.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.dustLavender.withValues(alpha: 0.12),
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 4),
                ],

                if (isNew) const SizedBox(height: 12),

                // Title field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _titleCtrl,
                    cursorColor: AppColors.loginBlueStart,
                    style: const TextStyle(
                      fontFamily: 'Caudex',
                      fontSize: 22,
                      color: AppColors.moonCream,
                      height: 1.3,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Judul...',
                      hintStyle: TextStyle(
                        fontFamily: 'Caudex',
                        fontSize: 22,
                        color: AppColors.dustLavender.withValues(alpha: 0.4),
                        height: 1.3,
                      ),
                      isCollapsed: true,
                    ),
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 8),

                // Content field
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _contentCtrl,
                      cursorColor: AppColors.loginBlueStart,
                      style: const TextStyle(
                        fontFamily: 'MontserratAlternates',
                        fontSize: 14,
                        color: AppColors.moonCream,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Tulis catatan di sini...',
                        hintStyle: TextStyle(
                          fontFamily: 'MontserratAlternates',
                          fontSize: 14,
                          color: AppColors.dustLavender.withValues(alpha: 0.4),
                          height: 1.6,
                        ),
                        isCollapsed: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
