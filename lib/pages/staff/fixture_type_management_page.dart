import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/pages/staff/generic_management_page.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';

final fixtureTypeConfig = {
  'title': '燈具類型管理',
  'table': 'fixture_type_options',
  'columns': [
    {'name': 'type', 'label': '類型名稱', 'type': 'text'},
    {'name': 'quantityLabel', 'label': '數量標籤', 'type': 'text'},
    {'name': 'unitLabel', 'label': '單位標籤', 'type': 'text'},
    {
      'name': 'isMeterBased',
      'label': '以米計算',
      'type': 'dropdown',
      'options': ['true', 'false'],
    },
    {'name': 'price', 'label': '價格', 'type': 'number'},
    {'name': 'defaultUnitWatt', 'label': '預設每單位瓦數', 'type': 'number'},
  ],
  'fetch': (QuoteService service) => service.fetchAllFixtureTypeOptions(),
  'add': (QuoteService service, Map<String, dynamic> data) =>
      service.addFixtureTypeOption(
        FixtureTypeData(
          type: data['type'],
          quantityLabel: data['quantityLabel'],
          unitLabel: data['unitLabel'],
          isMeterBased: data['isMeterBased'].toString().toLowerCase() == 'true',
          price: data['price'],
          defaultUnitWatt: data['defaultUnitWatt'].toInt(),
        ),
      ),
  'update': (QuoteService service, int id, Map<String, dynamic> data) =>
      service.updateFixtureTypeOption(id, {
        'type': data['type'],
        'quantityLabel': data['quantityLabel'],
        'unitLabel': data['unitLabel'],
        'isMeterBased': data['isMeterBased'].toString().toLowerCase() == 'true',
        'price': data['price'],
        'defaultUnitWatt': data['defaultUnitWatt'].toInt(),
      }),
  'delete': (QuoteService service, int id) =>
      service.deleteFixtureTypeOption(id),
};

class FixtureTypeManagementPage extends StatelessWidget {
  const FixtureTypeManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericManagementPage(config: fixtureTypeConfig);
  }
}
