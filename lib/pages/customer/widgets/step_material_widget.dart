import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/power_supply.dart';
import 'package:coselig_staff_portal/pages/customer/widgets/power_supply_list_widget.dart';

class StepMaterialWidget extends StatelessWidget {
  final List<PowerSupply> powerSupplies;
  final Function(List<PowerSupply>) onPowerSuppliesChanged;
  final TextEditingController boardMaterialsController;
  final TextEditingController wiringController;

  const StepMaterialWidget({
    super.key,
    required this.powerSupplies,
    required this.onPowerSuppliesChanged,
    required this.boardMaterialsController,
    required this.wiringController,
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
        TextField(
          controller: boardMaterialsController,
          decoration: const InputDecoration(
            labelText: '板材、配電箱配置',
            border: OutlineInputBorder(),
            hintText: '例如：配電箱 400x300x150mm x 1',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: wiringController,
          decoration: const InputDecoration(
            labelText: '線材配置',
            border: OutlineInputBorder(),
            hintText: '例如：2.5mm²電線 50m, 1.5mm²電線 30m',
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}