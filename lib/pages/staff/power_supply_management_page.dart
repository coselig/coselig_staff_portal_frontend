import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'package:coselig_staff_portal/pages/staff/generic_management_page.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:flutter/material.dart';

final powerSupplyConfig = {
  'title': '電源供應器管理',
  'table': 'power_supply_options',
  'columns': [
    {'name': 'name', 'label': '名稱', 'type': 'text'},
    {'name': 'wattage', 'label': '瓦數', 'type': 'number'},
    {
      'name': 'type',
      'label': '類型',
      'type': 'dropdown',
      'options': ['UHP', 'HLG'],
    },
    {
      'name': 'inputVoltage',
      'label': '輸入電壓',
      'type': 'dropdown',
      'options': ['110', '220', '110/220'],
    },
    {'name': 'price', 'label': '價格', 'type': 'number'},
  ],
  'fetch': (QuoteService service) async {
    final raw = await service.fetchAllPowerSupplyOptions();
    return raw.map((item) {
      final supportsBoth =
          item['supportsBothInputs'] == true ||
          item['supports_both_inputs'] == 1;
      return {
        ...item,
        'inputVoltage': supportsBoth
            ? '110/220'
            : (item['inputVoltage'] ?? item['input_voltage']).toString(),
      };
    }).toList();
  },
  'add': (QuoteService service, Map<String, dynamic> data) =>
      service.addPowerSupplyOption(
        PowerSupply(
          name: data['name'],
          wattage: data['wattage'],
          type: data['type'].toString().toUpperCase(),
          inputVoltage: data['inputVoltage'].toString() == '220' ? 220 : 110,
          supportsBothInputs: data['inputVoltage'].toString() == '110/220',
          price: data['price'],
        ),
      ),
  'update': (QuoteService service, int id, Map<String, dynamic> data) =>
      service.updatePowerSupplyOption(id, {
        'name': data['name'],
        'wattage': data['wattage'],
        'type': data['type'].toString().toUpperCase(),
        'inputVoltage': data['inputVoltage'].toString() == '220' ? 220 : 110,
        'supportsBothInputs': data['inputVoltage'].toString() == '110/220',
        'price': data['price'],
      }),
  'delete': (QuoteService service, int id) =>
      service.deletePowerSupplyOption(id),
};

class PowerSupplyManagementPage extends StatelessWidget {
  const PowerSupplyManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericManagementPage(config: powerSupplyConfig);
  }
}
