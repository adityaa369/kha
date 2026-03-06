import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'credit_score_state.dart';
import '../../network/api_client.dart';

class CreditScoreCubit extends Cubit<CreditScoreState> {
  CreditScoreCubit() : super(CreditScoreInitial());

  final _api = ApiClient();
  
  void clear() {
    emit(CreditScoreInitial());
  }

  void resetError() {
    if (state is CreditScoreError) {
      emit(CreditScoreInitial());
    }
  }

  Future<void> fetchCreditScore() async {
    resetError();
    emit(CreditScoreLoading());
    try {
      final scoreResponse = await _api.get('/credit-score');
      final insightsResponse = await _api.get('/credit-score/insights');

      int cibil = 0;
      int experian = 0;
      String status = 'N/A';
      Map<String, dynamic>? insights;

      if (scoreResponse.data['success'] == true) {
        final score = scoreResponse.data['score'];
        if (score != null) {
          cibil = score['cibilScore'] ?? 0;
          experian = score['experianScore'] ?? 0;
          status = score['status'] ?? 'N/A';
        }
      }

      if (insightsResponse.data['success'] == true) {
        insights = insightsResponse.data['insights'];
      }

      emit(CreditScoreLoaded(
        cibilScore: cibil,
        experianScore: experian,
        status: status,
        insights: insights,
      ));
    } catch (e) {
      emit(CreditScoreError('Failed to load credit score: $e'));
    }
  }
}