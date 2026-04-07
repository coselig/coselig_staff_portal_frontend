import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/services/user_data_service.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';

// 角色顯示設定
const _roleLabels = {'admin': '管理員', 'employee': '員工', 'customer': '用戶'};

const _roleColors = {
  'admin': Colors.red,
  'employee': Colors.blue,
  'customer': Colors.grey,
};

class UserDataViewPage extends StatefulWidget {
  const UserDataViewPage({super.key});

  @override
  State<UserDataViewPage> createState() => _UserDataViewPageState();
}

class _UserDataViewPageState extends State<UserDataViewPage> {
  final UserDataService _userDataService = UserDataService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _allUsers = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    html.document.title = '帳號管理';
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userDataService.getAllUsers();
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入帳號列表失敗: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _allUsers;
    return _allUsers.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final cname = (u['chinese_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) ||
          cname.contains(_searchQuery) ||
          email.contains(_searchQuery);
    }).toList();
  }

  Future<void> _changeRole(Map<String, dynamic> user, String newRole) async {
    final userId = user['id'].toString();
    final displayName = user['chinese_name'] ?? user['name'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認變更角色'),
        content: Text('將「$displayName」的角色變更為「${_roleLabels[newRole]}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('確認'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _userDataService.updateUserRole(userId, newRole);
      setState(() {
        final idx = _allUsers.indexWhere((u) => u['id'].toString() == userId);
        if (idx != -1) _allUsers[idx] = {..._allUsers[idx], 'role': newRole};
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已將「$displayName」設為${_roleLabels[newRole]}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('變更失敗: $e')),
        );
      }
    }
  }

  Widget _buildRoleChip(String? role) {
    final label = _roleLabels[role] ?? role ?? '未知';
    final color = _roleColors[role] ?? Colors.grey;
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    final role = user['role'] as String?;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user['chinese_name'] ?? user['name'] ?? '帳號詳情'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.person, '帳號名稱', user['name']),
              _detailRow(Icons.badge, '中文姓名', user['chinese_name']),
              _detailRow(Icons.email, 'Email', user['email']),
              _detailRow(Icons.work, '職稱', user['job_title']),
              _detailRow(Icons.phone, '電話', user['phone']),
              _detailRow(Icons.calendar_today, '建立時間', user['created_at']),
              const Divider(height: 24),
              Text(
                '角色管理',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['customer', 'employee', 'admin'].map((r) {
                  final isCurrent = role == r;
                  return ChoiceChip(
                    label: Text(_roleLabels[r]!),
                    selected: isCurrent,
                    onSelected: isCurrent
                        ? null
                        : (_) {
                            Navigator.of(ctx).pop();
                            _changeRole(user, r);
                          },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteUserWithPreview(user);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除帳號'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserWithPreview(Map<String, dynamic> user) async {
    final userId = user['id'].toString();
    final displayName = user['chinese_name'] ?? user['name'] ?? '此帳號';

    // 顯示載入中的對話框
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在查詢關聯資料...'),
          ],
        ),
      ),
    );

    Map<String, dynamic> relatedData;
    try {
      relatedData = await _userDataService.getUserRelatedData(userId);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 關閉載入
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('查詢關聯資料失敗: $e')));
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // 關閉載入

    final related = relatedData['related'] as Map<String, dynamic>;

    // 顯示關聯資料確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text('刪除「$displayName」', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '以下所有資料將一併永久刪除，此操作無法復原：',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _relatedDataRow(
                Icons.fingerprint,
                '打卡記錄',
                related['attendance_records'] as int,
              ),
              _relatedDataRow(
                Icons.request_quote,
                '估價設定（建立者）',
                related['quote_configurations'] as int,
              ),
              _relatedDataRow(
                Icons.person_search,
                '估價設定（客戶角色）',
                related['quote_as_customer'] as int,
                isSetNull: true,
              ),
              _relatedDataRow(
                Icons.devices,
                '設備設定',
                related['device_configurations'] as int,
              ),
              _relatedDataRow(
                Icons.home_work,
                '智慧型評估表',
                related['assessment_forms'] as int,
              ),
              _relatedDataRow(
                Icons.folder_special,
                '建立的案件',
                related['project_cases_created'] as int,
              ),
              _relatedDataRow(
                Icons.bookmark,
                '建立的快照',
                related['quote_snapshots_created'] as int,
              ),
              _relatedDataRow(
                Icons.devices_other,
                '活躍 Session',
                related['active_sessions'] as int,
              ),
              if (related['has_customer_record'] == true)
                _relatedDataRow(Icons.contact_page, '客戶記錄', 1),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '確定要刪除「$displayName」的帳號嗎？',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('確認刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _userDataService.deleteUser(userId);
      setState(() {
        _allUsers.removeWhere((u) => u['id'].toString() == userId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已成功刪除「$displayName」的帳號及所有關聯資料')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刪除失敗: $e')));
      }
    }
  }

  Widget _relatedDataRow(
    IconData icon,
    String label,
    int count, {
    bool isSetNull = false,
  }) {
    final hasData = count > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: hasData ? Colors.orange : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: hasData ? null : Colors.grey.shade500),
            ),
          ),
          if (isSetNull)
            Text(
              '(將設為空)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          else
            Text(
              hasData ? '$count 筆' : '無',
              style: TextStyle(
                fontWeight: hasData ? FontWeight.bold : null,
                color: hasData ? Colors.orange.shade700 : Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }


  Widget _detailRow(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label：', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value.toString(), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('帳號管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理',
            onPressed: _isLoading ? null : _loadAllUsers,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋姓名或 Email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '共 ${filtered.length} 筆',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                ...[
                  ('全部', null),
                  ('用戶', Colors.grey),
                  ('員工', Colors.blue),
                  ('管理員', Colors.red),
                ].map((pair) {
                  final count = pair.$1 == '全部'
                      ? _allUsers.length
                      : _allUsers
                            .where((u) => _roleLabels[u['role']] == pair.$1)
                            .length;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: Text(
                        '${pair.$1} $count',
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: pair.$2 != null
                          ? (pair.$2 as Color).withValues(alpha: 0.1)
                          : null,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
              ],
            ),
          ),
          if (_isLoading && _allUsers.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_allUsers.isEmpty)
            const Expanded(child: Center(child: Text('尚無帳號資料')))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  final role = user['role'] as String?;
                  final isActive = user['is_active'];
                  final inactive = isActive == 0 || isActive == false;
                  final displayName =
                      user['chinese_name'] ?? user['name'] ?? '未知';
                  final email = user['email'] ?? '';

                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (_roleColors[role] ?? Colors.grey)
                            .withValues(alpha: 0.15),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: _roleColors[role] ?? Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              color: inactive ? Colors.grey : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRoleChip(role),
                          if (inactive) ...[
                            const SizedBox(width: 4),
                            const Chip(
                              label: Text(
                                '離職',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                ),
                              ),
                              backgroundColor: Color(0x1AFF9800),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        email,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: role == 'customer'
                          ? Tooltip(
                              message: '升級為員工',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _changeRole(user, 'employee'),
                              ),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => _showUserDetail(user),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
