import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tasks',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search tasks or apps...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.white38, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white38, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // TASK LIST
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: Supabase.instance.client
                  .from('tasks')
                  .select(
                      'app_name, title, user_payout_ngn, task_type, slots_left, is_active, created_at, priority_level, task_url, form_url, description')
                  .eq('is_active', true)
                  .order('priority_level', ascending: false)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Could not load tasks. Check your connection.',
                      style: TextStyle(color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final allTasks = snapshot.data ?? [];
                final tasks = _searchQuery.isEmpty
                    ? allTasks
                    : allTasks.where((t) {
                        final title =
                            (t['title'] as String? ?? '').toLowerCase();
                        final appName =
                            (t['app_name'] as String? ?? '').toLowerCase();
                        return title.contains(_searchQuery) ||
                            appName.contains(_searchQuery);
                      }).toList();

                if (tasks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No tasks available right now. Check back soon!'
                          : 'No tasks match "$_searchQuery".',
                      style: const TextStyle(color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final title = task['title'] as String? ?? 'Task';
                    final appName = task['app_name'] as String? ?? '';
                    final description = task['description'] as String?;
                    final payout = task['user_payout_ngn'];
                    final taskType = task['task_type'] as String? ?? '';
                    final slotsLeft = task['slots_left'] as int?;
                    final priority = task['priority_level'] as int? ?? 0;
                    final taskUrl = task['task_url'] as String?;
                    final formUrl = task['form_url'] as String?;
                    final isHighPriority = priority >= 8;
                    final noSlots = slotsLeft != null && slotsLeft <= 0;

                    return Opacity(
                      opacity: noSlots ? 0.45 : 1.0,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: isHighPriority
                              ? const BorderSide(
                                  color: Color(0xFFFBBF24), width: 1)
                              : const BorderSide(color: Colors.white10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HEADER ROW
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF334155),
                                    child: Icon(
                                      Icons.bolt,
                                      color: isHighPriority
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFF4ADE80),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (appName.isNotEmpty)
                                              Text(
                                                appName,
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            if (isHighPriority) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0x33FBBF24),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'HOT',
                                                  style: TextStyle(
                                                    color: Color(0xFFFBBF24),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // PAYOUT BADGE
                                  if (payout != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0x224ADE80),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '₦${payout.toString()}',
                                        style: const TextStyle(
                                          color: Color(0xFF4ADE80),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              // DESCRIPTION
                              if (description != null &&
                                  description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),

                              // META ROW
                              Row(
                                children: [
                                  if (taskType.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF334155),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        taskType,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  if (slotsLeft != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      noSlots
                                          ? 'Full'
                                          : '$slotsLeft slots left',
                                      style: TextStyle(
                                        color: noSlots
                                            ? Colors.redAccent
                                            : Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // COMPLETE BUTTON
                              if (!noSlots) ...[
                                const SizedBox(height: 14),
                                const Divider(color: Colors.white10, height: 1),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Starting task: $title'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: const Text(
                                      'Complete',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
