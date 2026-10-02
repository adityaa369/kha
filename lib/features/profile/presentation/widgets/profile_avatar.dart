import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:khatha/data/repositories/loan_repository.dart';

class ProfileAvatar extends StatefulWidget {
  final String? profileImageId;

  final double? size;
  const ProfileAvatar({super.key, this.profileImageId, this.size});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileImageId != widget.profileImageId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.profileImageId == null || widget.profileImageId!.isEmpty) {
      if (mounted) setState(() => _bytes = null);
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final repo = context.read<LoanRepository>();
      final docResp = await repo.getSignedDocumentUrl(widget.profileImageId!);
      if (mounted) {
        setState(() {
          _bytes = docResp.bytes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 88.w;
    return Stack(
      children: [
        // Circle background + image or icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            image: _bytes != null
                ? DecorationImage(
                    image: ResizeImage(MemoryImage(_bytes!), width: 300),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _bytes == null
                  ? Icon(
                      Icons.person,
                      size: size * 0.55,
                      color: Colors.grey.shade500,
                    )
                  : null,
        ),

        ],
    );
  }
}
