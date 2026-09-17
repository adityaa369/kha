import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';

//  Lender signature step The agreement is persisted as pending_otp and is
//  released to the borrower only after a Firebase SMS challenge succeeds
class LoanConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> loanData;
  const LoanConfirmationPage({super.key, required this.loanData});

  @override
  State<LoanConfirmationPage> createState() => _LoanConfirmationPageState();
}

class _LoanConfirmationPageState extends State<LoanConfirmationPage> {
  String? _verificationId;
  String _code = '';
  bool _sending = false;
  bool _verifying = false;

  String get _loanId => widget.loanData['loan_id']?.toString() ?? '';

  Future<void> _sendOtp() async {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (_loanId.isEmpty || phone == null) {
      _show('Your phone session is unavailable. Please sign in again.');
      return;
    }
    setState(() => _sending = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (_) {},
      verificationFailed: (error) {
        if (!mounted) return;
        setState(() => _sending = false);
        _show(error.message ?? 'Unable to send OTP. Please try again.');
      },
      codeSent: (verificationId, _) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _sending = false;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) => _verificationId = verificationId,
    );
  }

  Future<void> _confirm() async {
    if (_verificationId == null || _code.length != 6) return;
    setState(() => _verifying = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final ok = await context.read<LoanCubit>().verifyLenderOtp(_loanId);
      if (!mounted) return;
      if (ok) {
        context.go(AppConstants.loansGiven);
      } else {
        _show('Could not confirm the agreement. Please request a new OTP.');
      }
    } on FirebaseAuthException catch (error) {
      _show(error.message ?? 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final amount = (widget.loanData['amountPaise'] as num? ?? 0) / 100;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Agreement')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.description_outlined, size: 64, color: KhaataTheme.primaryBlue),
              const SizedBox(height: 20),
              Text('Sign before sending', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                '₹${amount.toStringAsFixed(0)} to ${widget.loanData['borrower_name'] ?? 'the borrower'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'We will send an OTP to your registered phone. Verifying it is your digital signature; the borrower receives the agreement only afterwards.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_verificationId == null)
                ElevatedButton(
                  onPressed: _sending ? null : _sendOtp,
                  child: _sending ? const CircularProgressIndicator() : const Text('Send OTP to Sign'),
                )
              else ...[
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => _code = value),
                  onCompleted: (value) => setState(() => _code = value),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _verifying || _code.length != 6 ? null : _confirm,
                  child: _verifying ? const CircularProgressIndicator() : const Text('Verify OTP & Send Agreement'),
                ),
                TextButton(onPressed: _sending ? null : _sendOtp, child: const Text('Resend OTP')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
