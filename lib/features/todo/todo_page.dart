import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────
class TodoItem {
  TodoItem({
    required this.id,
    required this.title,
    this.isDone = false,
    this.isPinned = false,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  String title;
  bool isDone;
  bool isPinned;
  final DateTime createdAt;
  DateTime updatedAt;
}

// ─────────────────────────────────────────────────────────
// Todo Screen
// ─────────────────────────────────────────────────────────
class TodoScreen extends StatefulWidget {
  const TodoScreen({
    super.key,
    required this.todos,
    required this.onTodosChanged,
    required this.onBack,
  });

  final List<TodoItem> todos;
  final ValueChanged<List<TodoItem>> onTodosChanged;
  final VoidCallback onBack;

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  static const String _fontAlt = 'MontserratAlternates';
  static const Color _dustLavender = AppColors.dustLavender;
  static const Color _cardBg = Color(0xFF0D1240);

  late List<TodoItem> _todos;
  final TextEditingController _addCtrl = TextEditingController();
  final FocusNode _addFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _todos = List<TodoItem>.from(widget.todos);
    _sort();
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  void _sort() {
    _todos.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  void _sync() => widget.onTodosChanged(List<TodoItem>.from(_todos));

  void _addTodo(String title) {
    final t = title.trim();
    if (t.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      _todos.insert(0, TodoItem(
        id: now.millisecondsSinceEpoch.toString(),
        title: t,
        createdAt: now,
      ));
      _sort();
    });
    _addCtrl.clear();
    _sync();
  }

  void _toggleDone(TodoItem todo) {
    setState(() {
      todo.isDone = !todo.isDone;
      todo.updatedAt = DateTime.now();
      _sort();
    });
    _sync();
  }

  void _togglePin(TodoItem todo) {
    setState(() {
      todo.isPinned = !todo.isPinned;
      _sort();
    });
    _sync();
  }

  Future<void> _editTodo(TodoItem todo) async {
    final ctrl = TextEditingController(text: todo.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Tugas', style: TextStyle(fontFamily: 'Caudex', color: AppColors.moonCream, fontSize: 18)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          cursorColor: AppColors.loginBlueStart,
          style: const TextStyle(fontFamily: _fontAlt, fontSize: 14, color: AppColors.moonCream),
          decoration: InputDecoration(
            hintText: 'Nama tugas...',
            hintStyle: TextStyle(fontFamily: _fontAlt, fontSize: 14, color: _dustLavender.withValues(alpha: 0.5)),
            border: UnderlineInputBorder(borderSide: BorderSide(color: _dustLavender.withValues(alpha: 0.3))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.loginBlueStart)),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.dustLavender))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Simpan', style: TextStyle(color: AppColors.loginBlueStart))),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        todo.title = result.trim();
        todo.updatedAt = DateTime.now();
      });
      _sync();
    }
  }

  Future<void> _deleteTodo(TodoItem todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tugas', style: TextStyle(fontFamily: 'Caudex', color: AppColors.moonCream, fontSize: 18)),
        content: const Text('Yakin ingin menghapus tugas ini?', style: TextStyle(fontFamily: _fontAlt, color: AppColors.dustLavender, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: AppColors.dustLavender))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Color(0xFFFF7A7A)))),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _todos.removeWhere((t) => t.id == todo.id));
      _sync();
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  Widget _buildTodoCard(TodoItem todo) {
    return Dismissible(
      key: Key(todo.id),
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
        await _deleteTodo(todo);
        return false;
      },
      child: GestureDetector(
        onTap: () => _toggleDone(todo),
        onLongPress: () => _togglePin(todo),
        onDoubleTap: () => _editTodo(todo),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: todo.isPinned
                ? Border.all(color: _dustLavender.withValues(alpha: 0.20), width: 1)
                : null,
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => _toggleDone(todo),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: todo.isDone ? AppColors.loginBlueStart.withValues(alpha: 0.8) : Colors.transparent,
                    border: Border.all(
                      color: todo.isDone ? AppColors.loginBlueStart : _dustLavender.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: todo.isDone
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontFamily: _fontAlt,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: todo.isDone ? _dustLavender.withValues(alpha: 0.6) : AppColors.moonCream,
                        decoration: todo.isDone ? TextDecoration.lineThrough : null,
                        decorationColor: _dustLavender,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDateTime(todo.updatedAt),
                      style: TextStyle(fontFamily: _fontAlt, fontSize: 10, color: _dustLavender.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              if (todo.isPinned)
                const Icon(Icons.push_pin_rounded, size: 15, color: AppColors.dustLavender),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildList() {
    final pinned = _todos.where((t) => t.isPinned && !t.isDone).toList();
    final active = _todos.where((t) => !t.isPinned && !t.isDone).toList();
    final done = _todos.where((t) => t.isDone).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      children: [
        if (pinned.isNotEmpty) ...[
          _buildSectionLabel('Disematkan', Icons.push_pin_rounded),
          const SizedBox(height: 8),
          for (final t in pinned) ...[_buildTodoCard(t), const SizedBox(height: 10)],
        ],
        if (active.isNotEmpty) ...[
          if (pinned.isNotEmpty) const SizedBox(height: 4),
          _buildSectionLabel('Tugas', Icons.checklist_rounded),
          const SizedBox(height: 8),
          for (final t in active) ...[_buildTodoCard(t), const SizedBox(height: 10)],
        ],
        if (done.isNotEmpty) ...[
          if (pinned.isNotEmpty || active.isNotEmpty) const SizedBox(height: 4),
          _buildSectionLabel('Selesai', Icons.check_circle_outline_rounded),
          const SizedBox(height: 8),
          for (final t in done) ...[_buildTodoCard(t), const SizedBox(height: 10)],
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
                        child: Text('To-do', style: TextStyle(fontFamily: 'Caudex', fontSize: 22, color: AppColors.moonCream)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 4),
                  child: Text(
                    'Ketuk untuk centang · Tekan lama untuk sematkan · Klik dua kali untuk edit',
                    style: TextStyle(fontFamily: _fontAlt, fontSize: 10, color: _dustLavender.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _todos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.checklist_rounded, size: 48, color: _dustLavender.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('belum ada tugas', style: TextStyle(fontFamily: _fontAlt, fontSize: 13, color: AppColors.dustLavender)),
                            ],
                          ),
                        )
                      : _buildList(),
                ),
                // Quick-add bar
                Container(
                  color: const Color(0xFF07083A),
                  padding: EdgeInsets.only(
                    left: 16, right: 12, top: 10,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: TextField(
                              controller: _addCtrl,
                              focusNode: _addFocus,
                              cursorColor: AppColors.loginBlueStart,
                              style: const TextStyle(fontFamily: _fontAlt, fontSize: 13, color: AppColors.moonCream),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                hintText: 'Tambah tugas baru...',
                                hintStyle: TextStyle(fontFamily: _fontAlt, fontSize: 13, color: _dustLavender.withValues(alpha: 0.5)),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: _addTodo,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _addTodo(_addCtrl.text),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.loginButton,
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
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
