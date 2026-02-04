import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/services/user_data_service.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';

class StaffDataPage extends StatefulWidget {
  const StaffDataPage({super.key});

  @override
  State<StaffDataPage> createState() => _StaffDataPageState();
}

class _StaffDataPageState extends State<StaffDataPage> {
  final UserDataService _userDataService = UserDataService();
  final _formKey = GlobalKey<FormState>();

  // 表單控制器
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _chineseNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    html.document.title = '我的資料';
    _loadCurrentUserData();
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

  Future<void> _loadCurrentUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _userDataService.getCurrentUserData();
      _fillFormWithUserData(userData);
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('載入用戶資料失敗: $e')));
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

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'chinese_name': _chineseNameController.text,
        'job_title': _jobTitleController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'bank_account': _bankAccountController.text,
      };

      await _userDataService.updateCurrentUserData(updateData);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('資料更新成功')));
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新失敗: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的資料'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 用戶資料表單
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '個人資料',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    if (!_isEditing)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() => _isEditing = true);
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text('編輯'),
                                      ),
                                    if (_isEditing)
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(
                                                () => _isEditing = false,
                                              );
                                              _loadCurrentUserData();
                                            },
                                            child: const Text('取消'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: _updateUserData,
                                            icon: const Icon(Icons.save),
                                            label: const Text('保存'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 帳號名稱（不可編輯）
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

                                // Email（不可編輯）
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
                                  enabled: _isEditing,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '請輸入中文姓名';
                                    }
                                    return null;
                                  },
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
                                  enabled: _isEditing,
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
                                  enabled: _isEditing,
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
                                  enabled: _isEditing,
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
                                  enabled: _isEditing,
                                ),
                              ],
                            ),
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
