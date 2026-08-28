import re

with open('lib/features/loans/presentation/widgets/flexible_payment_sheet.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'package:intl/intl.dart';", "import 'package:intl/intl.dart';\nimport 'package:firebase_auth/firebase_auth.dart';")

state_vars = '''  int _step = 0; // 0: Amount, 1: OTP, 2: Success
  bool _isLoading = false;
  
  final _amountCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _currencyFmt = NumberFormat('#,##0', 'en_IN');
  String _verificationId = '';'''

content = re.sub(r'  int _step = 0;.*?final _currencyFmt = NumberFormat\(''#,##0'', ''en_IN''\);', state_vars, content, flags=re.DOTALL)

content = content.replace('_amountCtrl.dispose();', '_amountCtrl.dispose();\n    _otpCtrl.dispose();')

process_payment = '''  Future<void> _processPayment() async {
    if (_enteredAmount <= 0) return;
    
    setState(() => _isLoading = true);

    if (widget.actionType == 'add_credit') {
      await _verifyAndApply('');
      return;
    }

    try {
      final phone = '+91\';
      if (phone.length < 13) throw Exception('Invalid borrower phone number');
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ErrorHandler.showError(context, e.message ?? 'Verification failed');
        },
        codeSent: (verificationId, forceResendingToken) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
            _step = 1;
          });
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, 'Failed to send OTP: \');
    }
  }

  Future<void> _verifyAndApply(String otp) async {
    setState(() => _isLoading = true);
    final cubit = context.read<LoanCubit>();
    bool success = false;

    try {
      if (widget.actionType == 'record_payment') {
        success = await cubit.recordPayment(widget.loan.id, (_enteredAmount * 100).toInt(), otp, _verificationId);
      } else if (widget.actionType == 'add_credit') {
        success = await cubit.addCredit(widget.loan.id, (_enteredAmount * 100).toInt());
      } else if (widget.actionType == 'record_interest') {
        success = await cubit.recordInterest(widget.loan.id, (_enteredAmount * 100).toInt(), otp, _verificationId);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        setState(() => _step = 2);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      String errorMsg = 'An unexpected error occurred.';
      if (e is ServerFailure) {
        errorMsg = 'Server Error: \';
      } else {
        errorMsg = e.toString();
      }
      ErrorHandler.showError(context, errorMsg);
    }
  }'''

content = re.sub(r'  Future<void> _processPayment\(\) async \{.*?Widget _buildAmountStep\(\) \{', process_payment + '\n\n  Widget _buildAmountStep() {', content, flags=re.DOTALL)

otp_widget = '''  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Enter OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey.shade600),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text('Please ask the borrower for the 6-digit OTP sent to their phone to confirm this payment.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        SizedBox(height: 16),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          textAlign: TextAlign.center,
          onChanged: (val) {
            if (val.length == 6) setState((){});
          },
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: (_otpCtrl.text.length == 6 && !_isLoading) ? () => _verifyAndApply(_otpCtrl.text) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _isLoading 
              ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Verify & Apply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: Text('Back', style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }'''

content = content.replace("  Widget _buildSuccessStep() {", otp_widget + "\n\n  Widget _buildSuccessStep() {")
content = content.replace("child: _step == 0 ? _buildAmountStep() : _buildSuccessStep(),", "child: _step == 0 ? _buildAmountStep() : _step == 1 ? _buildOtpStep() : _buildSuccessStep(),")

with open('lib/features/loans/presentation/widgets/flexible_payment_sheet.dart', 'w') as f:
    f.write(content)
