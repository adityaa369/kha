import '../models/loan_model.dart';
import '../services/api_services.dart';

class LoansRepository {
  Future<List<LoanModel>> getMyLoans() async {
    try {
      final response = await ApiService.get('/loans/my');
      if (response.statusCode == 200) {
        return (response.data['loans'] as List)
            .map((json) => LoanModel.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load loans');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<LoanModel>> getLoansGiven() async {
    try {
      final response = await ApiService.get('/loans/given');
      if (response.statusCode == 200) {
        return (response.data['loans'] as List)
            .map((json) => LoanModel.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load loans');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<LoanModel> createLoan(Map<String, dynamic> loanData) async {
    try {
      final response = await ApiService.post('/loans', data: loanData);
      if (response.statusCode == 201) {
        return LoanModel.fromJson(response.data['loan']);
      }
      throw Exception('Failed to create loan');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}