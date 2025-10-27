import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TodoApp());
}

class TodoItem {
  String id;
  String title;
  bool done;
  DateTime createdAt;

  TodoItem({
    required this.id,
    required this.title,
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern ToDo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const TodoHomePage(),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<TodoItem> _items = [];

  // controller for entry animation (subtle scale/slide)
  late final AnimationController _bgPulseController;

  @override
  void initState() {
    super.initState();
    _bgPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // sample starter items
    Future.delayed(const Duration(milliseconds: 300), () {
      _insertItem(TodoItem(id: UniqueKey().toString(), title: 'Buy groceries'));
      _insertItem(TodoItem(id: UniqueKey().toString(), title: 'Walk with Sam'));
      _insertItem(TodoItem(id: UniqueKey().toString(), title: 'Read 20 pages'));
    });
  }

  @override
  void dispose() {
    _bgPulseController.dispose();
    super.dispose();
  }

  void _showFilterMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color.fromARGB(255, 151, 150, 150),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 130, 183, 253),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('Sort: Pending first'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _items.sort((a, b) => a.done ? 1 : -1);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.filter_list),
                title: const Text('Show only pending'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _items.retainWhere((i) => !i.done);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Clear completed'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _items.removeWhere((i) => i.done);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _insertItem(TodoItem item) {
    _items.insert(0, item);
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 450));
  }

  void _removeItem(int index) {
    final removed = _items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTile(removed, index, animation, removing: true),
      duration: const Duration(milliseconds: 400),
    );
  }

  void _toggleDone(int index) {
    setState(() {
      _items[index].done = !_items[index].done;
    });
  }

  Future<void> _showAddSheet() async {
    final newTitle = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddTaskSheet();
      },
    );

    if (newTitle != null && newTitle.trim().isNotEmpty) {
      final item = TodoItem(id: UniqueKey().toString(), title: newTitle.trim());
      _insertItem(item);
    }
  }

  Widget _buildTile(TodoItem item, int index, Animation<double> animation, {bool removing = false}) {
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: 0.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: GestureDetector(
          onTap: () => _toggleDone(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: item.done
                      ? LinearGradient(colors: [Colors.green.shade400.withOpacity(0.15), Colors.transparent])
                      : LinearGradient(colors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)]),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: item.done
                          ? const Icon(Icons.check_circle, key: ValueKey('done'), color: Color.fromARGB(255, 0, 0, 0))
                          : Icon(Icons.radio_button_unchecked, key: ValueKey('pending'), color: Colors.grey.shade400),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              decoration: item.done ? TextDecoration.lineThrough : TextDecoration.none,
                              color: item.done ? Colors.grey.shade500 : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                _formatDate(item.createdAt),
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
                              ),
                              const SizedBox(width: 8),
                              if (!item.done)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Today', style: TextStyle(fontSize: 11)),
                                )
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // delete button
                    GestureDetector(
                      onTap: () {
                        _removeItem(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${item.title}" removed'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                // restore
                                setState(() {
                                  _items.insert(index, item);
                                  _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 350));
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.delete_outline, size: 22),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) return 'Today';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 124, 243, 184),
        elevation: 0,
        title: const Text('Your To‑Do'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilterMenu,
          )
        ],
      ),
      body: Stack(
        children: [
          // gradient background with subtle moving circle
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgPulseController,
              builder: (context, child) {
                final v = _bgPulseController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.6 + v * 1.2, -0.5 + v * 0.6),
                      radius: 1.2,
                      colors: [
                        const Color.fromARGB(255, 70, 196, 255),
                        const Color.fromARGB(255, 168, 247, 90),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good day,', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                          const SizedBox(height: 6),
                          Text('Organize your day', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        child: const Icon(Icons.check, color: Colors.white),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, -12))
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Text('Today', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade400.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('${_items.length} tasks', style: const TextStyle(fontSize: 12)),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _items.sort((a, b) => a.done ? 1 : -1);
                                  });
                                },
                                icon: const Icon(Icons.sort),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: AnimatedList(
                            key: _listKey,
                            initialItemCount: _items.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index, animation) {
                              final item = _items[index];
                              return Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  padding: const EdgeInsets.only(right: 20),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (dir) => _removeItem(index),
                                child: _buildTile(item, index, animation),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        elevation: 6,
        label: const Text('Add task'),
        icon: const Icon(Icons.add_task_rounded),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isValid = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 117, 181, 255),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Add a new task', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'What do you want to do?',
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (value) {
                if (_isValid) Navigator.of(context).pop(value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValid ? () => Navigator.of(context).pop(_controller.text) : null,
                    child: const Text('Add task'),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
