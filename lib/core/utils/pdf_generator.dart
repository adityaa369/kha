import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/repayment_timeline_model.dart';

class PdfGenerator {
  static Future<void> generateAndShareStatement(LoanModel loan, RepaymentTimelineModel timelineModel) async {
    final pdf = pw.Document();

    // Load font for Rupee symbol and normal text
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final currencyFmt = NumberFormat('#,##0', 'en_IN');
    final dateFmt = DateFormat('MMM dd, yyyy');
    final dateTimeFmt = DateFormat('MMM dd, yyyy hh:mm a');

    final generatedTime = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Khataa Loan Statement', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text('CONFIDENTIAL', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('Statement Generated: ${dateTimeFmt.format(generatedTime)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (timelineModel.anchorSource != null)
                pw.Text('Anchor Source: ${timelineModel.anchorSource}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'This is a read-only temporal snapshot of flexible payment activity. Generated via Khataa.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (context) => [
          // Section 1: Loan Summary
          pw.Text('1. Loan Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Reference ID:', loan.id),
                      _buildInfoRow('Type:', loan.type.toUpperCase()),
                      _buildInfoRow('Status:', loan.status.toUpperCase()),
                      _buildInfoRow('Duration:', '${loan.durationMonths ?? 0} Months'),
                      _buildInfoRow('Activation Date:', loan.startDate != null ? dateFmt.format(loan.startDate!) : '-'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Lender:', loan.lenderName ?? 'Lender'),
                      _buildInfoRow('Borrower:', loan.borrowerName.isNotEmpty ? loan.borrowerName : 'Borrower'),
                      // Phone numbers intentionally excluded unless explicitly requested to preserve privacy
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Section 2: Financial Summary
          pw.Text('2. Financial Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricBox('Original Principal', 'Rs. ${currencyFmt.format(loan.amount)}'),
              _buildMetricBox('Total Payable', 'Rs. ${currencyFmt.format(loan.totalPayableAmount)}'),
              _buildMetricBox('Total Paid', 'Rs. ${currencyFmt.format(loan.paidAmount)}'),
              _buildMetricBox('Remaining Balance', 'Rs. ${currencyFmt.format(loan.remainingAmount)}'),
            ],
          ),
          pw.SizedBox(height: 24),

          // Section 3: Repayment Timeline
          pw.Text('3. Flexible Repayment Timeline', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.Text('This timeline records actual payment activity. It does not reflect fixed EMIs or monthly obligations.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
          pw.SizedBox(height: 12),
          ...timelineModel.timeline.map((period) {
            final isRecorded = period.hasPayments;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Period ${period.periodIndex} (${dateFmt.format(period.periodStart)} - ${dateFmt.format(period.periodEnd)})',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.Text(
                        isRecorded ? 'RECORDED' : 'NO_PAYMENT_RECORDED',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: isRecorded ? PdfColors.green700 : PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  if (!isRecorded)
                    pw.Text('No payment was recorded during this period.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
                  else ...[
                    ...period.transactions.map((tx) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4, left: 8),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${dateFmt.format(tx.recordedAt)} - ${tx.type == 'interest_payment' ? 'Interest' : 'Principal'} Payment', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('Rs. ${currencyFmt.format(tx.amount)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      );
                    }),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey200),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Period Total: Rs. ${currencyFmt.format(period.totalPaid)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ]
                ],
              ),
            );
          }),

          // Post-term
          if (timelineModel.postTermTransactions.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Post-Term Payment Activity', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.orange200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.orange50,
              ),
              child: pw.Column(
                children: timelineModel.postTermTransactions.map((tx) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${dateFmt.format(tx.recordedAt)} - Post-term Payment', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Rs. ${currencyFmt.format(tx.amount)}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          
          pw.SizedBox(height: 24),
          pw.Text('4. Transaction Ledger', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 8),
          _buildTransactionTable(timelineModel, dateFmt, currencyFmt),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'Khataa_Statement_${loan.id}.pdf');
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricBox(String label, String value) {
    return pw.Container(
      width: 105,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionTable(RepaymentTimelineModel timeline, DateFormat dateFmt, NumberFormat currencyFmt) {
    // Combine all transactions
    final allTxs = <RepaymentTransactionModel>[];
    for (final period in timeline.timeline) {
      allTxs.addAll(period.transactions);
    }
    allTxs.addAll(timeline.postTermTransactions);
    
    // Sort chronologically
    allTxs.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (allTxs.isEmpty) {
      return pw.Text('No transactions recorded.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Type', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Note', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
          ],
        ),
        // Rows
        ...allTxs.map((tx) {
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(dateFmt.format(tx.recordedAt), style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx.type, style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx.note.isNotEmpty ? tx.note : '-', style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs. ${currencyFmt.format(tx.amount)}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
            ],
          );
        }),
      ],
    );
  }
}
