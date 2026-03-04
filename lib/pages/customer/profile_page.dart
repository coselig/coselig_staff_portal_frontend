import 'package:coselig_staff_portal/services/user_data_service.dart';
import 'package:coselig_staff_portal/services/customer_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserDataService();

  final _chineseNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bankAccountController = TextEditingController();

  final _companyController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _notesController = TextEditingController();

  bool _loading = true;
  int? _customerId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final customerService = Provider.of<CustomerService>(context, listen: false);

      final user = await _userService.getCurrentUserData();
      _chineseNameController.text = user['chinese_name'] ?? '';
      _jobTitleController.text = user['job_title'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _addressController.text = user['address'] ?? '';
      _bankAccountController.text = user['bank_account'] ?? '';

      await customerService.fetchCustomers();
      final customers = customerService.customers;
      if (customers.isNotEmpty) {
        final c = customers.firstWhere((c) => c.userId.toString() == auth.userId, orElse: () => customers.first);
        _customerId = c.id;
        _companyController.text = c.company ?? '';
        _taxIdController.text = c.taxId ?? '';
        _contactPersonController.text = c.contactPerson ?? '';
        _notesController.text = c.notes ?? '';
        _isActive = c.isActive;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('載入個人資料失敗: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _userService.updateCurrentUserData({
        'chinese_name': _chineseNameController.text.trim(),
        'job_title': _jobTitleController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'bank_account': _bankAccountController.text.trim(),
      });

      if (_customerId != null) {
        final customerService = Provider.of<CustomerService>(context, listen: false);
        final success = await customerService.updateCustomer(_customerId!, {
          'company': _companyController.text.trim(),
          'tax_id': _taxIdController.text.trim(),
          'contact_person': _contactPersonController.text.trim(),
          'notes': _notesController.text.trim(),
          'is_active': _isActive,
        });
        if (!success) throw Exception('更新客戶資料失敗');
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('個人資料已儲存')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('儲存失敗: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _chineseNameController.dispose();
    _jobTitleController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bankAccountController.dispose();
    _companyController.dispose();
    _taxIdController.dispose();
    _contactPersonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人資料設定'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('個人資訊', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _chineseNameController,
                      decoration: const InputDecoration(labelText: '中文名'),
                    ),
                    TextFormField(
                      controller: _jobTitleController,
                      decoration: const InputDecoration(labelText: '職稱'),
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: '電話'),
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: '地址'),
                    ),
                    TextFormField(
                      controller: _bankAccountController,
                      decoration: const InputDecoration(labelText: '銀行帳號'),
                    ),
                    const SizedBox(height: 16),
                    const Text('公司 / 客戶欄位', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(labelText: '公司'),
                    ),
                    TextFormField(
                      controller: _taxIdController,
                      decoration: const InputDecoration(labelText: '統一編號'),
                    ),
                    TextFormField(
                      controller: _contactPersonController,
                      decoration: const InputDecoration(labelText: '聯絡人'),
                    ),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: '備註'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('啟用客戶紀錄'),
                        Switch(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: const Text('儲存'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
