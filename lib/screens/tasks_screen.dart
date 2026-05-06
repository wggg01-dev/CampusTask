import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _userProfile;
  bool _profileLoaded = false;
  final Set<String> _submittedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSubmittedTasks();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, age, gender, phone, location')
        .eq('id', user.id)
        .single();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _profileLoaded = true;
      });
    }
  }

  Future<void> _loadSubmittedTasks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final rows = await Supabase.instance.client
        .from('user_tasks')
        .select('task_id')
        .eq('user_id', user.id);
    if (mounted) {
      setState(() {
        _submittedTaskIds.addAll(
          (rows as List).map((r) => r['task_id'].toString()),
        );
      });
    }
  }

  Future<String?> _getDeviceId() async {
    final info = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        return web.userAgent;
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return android.id;
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return ios.identifierForVendor;
      }
    } catch (_) {}
    return null;
  }

  bool get _bioComplete {
    final name = _userProfile?['full_name'] as String?;
    return name != null && name.trim().isNotEmpty;
  }

  Future<void> _onComplete(Map<String, dynamic> task) async {
    if (!_bioComplete) {
      _showBioBlockedDialog();
      return;
    }

    final taskUrl = task['task_url'] as String?;

    if (taskUrl != null && taskUrl.trim().isNotEmpty) {
      // ── Workflow 1: Quick complete — record then launch URL ───────
      await _handleQuickComplete(taskUrl.trim(), task['id'].toString());
    } else {
      // ── Workflow 2: Submit bio-data automatically ────────────────
      await _submitBioData(task);
    }
  }

  Future<void> _handleQuickComplete(String taskUrl, String taskId) async {
    final user = Supabase.instance.client.auth.currentUser;
    final deviceId = await _getDeviceId();

    try {
      // 1. Instantly record the submission using their existing bio-data
      // The DB will link the user_id to their profile automatically
      await Supabase.instance.client.from('task_submissions').upsert({
        'user_id': user?.id,
        'task_id': taskId,
        'device_id': deviceId,
        'status': 'pending',
      });

      // 2. Mark locally so button updates immediately
      if (mounted) {
        setState(() => _submittedTaskIds.add(taskId));
      }

      // 3. Launch the external link immediately
      final Uri url = Uri.parse(taskUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        final message = errorStr.contains('unique_task_per_device')
            ? 'This device has already completed this task.'
            : 'Submission failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitBioData(Map<String, dynamic> task) async {
    final user = Supabase.instance.client.auth.currentUser!;
    final deviceId = await _getDeviceId();
    try {
      await Supabase.instance.client.from('task_submissions').upsert({
        'user_id': user.id,
        'task_id': task['id'],
        'full_name': _userProfile!['full_name'],
        'age': _userProfile!['age'],
        'gender': _userProfile!['gender'],
        'phone': _userProfile!['phone'],
        'location': _userProfile!['location'],
        'submitted_at': DateTime.now().toIso8601String(),
        if (deviceId != null) 'device_id': deviceId,
      });

      // Mark locally so button updates immediately
      if (mounted) {
        setState(() => _submittedTaskIds.add(task['id'].toString()));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Submitted! "${task['title']}" is now under review.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${e.toString()}')),
        );
      }
    }
  }

  void _showBioBlockedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.amber, size: 22),
            SizedBox(width: 10),
            Text(
              'Profile Incomplete',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'You need to complete your profile before you can complete tasks.\n\nGo to Settings → Profile to fill in your details.',
          style: TextStyle(color: Colors.white60, height: 1.6),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Got it',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

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
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 20),
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

          // BIO WARNING BANNER
          if (_profileLoaded && !_bioComplete)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x1AFBBF24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66FBBF24)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.amber, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complete your profile to unlock task completion.',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // TASK LIST
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: Supabase.instance.client
                  .from('tasks')
                  .select(
                      'id, app_name, title, user_payout_ngn, task_type, slots_left, is_active, created_at, priority_level, task_url, description')
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
                    final isHighPriority = priority >= 8;
                    final noSlots = slotsLeft != null && slotsLeft <= 0;
                    final hasUrl =
                        taskUrl != null && taskUrl.trim().isNotEmpty;

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
                                        Row(children: [
                                          if (appName.isNotEmpty)
                                            Text(appName,
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 11)),
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
                                              child: const Text('HOT',
                                                  style: TextStyle(
                                                      color: Color(0xFFFBBF24),
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ],
                                        ]),
                                        const SizedBox(height: 2),
                                        Text(title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                  if (payout != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0x224ADE80),
                                        borderRadius:
                                            BorderRadius.circular(10),
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
                                      height: 1.5),
                                ),
                              ],

                              const SizedBox(height: 12),

                              // META ROW
                              Row(children: [
                                if (taskType.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF334155),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(taskType,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11)),
                                  ),
                                if (slotsLeft != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    noSlots ? 'Full' : '$slotsLeft slots left',
                                    style: TextStyle(
                                      color: noSlots
                                          ? Colors.redAccent
                                          : Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                                if (hasUrl) ...[
                                  const Spacer(),
                                  const Icon(Icons.open_in_new_rounded,
                                      color: Colors.white24, size: 14),
                                  const SizedBox(width: 4),
                                  const Text('Opens link',
                                      style: TextStyle(
                                          color: Colors.white24, fontSize: 11)),
                                ],
                              ]),

                              // COMPLETE / COMPLETED BUTTON
                              if (!noSlots) ...[
                                const SizedBox(height: 14),
                                const Divider(
                                    color: Colors.white10, height: 1),
                                const SizedBox(height: 14),
                                Builder(builder: (_) {
                                  final isSubmitted = _submittedTaskIds
                                      .contains(task['id'].toString());

                                  if (isSubmitted) {
                                    return Opacity(
                                      opacity: 0.45,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF334155),
                                            disabledBackgroundColor:
                                                const Color(0xFF334155),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 13),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(
                                              Icons.check_circle_outline,
                                              color: Color(0xFF10B981),
                                              size: 17),
                                          label: const Text(
                                            'Completed',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _profileLoaded
                                          ? () => _onComplete(task)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _bioComplete
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF334155),
                                        disabledBackgroundColor:
                                            const Color(0xFF334155),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 13),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        _bioComplete
                                            ? 'Complete'
                                            : 'Complete your profile first',
                                        style: TextStyle(
                                          color: _bioComplete
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
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
