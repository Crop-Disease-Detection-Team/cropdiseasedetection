import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/config/app_config.dart';

final adminUsersProvider = StateNotifierProvider.autoDispose<AdminUsersNotifier, AsyncValue<List<dynamic>>>((ref) {
  return AdminUsersNotifier();
});

class AdminUsersNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  AdminUsersNotifier() : super(const AsyncValue.loading()) {
    fetchUsers();
  }

  final ApiClient _api = ApiClient(AppConfig.apiBaseUrl);
  String _searchQuery = '';
  String _roleFilter = '';

  void setSearch(String q) {
    _searchQuery = q;
    fetchUsers();
  }

  void setRole(String r) {
    _roleFilter = r;
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;
      if (_roleFilter.isNotEmpty) queryParams['role'] = _roleFilter;

      final response = await _api.dio.get('accounts/admin/users/', queryParameters: queryParams);
      state = AsyncValue.data(response.data as List);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> runAction(int userId, String action) async {
    try {
      await _api.dio.post('accounts/admin/users/$userId/$action/');
      await fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await _api.dio.delete('accounts/admin/users/$userId/');
      await fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class AdminUsersScreen extends HookConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final searchController = useTextEditingController();
    final selectedRole = useState<String>('');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (val) {
                      ref.read(adminUsersProvider.notifier).setSearch(val.trim());
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedRole.value.isEmpty ? null : selectedRole.value,
                  hint: const Text('Role'),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All')),
                    DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    DropdownMenuItem(value: 'user', child: Text('Users')),
                  ],
                  onChanged: (val) {
                    final role = val ?? '';
                    selectedRole.value = role;
                    ref.read(adminUsersProvider.notifier).setRole(role);
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(adminUsersProvider.notifier).fetchUsers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index] as Map<String, dynamic>;
                      final userId = user['id'] as int;
                      final isCurrentUserAdmin = user['role'] == 'admin';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: isCurrentUserAdmin ? AppColors.primary.withAlpha(26) : Colors.grey.shade200,
                            child: Icon(
                              isCurrentUserAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                              color: isCurrentUserAdmin ? AppColors.primary : Colors.grey.shade700,
                            ),
                          ),
                          title: Text(user['full_name'] ?? user['email'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(user['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (user['phone'] != null) Text('Phone: ${user['phone']}', style: const TextStyle(fontSize: 13)),
                                  if (user['district'] != null) Text('District: ${user['district']}', style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () async {
                                          final action = isCurrentUserAdmin ? 'demote' : 'promote';
                                          final success = await ref.read(adminUsersProvider.notifier).runAction(userId, action);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(success ? 'Role updated successfully.' : 'Action failed.')),
                                            );
                                          }
                                        },
                                        icon: Icon(isCurrentUserAdmin ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 16),
                                        label: Text(isCurrentUserAdmin ? 'Demote' : 'Promote'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () async {
                                          final success = await ref.read(adminUsersProvider.notifier).deleteUser(userId);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(success ? 'User deleted successfully.' : 'Failed to delete user.')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                                        label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          )
        ],
      ),
    );
  }
}

