import 'package:flutter/material.dart';

class Step3Widget extends StatelessWidget {
  final TextEditingController powerSupplyController;
  final TextEditingController boardMaterialsController;
  final TextEditingController wiringController;

  const Step3Widget({
    super.key,
    required this.powerSupplyController,
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
        TextField(
          controller: powerSupplyController,
          decoration: const InputDecoration(
            labelText: '電源供應配置',
            border: OutlineInputBorder(),
            hintText: '例如：12V/5A電源供應器 x 2',
          ),
          maxLines: 2,
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