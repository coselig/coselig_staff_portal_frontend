import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/pages/admin/generic_management_page.dart';

final moduleConfig = {
  'title': '模組管理',
  'table': 'module_options',
  'columns': [
    {'name': 'model', 'label': '型號', 'type': 'text'},
    {
      'name': 'brand',
      'label': '品牌',
      'type': 'dropdown',
      'options': ['', '郭先生', 'sunwave', 'matter', 'zigbee'],
    },
    {'name': 'channelCount', 'label': '通道數', 'type': 'number'},
    {
      'name': 'isDimmable',
      'label': '可調光',
      'type': 'dropdown',
      'options': ['true', 'false'],
    },
    {'name': 'maxAmperePerChannel', 'label': '每通道最大安培', 'type': 'number'},
    {'name': 'maxAmpereTotal', 'label': '總安培', 'type': 'number'},
    {'name': 'price', 'label': '價格', 'type': 'number'},
  ],
  'fetch': (QuoteService service) => service.fetchAllModuleOptions(),
  'add': (QuoteService service, Map<String, dynamic> data) =>
      service.addModuleOption(
        ModuleOption(
          model: data['model'],
          brand: data['brand'],
          channelCount: data['channelCount'].toInt(),
          isDimmable: data['isDimmable'].toString().toLowerCase() == 'true',
          maxAmperePerChannel: data['maxAmperePerChannel'],
          maxAmpereTotal: data['maxAmpereTotal'],
          price: data['price'],
        ),
      ),
  'update': (QuoteService service, int id, Map<String, dynamic> data) =>
      service.updateModuleOption(id, {
        'model': data['model'],
        'brand': data['brand'],
        'channelCount': data['channelCount'].toInt(),
        'isDimmable': data['isDimmable'].toString().toLowerCase() == 'true',
        'maxAmperePerChannel': data['maxAmperePerChannel'],
        'maxAmpereTotal': data['maxAmpereTotal'],
        'price': data['price'],
      }),
  'delete': (QuoteService service, int id) => service.deleteModuleOption(id),
};

class ModuleManagementPage extends StatelessWidget {
  const ModuleManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericManagementPage(config: moduleConfig);
  }
}