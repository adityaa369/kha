import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';

class PersonalDetailsPage extends StatelessWidget {
  const PersonalDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: KhaataTheme.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Step 1 of 3', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            SizedBox(height: 20.h),

            Center(
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: KhaataTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: KhaataTheme.accentGreen,
                  size: 40.sp,
                ),
              ),
            ),
            SizedBox(height: 32.h),

            Text(
              "Let's get you started",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              'No Spam. Just Credit Insights',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 40.h),

            KhaataTextField(
              label: 'First Name',
              hint: 'Enter first name',
              controller: TextEditingController(text: 'Aditya'),
            ),
            SizedBox(height: 20.h),
            KhaataTextField(
              label: 'Last Name',
              hint: 'Enter last name',
              controller: TextEditingController(text: 'Amruthaluri'),
            ),
            SizedBox(height: 20.h),
            KhaataTextField(
              label: 'Email Address',
              hint: 'Enter email',
              controller: TextEditingController(text: 'adityawork41@gmail.com'),
              keyboardType: TextInputType.emailAddress,
            ),

            SizedBox(height: 24.h),

            // Info Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: KhaataTheme.primaryBlue),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Your privacy is our priority. Rest assured, we never share your information.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: KhaataTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40.h),

            PrimaryButton(
              text: 'Continue',
              onPressed: () => context.push(AppConstants.panDetails),
            ),
          ],
        ),
      ),
    );
  }
}