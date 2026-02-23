import 'package:coselig_staff_portal/models/quote_models.dart';
import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/pages/admin/generic_management_page.dart';

final switchConfig = {
  'title': '開關管理',
  'table': 'switch_options',
  'columns': [
    {'name': 'name', 'label': '名稱', 'type': 'text'},
    {'name': 'count', 'label': '數量', 'type': 'number'},
    {'name': 'price', 'label': '價格', 'type': 'number'},
    {'name': 'location', 'label': '位置', 'type': 'text'},
  ],
  'fetch': (QuoteService service) => service.fetchSwitchOptions(),
  'add': (QuoteService service, Map<String, dynamic> data) =>
      service.addSwitchOption(
        SwitchModel(
          name: data['name'],
          count: data['count'].toInt(),
          price: data['price'],
          location: data['location'],
        ),
      ),
  'update': (QuoteService service, int id, Map<String, dynamic> data) =>
      service.updateSwitchOption(
        id,
        SwitchModel(
          id: id,
          name: data['name'],
          count: data['count'].toInt(),
          price: data['price'],
          location: data['location'],
        ),
      ),
  'delete': (QuoteService service, int id) => service.deleteSwitchOption(id),
};

class SwitchManagementPage extends StatelessWidget {
  const SwitchManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericManagementPage(config: switchConfig);
  }
}
