import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'credit_score_state.dart';
import '../../network/api_client.dart';

class CreditScoreCubit extends Cubit<CreditScoreState> {
  CreditScoreCubit() : super(CreditScoreInitial());

  final _supabase = Supabase.instance.client;
  StreamSubscription? _scoreSubscription;

  Future<void> fetchAndStreamCreditScore(String userId) async {
    emit(CreditScoreLoading());
    try {
      // Initial fetch
      final response = await _supabase
          .from(AppConstants.creditScoresTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        emit(CreditScoreLoaded(
          cibilScore: response['cibil_score'] ?? 0,
          experianScore: response['experian_score'] ?? 0,
          status: response['status'] ?? 'N/A',
        ));
      } else {
        emit(const CreditScoreLoaded(cibilScore: 0, experianScore: 0, status: 'N/A'));
      }

      // Stream listener for updates
      _scoreSubscription?.cancel();
      _scoreSubscription = _supabase
          .from(AppConstants.creditScoresTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((data) {
        if (data.isNotEmpty) {
          final score = data.first;
          emit(CreditScoreLoaded(
            cibilScore: score['cibil_score'] ?? 0,
            experianScore: score['experian_score'] ?? 0,
            status: score['status'] ?? 'N/A',
          ));
        }
      });
    } catch (e) {
      emit(CreditScoreError('Failed to load credit score: $e'));
    }
  }

  @override
  Future<void> close() {
    _scoreSubscription?.cancel();
    return super.close();
  }
}