import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = 'http://10.0.2.2:8000'; // Android emulator.
                                           // Replace with your server URL on a real phone.

void main() => runApp(const ConsentApp());

class ConsentApp extends StatelessWidget {
  const ConsentApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Uploader',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();
  List<XFile> selected = [];
  bool uploading = false;
  String status = '';

  Future<void> choosePhotos() async {
    final photos = await picker.pickMultiImage();
    if (!mounted) return;
    setState(() {
      selected = photos;
      status = photos.isEmpty ? 'لم يتم اختيار صور.' : 'تم اختيار ${photos.length} صورة.';
    });
  }

  Future<void> uploadPhotos() async {
    if (selected.isEmpty || uploading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الرفع'),
        content: Text(
          'سيتم إرسال ${selected.length} صورة اخترتها إلى السيرفر. '
          'هل توافق على رفعها؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('موافقة ورفع')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() { uploading = true; status = 'جاري الرفع...'; });

    int done = 0;
    for (final photo in selected) {
      final req = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/upload'));
      req.files.add(await http.MultipartFile.fromPath('file', photo.path));
      final res = await req.send();
      if (res.statusCode == 200) done++;
    }

    if (!mounted) return;
    setState(() {
      uploading = false;
      status = 'تم رفع $done من ${selected.length} صورة.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رفع الصور بموافقة المستخدم')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'التطبيق لا يرفع صورًا تلقائيًا. اختر الصور بنفسك ثم وافق على إرسالها.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: uploading ? null : choosePhotos,
              icon: const Icon(Icons.photo_library),
              label: const Text('اختيار الصور'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: uploading ? null : uploadPhotos,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('رفع الصور المختارة'),
            ),
            const SizedBox(height: 20),
            Text(status),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: selected.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
                ),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(selected[i].path), fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
