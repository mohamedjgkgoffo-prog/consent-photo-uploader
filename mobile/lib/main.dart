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

class NeonBackground extends StatelessWidget {
  final Widget child;
  const NeonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(color: const Color(0xFF050505)),
      Positioned(top: -90, right: -70, child: _glow(260, const Color(0xFF8B0000))),
      Positioned(bottom: -100, left: -80, child: _glow(300, const Color(0xFF003A66))),
      Positioned.fill(child: CustomPaint(painter: _GridPainter())),
      child,
    ],
  );

  Widget _glow(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(.18), boxShadow: [BoxShadow(color: color.withOpacity(.28), blurRadius: 90, spreadRadius: 35)]),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(.025)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 28) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();
  List<XFile> selected = [];
  bool uploading = false;
  String status = 'اضغط للسماح بالوصول إلى الصور والفيديوهات';

  Future<bool> requestPhotoAccess() async {
    final result = await Permission.photos.request();
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
    body: NeonBackground(
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: Column(children: [
          const SizedBox(height: 8),
          const Text('MASRY HEX', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const Text('STOR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 7)),
          const SizedBox(height: 5),
          Text('CONSENT PHOTO UPLOADER', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: Colors.white.withOpacity(.65))),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.redAccent.withOpacity(.75)),
              color: Colors.black.withOpacity(.55),
              boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(.08), blurRadius: 24)],
            ),
            child: const Column(children: [
              Icon(Icons.shield_outlined, size: 48),
              SizedBox(height: 9),
              Text('MASRY HEX STOR', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              SizedBox(height: 7),
              Text('الوصول إلى الصور والفيديوهات يتم من خلال صلاحية النظام الرسمية. الإرسال إلى السيرفر لا يتم إلا بعد موافقتك.', textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 15),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: uploading ? null : allowAndChoosePhotos, icon: const Icon(Icons.photo_library_outlined), label: const Text('السماح بالوصول إلى الصور'))),
          const SizedBox(height: 9),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: uploading ? null : uploadPhotos, icon: const Icon(Icons.cloud_upload_outlined), label: const Text('موافقة وإرسال الصور'))),
          const SizedBox(height: 10),
          Text(status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          Expanded(child: GridView.builder(
            itemCount: selected.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 7, mainAxisSpacing: 7),
            itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(selected[i].path), fit: BoxFit.cover)),
          )),
          Text('MASRY HEX • USER CONTROLLED SHARING', style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: Colors.white.withOpacity(.5))),
        ]),
      )),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
