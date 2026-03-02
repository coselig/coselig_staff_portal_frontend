import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/power_supply.dart';
import 'package:coselig_staff_portal/models/quote/material_item.dart';
import 'package:coselig_staff_portal/pages/customer/widgets/power_supply_list_widget.dart';
import 'package:coselig_staff_portal/pages/customer/widgets/item_list_widget.dart';

class StepMaterialWidget extends StatelessWidget {
  final List<PowerSupply> powerSupplies;
  final Function(List<PowerSupply>) onPowerSuppliesChanged;
  final List<MaterialItem> boardMaterials;
  final Function(List<MaterialItem>) onBoardMaterialsChanged;
  final List<MaterialItem> wiringItems;
  final Function(List<MaterialItem>) onWiringItemsChanged;

  const StepMaterialWidget({
    super.key,
    required this.powerSupplies,
    required this.onPowerSuppliesChanged,
    required this.boardMaterials,
    required this.onBoardMaterialsChanged,
    required this.wiringItems,
    required this.onWiringItemsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '材料配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        PowerSupplyListWidget(
          powerSupplies: powerSupplies,
          onChanged: onPowerSuppliesChanged,
        ),
        const SizedBox(height: 16),
        ItemListWidget(
          title: '板材、配電箱配置',
          items: boardMaterials,
          onChanged: onBoardMaterialsChanged,
          addTooltip: '新增板材/配電箱項目',
        ),
        const SizedBox(height: 16),
        ItemListWidget(
          title: '線材配置',
          items: wiringItems,
          onChanged: onWiringItemsChanged,
          addTooltip: '新增線材項目',
        ),
      ],
    );
  }
}