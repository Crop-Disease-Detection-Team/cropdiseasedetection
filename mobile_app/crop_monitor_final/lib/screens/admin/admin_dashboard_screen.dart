import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          title: const Text('Admin dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.green700,
            unselectedLabelColor: AppColors.gray500,
            indicatorColor: AppColors.green700,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Users'),
              Tab(text: 'Scans'),
              Tab(text: 'Feedback'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                }
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [_OverviewTab(), _UsersTab(), _ScansTab(), _FeedbackTab()],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final _adminService = AdminService();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await _adminService.getDashboardStats();
      setState(() => _stats = s);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _card(String label, String value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.green700),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const Center(child: Text('Could not load stats'));

    final users = _stats!['users'] ?? {};
    final scans = _stats!['scans'] ?? {};
    final diseases = _stats!['diseases'] ?? {};
    final activities = (_stats!['recent_activities'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(children: [
            _card('Total users', '${users['total'] ?? 0}', Icons.people_outline),
            _card('Active users', '${users['active'] ?? 0}', Icons.person_pin_outlined),
          ]),
          Row(children: [
            _card('Total scans', '${scans['total'] ?? 0}', Icons.document_scanner_outlined),
            _card('Scans today', '${scans['today'] ?? 0}', Icons.today_outlined),
          ]),
          Row(children: [
            _card('Diseases tracked', '${diseases['total'] ?? 0}', Icons.eco_outlined),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          ...activities.map((a) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.bolt, color: AppColors.amber500),
                  title: Text('${a['user_name']} scanned ${a['disease_name']}'),
                  subtitle: Text(a['timestamp']?.toString() ?? ''),
                ),
              )),
        ],
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _adminService = AdminService();
  List<dynamic> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String search = ''}) async {
    setState(() => _loading = true);
    try {
      final result = await _adminService.getUsers(search: search, perPage: 50);
      setState(() => _users = result['users'] ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(Map user) async {
    await _adminService.setUserStatus(user['id'], !(user['is_active'] == true));
    _load(search: _searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
                hintText: 'Search name, email or phone', prefixIcon: Icon(Icons.search, size: 20)),
            onSubmitted: (v) => _load(search: v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, i) {
                    final u = _users[i] as Map;
                    final active = u['is_active'] == true;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${u['email']}\n${u['total_scans'] ?? 0} scans'),
                        isThreeLine: true,
                        trailing: Switch(
                          value: active,
                          activeColor: AppColors.green700,
                          onChanged: (_) => _toggleStatus(u),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ScansTab extends StatefulWidget {
  const _ScansTab();
  @override
  State<_ScansTab> createState() => _ScansTabState();
}

class _ScansTabState extends State<_ScansTab> {
  final _adminService = AdminService();
  List<dynamic> _scans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _adminService.getAllScans(perPage: 50);
      setState(() => _scans = result['scans'] ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _scans.length,
        itemBuilder: (context, i) {
          final s = _scans[i] as Map;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.eco_outlined, color: AppColors.green700),
              title: Text(s['disease_name'] ?? ''),
              subtitle: Text('${s['user_name'] ?? s['user_id'] ?? ''} • ${s['scanned_at'] ?? ''}'),
            ),
          );
        },
      ),
    );
  }
}

class _FeedbackTab extends StatefulWidget {
  const _FeedbackTab();
  @override
  State<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<_FeedbackTab> {
  final _adminService = AdminService();
  List<dynamic> _feedback = [];
  bool _loading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result =
          await _adminService.getAllFeedback(status: _statusFilter, perPage: 50);
      setState(() => _feedback = result['feedbacks'] ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(Map fb, String status) async {
    await _adminService.setFeedbackStatus(fb['id'], status);
    _load();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'resolved':
        return AppColors.green700;
      case 'read':
        return AppColors.amber500;
      default:
        return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null),
                _filterChip('Pending', 'pending'),
                _filterChip('Read', 'read'),
                _filterChip('Resolved', 'resolved'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _feedback.isEmpty
                  ? const Center(child: Text('No feedback yet'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: _feedback.length,
                        itemBuilder: (context, i) {
                          final fb = _feedback[i] as Map;
                          final status = fb['status'] ?? 'pending';
                          return Card(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(fb['user_name'] ?? 'Unknown',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.full),
                                        ),
                                        child: Text(status,
                                            style: TextStyle(
                                                color: _statusColor(status),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                  if (fb['user_email'] != null)
                                    Text(fb['user_email'],
                                        style: const TextStyle(
                                            fontSize: 12, color: AppColors.gray500)),
                                  const SizedBox(height: 8),
                                  Text(fb['message'] ?? '',
                                      style: const TextStyle(height: 1.4)),
                                  const SizedBox(height: 8),
                                  Text(fb['created_at']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.gray300)),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (status != 'read')
                                        TextButton(
                                          onPressed: () => _updateStatus(fb, 'read'),
                                          child: const Text('Mark read'),
                                        ),
                                      if (status != 'resolved')
                                        TextButton(
                                          onPressed: () =>
                                              _updateStatus(fb, 'resolved'),
                                          child: const Text('Resolve'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = value);
          _load();
        },
      ),
    );
  }
}
