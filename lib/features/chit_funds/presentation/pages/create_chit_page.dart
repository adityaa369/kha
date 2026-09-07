import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/blocs/chit_funds/chit_fund_cubit.dart';
import '../../../../core/blocs/chit_funds/chit_fund_state.dart';

class CreateChitGroupPage extends StatefulWidget {
  const CreateChitGroupPage({super.key});

  @override
  State<CreateChitGroupPage> createState() => _CreateChitGroupPageState();
}

class _CreateChitGroupPageState extends State<CreateChitGroupPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  final Color _primaryColor = const Color(0xFF059669);
  final Color _bgColor = const Color(0xFFF8FAFC);
  final Color _textColorDark = const Color(0xFF1F2937);
  final Color _textColorGrey = const Color(0xFF6B7280);
  final Color _borderColor = const Color(0xFFE5E7EB);
  final Color _dangerColor = const Color(0xFFEF4444);

  // Form Fields
  final _formKey = GlobalKey<FormState>();
  String name = '';
  double totalValue = 0;
  int totalMonths = 0;
  double commissionPercent = 5.0;
  String branchName = 'KPHB-CAO';

  double get monthlySubscription =>
      totalMonths > 0 ? totalValue / totalMonths : 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      _formKey.currentState!.save();
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChitFundCubit, ChitFundState>(
      listener: (context, state) {
        if (state is ChitFundActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: _primaryColor,
            ),
          );
          context.pop();
        } else if (state is ChitFundError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: _dangerColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _textColorDark),
            onPressed: () {
              if (_currentStep > 0) {
                _prevStep();
              } else {
                context.pop();
              }
            },
          ),
          title: Text(
            'New Chit Group',
            style: GoogleFonts.inter(
              color: _textColorDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(color: Colors.white, child: _buildStepIndicator()),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 32.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepCircle(0, 'Basics'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Config'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Preview'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepIndex, String label) {
    bool isActive = _currentStep >= stepIndex;
    return Column(
      children: [
        Container(
          width: 24.r,
          height: 24.r,
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? _primaryColor : _borderColor,
              width: 2,
            ),
          ),
          child: isActive
              ? Icon(Icons.check, color: Colors.white, size: 14.r)
              : null,
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? _primaryColor : _textColorGrey,
            fontSize: 12.sp,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int stepIndex) {
    bool isActive = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2.h,
        color: isActive ? _primaryColor : _borderColor,
        margin: EdgeInsets.only(bottom: 24.h), // align with circles
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Details',
              style: GoogleFonts.inter(
                color: _textColorDark,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Set the basic parameters for the chit fund.',
              style: GoogleFonts.inter(color: _textColorGrey, fontSize: 14.sp),
            ),
            SizedBox(height: 32.h),

            _buildLabel('Chit Group Name'),
            TextFormField(
              initialValue: name,
              decoration: _inputDecoration('e.g. Dream Home Fund'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => name = val ?? '',
            ),
            SizedBox(height: 24.h),

            _buildLabel('Total Pot Value (₹)'),
            TextFormField(
              initialValue: totalValue > 0 ? totalValue.toStringAsFixed(0) : '',
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('e.g. 500000'),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (double.tryParse(val) == null || double.parse(val) <= 0)
                  return 'Must be > 0';
                return null;
              },
              onSaved: (val) => totalValue = double.tryParse(val ?? '') ?? 0,
            ),
            SizedBox(height: 24.h),

            _buildLabel('Duration in Months'),
            TextFormField(
              initialValue: totalMonths > 0 ? totalMonths.toString() : '',
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('e.g. 20'),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (int.tryParse(val) == null || int.parse(val) <= 0)
                  return 'Must be > 0';
                return null;
              },
              onSaved: (val) => totalMonths = int.tryParse(val ?? '') ?? 0,
            ),
            SizedBox(height: 48.h),

            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                onPressed: _nextStep,
                child: Text(
                  'Next',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    double exampleBid = totalValue * 0.97;
    double commissionAmt = (totalValue * commissionPercent) / 100;
    double dividend =
        (totalValue - exampleBid - commissionAmt) /
        (totalMonths > 0 ? totalMonths : 1);

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Configuration',
            style: GoogleFonts.inter(
              color: _textColorDark,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 32.h),

          _buildLabel('Monthly Subscription'),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: _borderColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: _textColorGrey, size: 20.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_currencyFormat.format(monthlySubscription)}/month',
                        style: GoogleFonts.inter(
                          color: _textColorDark,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Total Value ÷ Duration = ${_currencyFormat.format(totalValue)} ÷ $totalMonths months',
                        style: GoogleFonts.inter(
                          color: _textColorGrey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Commission %'),
              Text(
                '${commissionPercent.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  color: _primaryColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _primaryColor,
              inactiveTrackColor: _borderColor,
              thumbColor: _primaryColor,
              overlayColor: _primaryColor.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: commissionPercent,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              onChanged: (val) {
                setState(() {
                  commissionPercent = val;
                });
              },
            ),
          ),
          Text(
            'Commission deducted from winning bid before dividend distribution',
            style: GoogleFonts.inter(color: _textColorGrey, fontSize: 12.sp),
          ),
          SizedBox(height: 32.h),

          _buildLabel('Branch Name'),
          TextFormField(
            initialValue: branchName,
            decoration: _inputDecoration('e.g. KPHB-CAO'),
            onChanged: (val) => branchName = val,
          ),
          SizedBox(height: 32.h),

          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Preview (Example)',
                  style: GoogleFonts.inter(
                    color: _textColorDark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Example: Bid ${_currencyFormat.format(exampleBid)} → Commission: ${_currencyFormat.format(commissionAmt)} → Dividend: ${_currencyFormat.format(dividend > 0 ? dividend : 0)}/member',
                  style: GoogleFonts.inter(
                    color: _textColorGrey,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 48.h),

          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              onPressed: _nextStep,
              child: Text(
                'Next',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: _primaryColor, size: 64.r),
          SizedBox(height: 16.h),
          Text(
            'Review & Create',
            style: GoogleFonts.inter(
              color: _textColorDark,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Verify the details before creating the group.',
            style: GoogleFonts.inter(color: _textColorGrey, fontSize: 14.sp),
          ),
          SizedBox(height: 32.h),

          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Group Name', name),
                Divider(color: _borderColor, height: 24.h),
                _buildSummaryRow(
                  'Pot Value',
                  _currencyFormat.format(totalValue),
                ),
                Divider(color: _borderColor, height: 24.h),
                _buildSummaryRow('Duration', '$totalMonths months'),
                Divider(color: _borderColor, height: 24.h),
                _buildSummaryRow(
                  'Monthly Installment',
                  _currencyFormat.format(monthlySubscription),
                ),
                Divider(color: _borderColor, height: 24.h),
                _buildSummaryRow(
                  'Commission',
                  '${commissionPercent.toStringAsFixed(1)}%',
                ),
                Divider(color: _borderColor, height: 24.h),
                _buildSummaryRow('Branch', branchName),
              ],
            ),
          ),
          SizedBox(height: 48.h),

          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // ignore: avoid_dynamic_calls
                (context.read<ChitFundCubit>() as dynamic).createChitGroup(
                  name: name,
                  totalValue: totalValue,
                  totalMonths: totalMonths,
                  commissionPercent: commissionPercent,
                  branchName: branchName,
                );
              },
              child: Text(
                'Create Group & Start Inviting',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: _prevStep,
              child: Text(
                'Edit Details',
                style: GoogleFonts.inter(
                  color: _textColorDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: _textColorGrey, fontSize: 14.sp),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: _textColorDark,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: _textColorDark,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: _textColorGrey.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: _dangerColor),
      ),
    );
  }
}
