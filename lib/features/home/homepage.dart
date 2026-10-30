import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../journal/journal_page.dart';
import '../notes/notes_page.dart';
import '../todo/todo_page.dart';

// ─────────────────────────────────────────────────────────
// Unified item wrapper for combined list views
// ─────────────────────────────────────────────────────────
enum _ItemType { journal, note, todo }

class _AnyItem {
  _AnyItem({
    required this.type,
    required this.id,
    required this.title,
    required this.preview,
    required this.isPinned,
    required this.updatedAt,
    this.isDone = false,
  });

  final _ItemType type;
  final String id;
  final String title;
  final String preview;
  final bool isPinned;
  final DateTime updatedAt;
  final bool isDone;

  IconData get icon => switch (type) {
        _ItemType.journal => Icons.book_outlined,
        _ItemType.note => Icons.sticky_note_2_outlined,
        _ItemType.todo => Icons.checklist_rounded,
      };

  String get typeLabel => switch (type) {
        _ItemType.journal => 'Jurnal',
        _ItemType.note => 'Catatan',
        _ItemType.todo => 'To-do',
      };
}

// ─────────────────────────────────────────────────────────
// Home Screen
// ─────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.email,
    required this.onLogout,
  });

  final String email;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────
  int _selectedIndex = 0;
  bool _fabExpanded = false;

  final List<NoteItem> _notes = [];
  final List<TodoItem> _todos = [];
  final List<JournalItem> _journals = [];

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Files tab filter: 0=all, 1=journal, 2=note, 3=todo
  int _filesFilter = 0;

  // ── Animations ────────────────────────────────────────
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;
  late final Animation<double> _fabOpacity;

  // ── Constants ─────────────────────────────────────────
  static const String _fontAlt = 'MontserratAlternates';
  static const Color _dust = AppColors.dustLavender;
  static const Color _cream = AppColors.moonCream;
  static const Color _cardBg = Color(0xFF0D1240);

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    _fabOpacity = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────
  String _formatDateTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  List<_AnyItem> get _allItems {
    final all = <_AnyItem>[
      for (final j in _journals)
        _AnyItem(type: _ItemType.journal, id: j.id, title: j.title, preview: j.content, isPinned: j.isPinned, updatedAt: j.updatedAt),
      for (final n in _notes)
        _AnyItem(type: _ItemType.note, id: n.id, title: n.title, preview: n.content, isPinned: n.isPinned, updatedAt: n.updatedAt),
      for (final t in _todos)
        _AnyItem(type: _ItemType.todo, id: t.id, title: t.title, preview: '', isPinned: t.isPinned, updatedAt: t.updatedAt, isDone: t.isDone),
    ];
    all.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return all;
  }

  void _toggleFab() {
    setState(() => _fabExpanded = !_fabExpanded);
    _fabExpanded ? _fabCtrl.forward() : _fabCtrl.reverse();
  }

  void _snackComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 22),
        backgroundColor: const Color(0xFF1B1F4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('fitur segera hadir', textAlign: TextAlign.center,
            style: TextStyle(fontFamily: _fontAlt, fontSize: 13, height: 1.4, color: _cream)),
      ));
  }

  void _openNotes() {
    if (_fabExpanded) _toggleFab();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NotesScreen(
        notes: _notes,
        onNotesChanged: (u) => setState(() { _notes..clear()..addAll(u); }),
        onBack: () => Navigator.of(context).pop(),
      ),
    ));
  }

  void _openTodo() {
    if (_fabExpanded) _toggleFab();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TodoScreen(
        todos: _todos,
        onTodosChanged: (u) => setState(() { _todos..clear()..addAll(u); }),
        onBack: () => Navigator.of(context).pop(),
      ),
    ));
  }

  void _openJournal() {
    if (_fabExpanded) _toggleFab();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => JournalScreen(
        journals: _journals,
        onJournalsChanged: (u) => setState(() { _journals..clear()..addAll(u); }),
        onBack: () => Navigator.of(context).pop(),
      ),
    ));
  }

  void _openByType(_ItemType type) {
    switch (type) {
      case _ItemType.journal: _openJournal();
      case _ItemType.note: _openNotes();
      case _ItemType.todo: _openTodo();
    }
  }

  String get _displayName {
    final local = widget.email.split('@').first;
    final stripped = local.replaceAll(RegExp(r'\d+$'), '');
    if (stripped.isEmpty) return local;
    return stripped[0].toUpperCase() + stripped.substring(1);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  // ── Main build ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      extendBody: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.nightSky),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Moon
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset('assets/images/moon_half.png', fit: BoxFit.fill, filterQuality: FilterQuality.high),
                  ),
                ),
              ),

              // Tab content
              SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [_buildHomeTab(), _buildFilesTab(), _buildProfileTab()],
                ),
              ),

              // FAB dismiss overlay
              if (_fabExpanded)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleFab,
                    behavior: HitTestBehavior.opaque,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),

              // FAB mini menu (only on home tab)
              if (_selectedIndex == 0)
                Positioned(right: 20, bottom: 86, child: _buildFabMenu()),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0 ? _buildFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── HOME TAB ──────────────────────────────────────────
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 20),
          _buildQuickAccess(),
          const SizedBox(height: 20),
          _buildRecentAdded(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo_nottia.png', width: 28, filterQuality: FilterQuality.high),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: const TextStyle(fontFamily: _fontAlt, fontSize: 13, fontWeight: FontWeight.w400, height: 1.3, color: _dust)),
                Text(_displayName, style: const TextStyle(fontFamily: 'Caudex', fontSize: 22, height: 1.2, color: _cream)),
              ],
            ),
          ),
          SizedBox(
            width: 80, height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: 0, top: 4, child: Image.asset('assets/images/stars/star_01.png', width: 7, height: 7, filterQuality: FilterQuality.high)),
                Positioned(left: 11, top: 18, child: Image.asset('assets/images/stars/star_02.png', width: 9, height: 9, filterQuality: FilterQuality.high)),
                Positioned(left: 22, top: 2, child: Image.asset('assets/images/stars/star_03.png', width: 8, height: 8, filterQuality: FilterQuality.high)),
                Positioned(left: 33, top: 13, child: Image.asset('assets/images/stars/star_04.png', width: 8, height: 8, filterQuality: FilterQuality.high)),
                Positioned(
                  right: 0, top: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1B1F4A),
                    child: const Icon(Icons.person_rounded, size: 20, color: _cream),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search_rounded, size: 18, color: _dust.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                cursorColor: AppColors.loginBlueStart,
                style: const TextStyle(fontFamily: _fontAlt, fontSize: 13, color: _cream),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'Cari semua catatan...',
                  hintStyle: TextStyle(fontFamily: _fontAlt, fontSize: 13, color: _dust.withValues(alpha: 0.5)),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.close_rounded, size: 16, color: _dust.withValues(alpha: 0.6)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(color: const Color(0x880D1240), borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            _statItem(_journals.length.toString(), 'Journal'),
            _statDivider(),
            _statItem(_notes.length.toString(), 'Notes'),
            _statDivider(),
            _statItem(_todos.length.toString(), 'To-do'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String count, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: const TextStyle(fontFamily: 'Caudex', fontSize: 28, height: 1.1, color: _cream)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontFamily: _fontAlt, fontSize: 11, color: _dust)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 40, color: _dust.withValues(alpha: 0.25));

  // ── Quick Access ──────────────────────────────────────
  Widget _buildQuickAccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Access', style: TextStyle(fontFamily: _fontAlt, fontSize: 13, fontWeight: FontWeight.w700, height: 1.2, color: _cream)),
          const SizedBox(height: 10),
          Row(
            children: [
              _quickCard(Icons.book_outlined, 'Journal', _openJournal),
              const SizedBox(width: 12),
              _quickCard(Icons.sticky_note_2_outlined, 'Notes', _openNotes),
              const SizedBox(width: 12),
              _quickCard(Icons.checklist_rounded, 'To-do', _openTodo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickCard(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 76,
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: _dust),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontFamily: _fontAlt, fontSize: 11, color: _dust)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recent Added ──────────────────────────────────────
  Widget _buildRecentAdded() {
    final q = _searchQuery.toLowerCase();
    final filtered = _allItems.where((item) {
      if (q.isEmpty) return true;
      return item.title.toLowerCase().contains(q) || item.preview.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Added', style: TextStyle(fontFamily: _fontAlt, fontSize: 13, fontWeight: FontWeight.w700, height: 1.2, color: _cream)),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  q.isNotEmpty ? 'tidak ada hasil' : 'belum ada catatan',
                  style: TextStyle(fontFamily: _fontAlt, fontSize: 12, color: _dust.withValues(alpha: 0.7)),
                ),
              ),
            )
          else
            for (final item in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => _openByType(item.type),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: item.isPinned ? Border.all(color: _dust.withValues(alpha: 0.20)) : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10, top: 1),
                          child: Icon(
                            item.isPinned ? Icons.push_pin_rounded : item.icon,
                            size: 14, color: _dust,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title.isEmpty ? '(tanpa judul)' : item.title,
                                      style: const TextStyle(fontFamily: _fontAlt, fontSize: 12, fontWeight: FontWeight.w700, color: _cream),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _dust.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(item.typeLabel, style: TextStyle(fontFamily: _fontAlt, fontSize: 9, color: _dust.withValues(alpha: 0.8))),
                                  ),
                                ],
                              ),
                              if (item.preview.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(item.preview,
                                  style: TextStyle(fontFamily: _fontAlt, fontSize: 11, color: _dust.withValues(alpha: 0.8), height: 1.4),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                              if (item.type == _ItemType.todo && item.isDone) ...[
                                const SizedBox(height: 2),
                                Text('✓ selesai', style: TextStyle(fontFamily: _fontAlt, fontSize: 10, color: AppColors.loginBlueStart.withValues(alpha: 0.8))),
                              ],
                              const SizedBox(height: 4),
                              Text(_formatDateTime(item.updatedAt),
                                style: TextStyle(fontFamily: _fontAlt, fontSize: 10, color: _dust.withValues(alpha: 0.5))),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: _dust),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ── FILES TAB ─────────────────────────────────────────
  Widget _buildFilesTab() {
    final filters = ['Semua', 'Jurnal', 'Catatan', 'To-do'];
    final icons = [Icons.apps_rounded, Icons.book_outlined, Icons.sticky_note_2_outlined, Icons.checklist_rounded];

    List<_AnyItem> items = _allItems;
    if (_filesFilter == 1) items = items.where((i) => i.type == _ItemType.journal).toList();
    if (_filesFilter == 2) items = items.where((i) => i.type == _ItemType.note).toList();
    if (_filesFilter == 3) items = items.where((i) => i.type == _ItemType.todo).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: const Text('Files', style: TextStyle(fontFamily: 'Caudex', fontSize: 26, height: 1.1, color: _cream)),
        ),
        const SizedBox(height: 14),

        // Filter chips
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = _filesFilter == i;
              return GestureDetector(
                onTap: () => setState(() => _filesFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.loginBlueStart : _cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[i], size: 13, color: selected ? Colors.white : _dust),
                      const SizedBox(width: 5),
                      Text(filters[i], style: TextStyle(fontFamily: _fontAlt, fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? Colors.white : _dust)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Count
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Text(
            '${items.length} item',
            style: TextStyle(fontFamily: _fontAlt, fontSize: 11, color: _dust.withValues(alpha: 0.6)),
          ),
        ),

        // List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 48, color: _dust.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('belum ada item', style: TextStyle(fontFamily: _fontAlt, fontSize: 13, color: _dust.withValues(alpha: 0.6))),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return GestureDetector(
                      onTap: () => _openByType(item.type),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: item.isPinned ? Border.all(color: _dust.withValues(alpha: 0.20)) : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Type icon box
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.loginBlueStart.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.icon, size: 20, color: AppColors.loginBlueStart.withValues(alpha: 0.85)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title.isEmpty ? '(tanpa judul)' : item.title,
                                          style: const TextStyle(fontFamily: _fontAlt, fontSize: 13, fontWeight: FontWeight.w700, color: _cream),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (item.isPinned)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(Icons.push_pin_rounded, size: 13, color: _dust),
                                        ),
                                      if (item.type == _ItemType.todo && item.isDone)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Icon(Icons.check_circle_rounded, size: 14, color: AppColors.loginBlueStart.withValues(alpha: 0.8)),
                                        ),
                                    ],
                                  ),
                                  if (item.preview.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(item.preview,
                                      style: TextStyle(fontFamily: _fontAlt, fontSize: 11, color: _dust.withValues(alpha: 0.8), height: 1.3),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _dust.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(item.typeLabel, style: TextStyle(fontFamily: _fontAlt, fontSize: 9, color: _dust.withValues(alpha: 0.8))),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(_formatDateTime(item.updatedAt), style: TextStyle(fontFamily: _fontAlt, fontSize: 10, color: _dust.withValues(alpha: 0.5))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: _dust),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── PROFILE TAB (placeholder) ──────────────────────────
  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 36, backgroundColor: _cardBg, child: const Icon(Icons.person_rounded, size: 40, color: _dust)),
          const SizedBox(height: 16),
          Text(_displayName, style: const TextStyle(fontFamily: 'Caudex', fontSize: 24, color: _cream)),
          const SizedBox(height: 4),
          Text(widget.email, style: TextStyle(fontFamily: _fontAlt, fontSize: 12, color: _dust.withValues(alpha: 0.7))),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: widget.onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout_rounded, size: 16, color: _dust),
                  SizedBox(width: 8),
                  Text('Keluar', style: TextStyle(fontFamily: _fontAlt, fontSize: 13, color: _dust)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────
  Widget _buildFab() {
    return GestureDetector(
      onTap: _toggleFab,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.loginButton,
          boxShadow: [BoxShadow(color: AppColors.loginBlueEnd.withValues(alpha: 0.40), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: AnimatedRotation(
          turns: _fabExpanded ? 0.125 : 0,
          duration: const Duration(milliseconds: 220),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildFabMenu() {
    const actions = [
      (Icons.book_outlined, 'Journal'),
      (Icons.sticky_note_2_outlined, 'Note'),
      (Icons.checklist_rounded, 'Todo'),
    ];

    return FadeTransition(
      opacity: _fabOpacity,
      child: ScaleTransition(
        scale: _fabScale,
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...actions.reversed.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF1B1F4A), borderRadius: BorderRadius.circular(8)),
                    child: Text(a.$2, style: const TextStyle(fontFamily: _fontAlt, fontSize: 12, color: _cream)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      switch (a.$2) {
                        case 'Journal': _openJournal();
                        case 'Note': _openNotes();
                        case 'Todo': _openTodo();
                      }
                    },
                    child: Container(
                      width: 46, height: 46,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1B1F4A)),
                      child: Icon(a.$1, size: 20, color: _dust),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 58),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() { _selectedIndex = i; if (_fabExpanded) _toggleFab(); }),
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF07083A),
      selectedItemColor: AppColors.dustLavender,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontFamily: _fontAlt, fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontFamily: _fontAlt, fontSize: 10, fontWeight: FontWeight.w400),
      elevation: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: 'Files'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
