import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

const apiBaseUrl = 'http://10.0.2.2:8000';

void main() => runApp(const ConsentApp());

class ConsentApp extends StatelessWidget {
  const ConsentApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MASRY HEX STOR',
    theme: ThemeData.dark(useMaterial3: true),
    home: const HomePage(),
  );
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
  String status = 'اضغط للسماح بالوصول إلى الصور والفيديوهات';

  Future<bool> requestPhotoAccess() async {
    PermissionStatus result;
    if (Platform.isIOS) {
      result = await Permission.photos.request();
    } else {
      result = await Permission.photos.request();
    }
    if (result.isGranted || result.isLimited) return true;
    if (result.isPermanentlyDenied) await openAppSettings();
    return false;
  }

  Future<void> allowAndChoosePhotos() async {
    final allowed = await requestPhotoAccess();
    if (!mounted) return;
    if (!allowed) {
      setState(() => status = 'لم يتم منح صلاحية الصور');
      return;
    }
    final photos = await picker.pickMultiImage();
    if (!mounted) return;
    setState(() {
      selected = photos;
      status = photos.isEmpty ? 'لم يتم اختيار صور' : 'تم اختيار ${photos.length} صورة';
    });
  }

  Future<void> uploadPhotos() async {
    if (selected.isEmpty || uploading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد مشاركة الصور'),
        content: Text('سيتم إرسال ${selected.length} صورة اخترتها أنت إلى السيرفر. لا يتم إرسال أي صورة دون موافقتك. هل توافق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('موافقة وإرسال')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() { uploading = true; status = 'جاري إرسال الصور...'; });
    int done = 0;
    for (final photo in selected) {
      try {
        final req = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/upload'));
        req.files.add(await http.MultipartFile.fromPath('file', photo.path));
        final res = await req.send();
        if (res.statusCode == 200) done++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() { uploading = false; status = 'تم إرسال $done من ${selected.length} صورة'; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080808),
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 18),
        const Text('MASRY HEX STOR', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 6),
        const Text('CONSENT PHOTO UPLOADER', style: TextStyle(fontSize: 12, letterSpacing: 3)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent), color: const Color(0xFF141414)),
          child: const Column(children: [
            Icon(Icons.photo_library_outlined, size: 48),
            SizedBox(height: 10),
            Text('الوصول إلى الصور والفيديوهات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('سيطلب التطبيق صلاحية الصور الرسمية من نظام Android أو iOS. الإرسال إلى السيرفر لا يتم إلا بعد موافقتك.', textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: uploading ? null : allowAndChoosePhotos, icon: const Icon(Icons.lock_open), label: const Text('السماح بالوصول إلى الصور'))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: uploading ? null : uploadPhotos, icon: const Icon(Icons.cloud_upload), label: const Text('موافقة وإرسال الصور'))),
        const SizedBox(height: 14),
        Text(status, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        Expanded(child: GridView.builder(
          itemCount: selected.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(selected[i].path), fit: BoxFit.cover)),
        )),
        const Text('MASRY HEX • USER CONTROLLED SHARING', style: TextStyle(fontSize: 10, letterSpacing: 1.2)),
      ]),
    )),
  );
}
