import 'quote_models.dart';

class LoopInfo {
  final Loop loop;
  final int channels;
  final double ampere;
  final double amperePerCh;
  final bool isRelay;

  const LoopInfo({
    required this.loop,
    required this.channels,
    required this.ampere,
    required this.amperePerCh,
    required this.isRelay,
  });
}
