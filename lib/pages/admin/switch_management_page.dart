import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/pages/admin/generic_management_page.dart';

final switchConfig = {
  'title': '開關管理',
  'table': 'switch_options',
  'columns': [
    {'name': 'name', 'label': '名稱', 'type': 'text'},
    {'name': 'price', 'label': '價格', 'type': 'number'},
    {'name': 'count', 'label': '切數(開關數量)', 'type': 'number'},
    {
      'name': 'fireType',
      'label': '單火/零火',
      'type': 'dropdown',
      'options': ['單火', '零火'],
    },
    {
      'name': 'networkable',
      'label': '是否可以聯網',
      'type': 'dropdown',
      'options': ['是', '否'],
    },
    {
      'name': 'protocol',
      'label': '協定類型',
      'type': 'dropdown',
      'options': ['MQTT', 'zigbee', '藍芽', 'matter'],
    },
    {'name': 'color', 'label': '顏色', 'type': 'text'},
    {
      'name': 'sceneCapable',
      'label': '支援場景開關',
      'type': 'dropdown',
      'options': ['是', '否'],
    },
  ],
  'fetch': (QuoteService service) => service.fetchSwitchOptions(),
  'add': (QuoteService service, Map<String, dynamic> data) =>
      service.addSwitchOption(
        SwitchModel(
          name: data['name'],
          price: data['price'],
          count: data['count'].toInt(),
          fireType: data['fireType'] ?? '',
          networkable: data['networkable'] == '是',
          protocol: data['protocol'] ?? '',
          color: data['color'] ?? '',
          sceneCapable: data['sceneCapable'] == '是',
        ),
      ),
  'update': (QuoteService service, int id, Map<String, dynamic> data) =>
      service.updateSwitchOption(
        id,
        SwitchModel(
          id: id,
          name: data['name'],
          price: data['price'],
          count: data['count'].toInt(),
          fireType: data['fireType'] ?? '',
          networkable: data['networkable'] == '是',
          protocol: data['protocol'] ?? '',
          color: data['color'] ?? '',
          sceneCapable: data['sceneCapable'] == '是',
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
