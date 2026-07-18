import os

file_path = 'lib/features/home/presentation/pages/home_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# We need to replace the build method of _UpcomingPayments
# It starts at `  @override\n  Widget build(BuildContext context) {` inside `class _UpcomingPayments`
# and ends right before `class _PaymentCard extends StatelessWidget {`

start_marker = "  @override\n  Widget build(BuildContext context) {\n    return BlocBuilder<LoanCubit, LoanState>("
end_marker = "class _PaymentCard extends StatelessWidget {"

if start_marker in content and end_marker in content:
    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)
    
    new_build_method = """  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoanCubit, LoanState>(
      builder: (context, state) {
        if (state is! LoansLoaded) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final loans = state.myLoans;
        final now = DateTime.now();

        // 1. Gather all active taken loans with their upcoming/due details
        List<Map<String, dynamic>> dueList = [];

        for (final loan in loans) {
          if (loan.status == 'completed' ||
              loan.status == 'closed' ||
              loan.status == 'pending_otp' ||
              loan.status == 'pending_approval') {
            continue;
          }

          final type = loan.type.toLowerCase().replaceAll('_', '');
          // Usually business credit / chitfund are handled differently or don't have standard EMIs
          if (type == 'businesscredit' || type == 'business' || type == 'chitfund') {
            continue;
          }

          final duration = (loan.durationMonths == null || loan.durationMonths == 0)
              ? 6
              : loan.durationMonths!;
          final progressVal = loan.progress.clamp(0.0, 1.0);
          final completedMonths = (duration * progressVal).round();

          final nextDueDate = loan.startDate.add(
            Duration(days: (completedMonths + 1) * 30),
          );

          double installment = 0;
          if (type == 'interestcredit' || type == 'home') {
            installment = loan.amount * (loan.interestRate ?? 0) / 100;
          } else {
            installment = loan.amount / duration;
          }

          final daysDifference = nextDueDate.difference(now).inDays;
          
          dueList.add({
            'loan': loan,
            'dueDate': nextDueDate,
            'amount': installment,
            'daysDifference': daysDifference,
          });
        }

        // 2. Sort by most urgent first
        dueList.sort((a, b) => (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));

        if (dueList.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Center(
              child: Text(
                'No upcoming payments',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.sp),
              ),
            ),
          );
        }

        // 3. Render the list of cards
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            children: dueList.map((item) {
              final loan = item['loan'] as LoanModel;
              final dueDate = item['dueDate'] as DateTime;
              final amount = item['amount'] as double;
              final daysDiff = item['daysDifference'] as int;

              String subtitle;
              Color iconBg;
              IconData icon;
              bool isOverdue = false;

              if (daysDiff < 0) {
                final daysPast = daysDiff.abs();
                subtitle = "Overdue by $daysPast Day${daysPast > 1 ? 's' : ''}";
                iconBg = Colors.red.shade600;
                icon = Icons.warning_amber_rounded;
                isOverdue = true;
              } else if (daysDiff == 0) {
                subtitle = "Due Today";
                iconBg = Colors.orange.shade600;
                icon = Icons.today;
              } else {
                subtitle = "Due in $daysDiff Day${daysDiff > 1 ? 's' : ''}";
                iconBg = Colors.blue.shade600;
                icon = Icons.calendar_month;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _PaymentCard(
                  icon: icon,
                  iconBg: iconBg,
                  title: 'Pay to ${loan.lenderName}',
                  amount: '₹${_formatCurrency(amount)}',
                  subtitle: subtitle,
                  showProgress: isOverdue,
                  progressValue: loan.progress.clamp(0.0, 1.0),
                  onTap: () {
                    context.push(
                      AppConstants.loanDetails,
                      extra: loan,
                    );
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

"""
    
    new_content = content[:start_idx] + new_build_method + content[end_idx:]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print('Updated home_page.dart successfully!')
else:
    print('Could not find markers')
