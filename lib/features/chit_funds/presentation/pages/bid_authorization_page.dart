import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';

class BidAuthorizationPage extends StatelessWidget {
  const BidAuthorizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: KhaataTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bid Authorization',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        itemCount: 2,
        itemBuilder: (context, index) {
          return const _BidAuthCard();
        },
      ),
    );
  }
}

class _BidAuthCard extends StatelessWidget {
  const _BidAuthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: KhaataTheme.cardWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: KhaataTheme.borderGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'SRINATH KAMIREDDY',
            style: TextStyle(
              color: KhaataTheme.textDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 24.h),
          const _InfoRow(label: 'Branch Name', value: 'KPHB-CAO'),
          SizedBox(height: 12.h),
          const _InfoRow(label: 'Chit Number', value: 'KKPT47J-26'),
          SizedBox(height: 12.h),
          const _InfoRow(label: 'Auction Date', value: '21-Jun-2025'),
          SizedBox(height: 12.h),
          const _InfoRow(label: 'Chit Value', value: '₹ 5,00,000'),
          SizedBox(height: 24.h),
          SizedBox(
            width: 140.w,
            height: 44.h,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bid Authorized Successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KhaataTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Authorize',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: TextStyle(
              color: KhaataTheme.textDark,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '   :   ',
          style: TextStyle(
            color: KhaataTheme.textGrey,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: KhaataTheme.textGrey,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
