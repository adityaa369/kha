import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';
import 'package:khatha/data/repositories/loan_repository.dart';
import 'package:khatha/core/widgets/looping_avatar.dart';

class ProfileAvatar extends StatefulWidget {
  final String? profileImageId;
  final String? gender;

  const ProfileAvatar({super.key, this.profileImageId, this.gender});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Uint8List? _bytes;

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
    try {
      final repo = context.read<LoanRepository>();
      final docResp = await repo.getSignedDocumentUrl(widget.profileImageId!);
      if (mounted) {
        setState(() => _bytes = docResp.bytes);
      }
    } catch (e) {
      // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Container(
        width: 72.w,
        height: 72.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: MemoryImage(_bytes!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return LoopingAvatar(gender: widget.gender, height: 72.w);
  }
}
