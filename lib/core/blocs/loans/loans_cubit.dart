import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/loan_model.dart';
import '../../../config/constants.dart';

part 'loans_state.dart';

class LoansCubit extends Cubit<LoansState> {
  LoansCubit() : super(LoansInitial());

  final _supabase = Supabase.instance.client;

  // Load loans taken by user (from banks)
  Future<void> loadMyLoans() async {
    emit(LoansLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const LoansError('User not authenticated'));
        return;
      }

      final response = await _supabase
          .from(AppConstants.loansTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final loans = (response as List)
          .map((json) => LoanModel.fromJson({
        ...json,
        'borrower_name': json['lender_name'],
      }))
          .toList();

      emit(LoansLoaded(loans: loans));
    } on PostgrestException catch (e) {
      emit(LoansError('Database error: ${e.message}'));
    } catch (e) {
      emit(LoansError('Failed to load loans: $e'));
    }
  }

  // Load loans given by user (to other people)
  Future<void> loadLoansGiven() async {
    emit(LoansLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const LoansError('User not authenticated'));
        return;
      }

      final response = await _supabase
          .from(AppConstants.loansGivenTable)
          .select()
          .eq('lender_id', userId)
          .order('created_at', ascending: false);

      final loans = (response as List)
          .map((json) => LoanModel.fromJson({
        ...json,
        'initials': _getInitials(json['borrower_name']),
      }))
          .toList();

      emit(LoansLoaded(loans: loans));
    } on PostgrestException catch (e) {
      emit(LoansError('Database error: ${e.message}'));
    } catch (e) {
      emit(LoansError('Failed to load loans: $e'));
    }
  }

  // Create a new loan agreement
  Future<void> createLoan(Map<String, dynamic> loanData) async {
    emit(LoanCreating());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const LoansError('User not authenticated'));
        return;
      }

      // Insert loan to database
      await _supabase.from(AppConstants.loansGivenTable).insert({
        'lender_id': userId,
        'borrower_name': loanData['borrowerName'],
        'borrower_phone': loanData['mobile'],
        'borrower_aadhar': loanData['aadhar'],
        'amount': double.parse(loanData['amount'].toString()),
        'interest_rate': loanData['interestRate'] != null
            ? double.parse(loanData['interestRate'].toString())
            : null,
        'duration_months': loanData['duration'] != null
            ? int.parse(loanData['duration'].toString())
            : null,
        'start_date': loanData['startDate'],
        'type': loanData['loanType'],
        'status': 'pending_otp',
        'progress': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send OTP to borrower (via SMS service or Supabase function)
      await _sendBorrowerOtp(loanData['mobile']);

      emit(LoanCreated());
    } on PostgrestException catch (e) {
      emit(LoansError('Database error: ${e.message}'));
    } catch (e) {
      emit(LoansError('Failed to create loan: $e'));
    }
  }

  // Verify borrower OTP and activate loan
  Future<void> verifyBorrowerOtp(String loanId, String otp) async {
    emit(LoanCreating());
    try {
      // Verify OTP (implement your OTP verification logic)
      final isValid = await _verifyOtp(loanId, otp);

      if (!isValid) {
        emit(const LoansError('Invalid OTP'));
        return;
      }

      // Update loan status to active
      await _supabase
          .from(AppConstants.loansGivenTable)
          .update({
        'status': 'active',
        'activated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', loanId);

      emit(LoanCreated());
    } catch (e) {
      emit(LoansError('Verification failed: $e'));
    }
  }

  // Update loan repayment progress
  Future<void> updateRepayment(String loanId, double amountPaid) async {
    try {
      final loan = await _supabase
          .from(AppConstants.loansGivenTable)
          .select()
          .eq('id', loanId)
          .single();

      final totalAmount = loan['amount'] as double;
      final currentProgress = loan['progress'] as double;
      final newProgress = (currentProgress + (amountPaid / totalAmount)).clamp(0.0, 1.0);

      await _supabase
          .from(AppConstants.loansGivenTable)
          .update({
        'progress': newProgress,
        'status': newProgress >= 1.0 ? 'completed' : 'active',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', loanId);

      // Refresh loans list
      await loadLoansGiven();
    } catch (e) {
      emit(LoansError('Update failed: $e'));
    }
  }

  // Send reminder to borrower
  Future<void> sendReminder(String loanId) async {
    try {
      final loan = await _supabase
          .from(AppConstants.loansGivenTable)
          .select('borrower_phone, borrower_name')
          .eq('id', loanId)
          .single();

      final phone = loan['borrower_phone'];
      final name = loan['borrower_name'];

      // Call Supabase Edge Function or external SMS service
      await _supabase.functions.invoke('send-sms', body: {
        'phone': phone,
        'message': 'Hi $name, this is a friendly reminder about your pending loan payment. Please check the Khaata app for details.',
      });
    } catch (e) {
      emit(LoansError('Failed to send reminder: $e'));
    }
  }

  // Helper methods
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _sendBorrowerOtp(String phone) async {
    // Implement OTP sending via Supabase function or external service
    await _supabase.functions.invoke('send-borrower-otp', body: {
      'phone': phone,
    });
  }

  Future<bool> _verifyOtp(String loanId, String otp) async {
    // Implement OTP verification
    final result = await _supabase.functions.invoke('verify-borrower-otp', body: {
      'loan_id': loanId,
      'otp': otp,
    });
    return result.data['valid'] == true;
  }
}