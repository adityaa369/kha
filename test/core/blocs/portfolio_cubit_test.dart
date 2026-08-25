import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/data/models/portfolio_summary_model.dart';

void main() {
  group('PortfolioSummaryModel & F.4.1 Aggregation Parsing', () {
    test('Parses from JSON accurately (paise -> Rupees)', () {
      final json = {
        'loanCount': 10,
        'activeLoanCount': 5,
        'totalLentPaise': 5000000, // 50,000
        'totalCollectedPaise': 2000000, // 20,000
        'outstandingPaise': 3000000, // 30,000
      };

      final model = PortfolioSummaryModel.fromJson(json);

      expect(model.loanCount, 10);
      expect(model.activeLoanCount, 5);
      
      // Internal state should be strict integers
      expect(model.totalLentPaise, 5000000);
      expect(model.outstandingPaise, 3000000);

      // Boundary formatting converts to Rupees purely for display
      expect(model.totalLent, 50000.0);
      expect(model.totalCollected, 20000.0);
      expect(model.outstanding, 30000.0);
    });

    test('Defaults to 0 for missing fields (resilience)', () {
      final json = <String, dynamic>{};
      final model = PortfolioSummaryModel.fromJson(json);

      expect(model.loanCount, 0);
      expect(model.totalLentPaise, 0);
      expect(model.outstanding, 0.0);
    });
  });
}
