import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DrivePage extends StatelessWidget {
  const DrivePage({super.key});

  Future<void> _launchDrive() async {
    final Uri url = Uri.parse('https://drive.google.com/drive/folders/1KAwWpAqFOA6CqaQ508yQVm3B_zIlcGpr?usp=drive_link');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('雲端硬碟'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              '雲端硬碟',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '點擊下方按鈕在新標籤頁中打開 Google Drive',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _launchDrive,
              icon: const Icon(Icons.open_in_new),
              label: const Text('在新標籤頁中打開'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}