  Widget _nudgeCard(BuildContext context, LoanModel loan) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_outlined, color: Colors.blue.shade700, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send Payment Nudge', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4.h),
                Text('Ask the borrower to coordinate about their next payment.', style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () => _handleNudge(context, loan.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Nudge', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNudge(BuildContext context, String loanId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      await context.read<LoanCubit>().sendPaymentNudge(loanId);
      if (context.mounted) Navigator.pop(context); // close dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment nudge sent successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // close dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

