import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────
class JournalItem {
  JournalItem({
    required this.id,
    required this.title,
    required this.content,
    this.isPinned = false,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  String title;
  String content;
  bool isPinned;
  final DateTime createdAt;
  DateTime updatedAt;
}

// ─────────────────────────────────────────────────────────
// Journal Screen
// ─────────────────────────────────────────────────────────
class JournalScreen extends StatefulWidget {
  const JournalScreen({
    super.key,
    required this.journals,
    required this.onJournalsChanged,
    required this.onBack,
  });

  final List<JournalItem> journals;
  final ValueChanged<List<JournalItem>> onJournalsChanged;
  final VoidCallback onBack;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const String _fontAlt = 'MontserratAlternates';
  static const Color _dustLavender = AppColors.dustLavender;
  static const Color _cardBg = Color(0xFF0D1240);

  late List<JournalItem> _journals;

  @override
  void initState() {
    super.initState();
    _journals = List<JournalItem>.from(widget.journals);
    _sort();
  }

  void _sort() {
    _journals.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  void _sync() => widget.onJournalsChanged(List<JournalItem>.from(_journals));

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  Future<void> _openJournal({JournalItem? journal}) async {
    final result = await Navigator.of(context).push<JournalItem?>(
      MaterialPageRoute(builder: (_) => JournalDetailScreen(journal: journal)),
    );
    if (result != null) {
      setState(() {
        if (journal == null) {
          _journals.insert(0, result);
        } else {
          final idx = _journals.indexWhere((j) => j.id == result.id);
          if (idx >= 0) _journals[idx] = result;
        }
        _sort();
      });
      _sync();
    }
  }

  Future<void> _deleteJournal(JournalItem journal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jurnal', style: TextStyle(fontFamily: 'Caudex', color: AppColors.moonCream, fontSize: 18)),
        content: const Text('Yakin ingin menghapus jurnal ini?', style: TextStyle(fontFamily: _fontAlt, color: AppColors.dustLavender, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: AppColors.dustLavender))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Color(0xFFFF7A7A)))),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _journals.removeWhere((j) => j.id == journal.id));
      _sync();
    }
  }

  void _togglePin(JournalItem journal) {
    setState(() {
      journal.isPinned = !journal.isPinned;
      _sort();
    });
    _sync();
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _dustLavender.withValues(alpha: 0.55)),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontFamily: _fontAlt, fontSize: 11, color: _dustLavender.withValues(alpha: 0.55))),
      ],
    );
  }

  Widget _buildJournalCard(JournalItem journal) {
    return Dismissible(
      key: Key(journal.id),
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
      confirmDismiss: (_) async { await _deleteJournal(journal); return false; },
      child: GestureDetector(
        onTap: () => _openJournal(journal: journal),
        onLongPress: () => _togglePin(journal),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: journal.isPinned
                ? Border.all(color: _dustLavender.withValues(alpha: 0.20), width: 1)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.book_outlined, size: 18, color: AppColors.dustLavender),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journal.title.isEmpty ? '(tanpa judul)' : journal.title,
                      style: const TextStyle(fontFamily: _fontAlt, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.moonCream),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (journal.content.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        journal.content,
                        style: TextStyle(fontFamily: _fontAlt, fontSize: 11, color: _dustLavender, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(journal.updatedAt),
                      style: TextStyle(fontFamily: _fontAlt, fontSize: 10, color: _dustLavender.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              journal.isPinned
                  ? const Icon(Icons.push_pin_rounded, size: 15, color: AppColors.dustLavender)
                  : const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.dustLavender),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJournalList() {
    final pinned = _journals.where((j) => j.isPinned).toList();
    final unpinned = _journals.where((j) => !j.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (pinned.isNotEmpty) ...[
          _buildSectionLabel('Disematkan', Icons.push_pin_rounded),
          const SizedBox(height: 8),
          for (final j in pinned) ...[_buildJournalCard(j), const SizedBox(height: 10)],
        ],
        if (unpinned.isNotEmpty) ...[
          if (pinned.isNotEmpty) const SizedBox(height: 4),
          _buildSectionLabel('Jurnal', Icons.book_outlined),
          const SizedBox(height: 8),
          for (final j in unpinned) ...[_buildJournalCard(j), const SizedBox(height: 10)],
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
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.moonCream),
                      ),
                      const Expanded(
                        child: Text('Journal', style: TextStyle(fontFamily: 'Caudex', fontSize: 22, color: AppColors.moonCream)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 4),
                  child: Text(
                    'Tekan lama untuk sematkan',
                    style: TextStyle(fontFamily: _fontAlt, fontSize: 10, color: _dustLavender.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _journals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.book_outlined, size: 48, color: _dustLavender.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('belum ada jurnal', style: TextStyle(fontFamily: _fontAlt, fontSize: 13, color: AppColors.dustLavender)),
                            ],
                          ),
                        )
                      : _buildJournalList(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _openJournal(),
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.loginButton,
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Journal Detail Screen
// ─────────────────────────────────────────────────────────
class JournalDetailScreen extends StatefulWidget {
  const JournalDetailScreen({super.key, this.journal});
  final JournalItem? journal;

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final DateTime _createdAt;
  DateTime? _updatedAt;
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.journal?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.journal?.content ?? '');
    _createdAt = widget.journal?.createdAt ?? DateTime.now();
    _updatedAt = widget.journal?.updatedAt;
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
    const months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  void _save() {
    final now = DateTime.now();
    Navigator.of(context).pop(JournalItem(
      id: widget.journal?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      createdAt: _createdAt,
      updatedAt: now,
      isPinned: widget.journal?.isPinned ?? false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.journal == null;
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
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.moonCream),
                      ),
                      Expanded(
                        child: Text(
                          isNew ? 'Jurnal Baru' : 'Edit Jurnal',
                          style: const TextStyle(fontFamily: 'Caudex', fontSize: 20, color: AppColors.moonCream),
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
                            child: const Text('Simpan', style: TextStyle(fontFamily: 'MontserratAlternates', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isNew) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: AppColors.dustLavender.withValues(alpha: 0.6)),
                        const SizedBox(width: 5),
                        Text(
                          'Diubah ${_formatFull(_updatedAt ?? _createdAt)}',
                          style: TextStyle(fontFamily: 'MontserratAlternates', fontSize: 10, color: AppColors.dustLavender.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(height: 1, thickness: 1, color: AppColors.dustLavender.withValues(alpha: 0.12), indent: 20, endIndent: 20),
                  const SizedBox(height: 4),
                ],
                if (isNew) const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _titleCtrl,
                    cursorColor: AppColors.loginBlueStart,
                    style: const TextStyle(fontFamily: 'Caudex', fontSize: 22, color: AppColors.moonCream, height: 1.3),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Judul jurnal...',
                      hintStyle: TextStyle(fontFamily: 'Caudex', fontSize: 22, color: AppColors.dustLavender.withValues(alpha: 0.4), height: 1.3),
                      isCollapsed: true,
                    ),
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _contentCtrl,
                      cursorColor: AppColors.loginBlueStart,
                      style: const TextStyle(fontFamily: 'MontserratAlternates', fontSize: 14, color: AppColors.moonCream, height: 1.6),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Tulis jurnal hari ini...',
                        hintStyle: TextStyle(fontFamily: 'MontserratAlternates', fontSize: 14, color: AppColors.dustLavender.withValues(alpha: 0.4), height: 1.6),
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
