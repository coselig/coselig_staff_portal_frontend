import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      startScan();
    }
  }

  void startScan() async {
    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('附近低功耗藍芽裝置'),
      ),
      body: kIsWeb
          ? _buildWebBody()
          : _buildMobileBody(),
    );
  }

  Widget _buildWebBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '網頁版 BLE 掃描',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            '此功能需要在支持 Web Bluetooth API 的瀏覽器中使用。\n'
            '請確保您使用 Chrome 或 Edge 瀏覽器，並且已啟用藍芽權限。',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isScanning ? null : startScan,
            child: Text(isScanning ? '掃描中...' : '開始掃描 BLE 裝置'),
          ),
          const SizedBox(height: 20),
          if (scanResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final result = scanResults[index];
                  final device = result.device;
                  return ListTile(
                    title: Text(device.platformName.isNotEmpty ? device.platformName : '未知裝置'),
                    subtitle: Text(device.remoteId.toString()),
                    trailing: Text('${result.rssi} dBm'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: isScanning ? null : startScan,
            child: Text(isScanning ? '掃描中...' : '重新掃描'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: scanResults.length,
            itemBuilder: (context, index) {
              final result = scanResults[index];
              final device = result.device;
              return ListTile(
                title: Text(device.platformName.isNotEmpty ? device.platformName : '未知裝置'),
                subtitle: Text(device.remoteId.toString()),
                trailing: Text('${result.rssi} dBm'),
              );
            },
          ),
        ),
      ],
    );
  }
}
