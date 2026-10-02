import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/theme.dart';

class MultiCameraScreen extends StatefulWidget {
  const MultiCameraScreen({super.key});

  @override
  State<MultiCameraScreen> createState() => _MultiCameraScreenState();
}

class _MultiCameraScreenState extends State<MultiCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  final List<File> _capturedImages = [];
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) setState(() => _isReady = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile photo = await _controller!.takePicture();
      setState(() {
        _capturedImages.add(File(photo.path));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take picture: $e')),
      );
    }
  }

  void _removePicture(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context, _capturedImages),
                  ),
                  Text(
                    '${_capturedImages.length} captured',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _capturedImages),
                    child: const Text('Done', style: TextStyle(color: KhaataTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // Camera Preview
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: CameraPreview(_controller!),
              ),
            ),
            
            // Thumbnail Tray
            if (_capturedImages.isNotEmpty)
              Container(
                height: 80.h,
                margin: EdgeInsets.only(top: 16.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 12.w),
                          width: 60.h,
                          height: 60.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: KhaataTheme.primaryBlue, width: 2),
                            image: DecorationImage(
                              image: FileImage(_capturedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removePicture(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            
            // Shutter Button
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
