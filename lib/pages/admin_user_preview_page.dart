import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/services/user_data_service.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';

class AdminUserPreviewPage extends StatefulWidget {
  const AdminUserPreviewPage({super.key});

  @override
  State<AdminUserPreviewPage> createState() => _AdminUserPreviewPageState();
}

class _AdminUserPreviewPageState extends State<AdminUserPreviewPage> {
  final UserDataService _userDataService = UserDataService();
  
  // 表單控制器
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _chineseNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedUserId;
  List<Map<String, dynamic>> _allUsers = [];
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    html.document.title = '用戶資料預覽';
    _loadAllUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _chineseNameController.dispose();
    _emailController.dispose();
    _jobTitleController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bankAccountController.dispose();
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
          SnackBar(content: Text('載入用戶列表失敗: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserDataById(String userId) async {
    setState(() => _isLoading = true);
    try {
      final userData = await _userDataService.getUserDataById(userId);
      _fillFormWithUserData(userData);
      setState(() {
        _selectedUserId = userId;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入用戶資料失敗: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _fillFormWithUserData(Map<String, dynamic> userData) {
    _nameController.text = userData['name'] ?? '';
    _chineseNameController.text = userData['chinese_name'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _jobTitleController.text = userData['job_title'] ?? '';
    _phoneController.text = userData['phone'] ?? '';
    _addressController.text = userData['address'] ?? '';
    _bankAccountController.text = userData['bank_account'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用戶資料預覽（管理員）'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading && _allUsers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 用戶選擇下拉選單
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '選擇用戶',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _showInactive,
                                    onChanged: (value) {
                                      setState(() {
                                        _showInactive = value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('顯示離職員工'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedUserId,
                                hint: const Text('請選擇用戶'),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: _allUsers
                                    .where((user) {
                                      // 過濾離職員工
                                      if (!_showInactive) {
                                        final isActive = user['is_active'];
                                        // is_active 可能是 int (0/1) 或 bool
                                        if (isActive == 0 ||
                                            isActive == false) {
                                          return false;
                                        }
                                      }
                                      return true;
                                    })
                                    .map((user) {
                                      final isActive = user['is_active'];
                                      final statusText =
                                          (isActive == 0 || isActive == false)
                                          ? ' (離職)'
                                          : '';
                                  return DropdownMenuItem<String>(
                                    value: user['id'].toString(),
                                    child: Text(
                                          '${user['chinese_name'] ?? user['name']} (${user['email']})$statusText',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _loadUserDataById(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 用戶資料顯示（唯讀）
                      if (_selectedUserId != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '用戶資料',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                
                                // 帳號名稱
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: '帳號名稱',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                
                                // 中文姓名
                                TextFormField(
                                  controller: _chineseNameController,
                                  decoration: const InputDecoration(
                                    labelText: '中文姓名',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.badge),
                                  ),
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                
                                // 職稱
                                TextFormField(
                                  controller: _jobTitleController,
                                  decoration: const InputDecoration(
                                    labelText: '職稱',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.work),
                                  ),
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                
                                // 電話
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: '電話',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                
                                // 地址
                                TextFormField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    labelText: '地址',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.home),
                                  ),
                                  enabled: false,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                
                                // 銀行帳號
                                TextFormField(
                                  controller: _bankAccountController,
                                  decoration: const InputDecoration(
                                    labelText: '銀行帳號',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.account_balance),
                                  ),
                                  enabled: false,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      // 提示訊息
                      if (_selectedUserId == null) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('請從上方選擇用戶以查看資料'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
