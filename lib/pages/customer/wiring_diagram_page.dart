import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';

class WiringDiagramPage extends StatelessWidget {
  final List<PowerSupply> powerSupplies;
  final List<Module> modules;
  final List<Loop> loops;

  const WiringDiagramPage({
    super.key,
    required this.powerSupplies,
    required this.modules,
    required this.loops,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配線圖預覽'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 1200,
              height: 800,
              child: CustomPaint(
                painter: _WiringDiagramPainter(
                  powerSupplies: powerSupplies,
                  modules: modules,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WiringDiagramPainter extends CustomPainter {
  final List<PowerSupply> powerSupplies;
  final List<Module> modules;

  _WiringDiagramPainter({required this.powerSupplies, required this.modules});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Layout: power supplies (top), modules (middle), loops (below modules)
    final double topY = 40;
    final double midY = size.height / 2.5;
    final double botYStart = midY + 120;

    // Draw power supplies
    final psCount = powerSupplies.isEmpty ? 1 : powerSupplies.length;
    for (int i = 0; i < psCount; i++) {
      final x = (i + 0.5) * (size.width / psCount);
      final rect = Rect.fromCenter(center: Offset(x, topY), width: 160, height: 48);
      paint.color = Colors.green.shade700;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
      // label
      final label = i < powerSupplies.length ? powerSupplies[i].name : 'PS';
      textPainter.text = TextSpan(text: label, style: const TextStyle(color: Colors.black, fontSize: 12));
      textPainter.layout(minWidth: 0, maxWidth: 160);
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, topY - textPainter.height / 2));
    }

    // Draw modules
    final moduleCount = modules.isEmpty ? 1 : modules.length;
    for (int i = 0; i < moduleCount; i++) {
      final x = (i + 0.5) * (size.width / moduleCount);
      final rect = Rect.fromCenter(center: Offset(x, midY), width: 200, height: 64);
      paint.color = Colors.blue.shade700;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);

      final m = i < modules.length ? modules[i] : null;
      final label = m != null
          ? '${m.brand.isNotEmpty ? '[${m.brand}] ' : ''}${m.model}'
          : 'Module';
      textPainter.text = TextSpan(text: label, style: const TextStyle(color: Colors.black, fontSize: 12));
      textPainter.layout(minWidth: 0, maxWidth: 200);
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, midY - textPainter.height / 2));

      // Draw lines from a power supply to this module (round-robin assignment for visualization)
      if (powerSupplies.isNotEmpty) {
        final psIndex = i % powerSupplies.length;
        final psX = (psIndex + 0.5) * (size.width / psCount);
        final start = Offset(psX, topY + 24);
        final end = Offset(x, midY - 32);
        paint.color = Colors.grey.shade700;
        canvas.drawLine(start, end, paint);
      }

      // Draw loops under module
      final loops = m?.loopAllocations ?? [];
      final loopCount = loops.length;
      final spacing = loopCount <= 1 ? 0 : 40.0;
      final baseX = x - (spacing * (loopCount - 1) / 2);
      for (int li = 0; li < loopCount; li++) {
        final lx = baseX + li * spacing;
        final ly = botYStart + (li ~/ 10) * 60; // wrap rows if many
        // draw small circle
        paint.color = Colors.orange.shade700;
        canvas.drawCircle(Offset(lx, ly), 12, paint);
        // draw line from module to loop
        paint.color = Colors.grey.shade700;
        canvas.drawLine(Offset(x, midY + 32), Offset(lx, ly - 12), paint);
        // label
        final lname = loops[li].loop.name;
        textPainter.text = TextSpan(text: lname, style: const TextStyle(color: Colors.black, fontSize: 11));
        textPainter.layout(minWidth: 0, maxWidth: 120);
        textPainter.paint(canvas, Offset(lx - textPainter.width / 2, ly + 14));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
