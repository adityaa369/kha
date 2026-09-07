import 'package:khataa/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/chit_funds/chit_fund_cubit.dart';
import '../../../../core/blocs/chit_funds/chit_fund_state.dart';

class ChitMemberDetailPage extends StatefulWidget {
  final String chitId;
  const ChitMemberDetailPage({super.key, required this.chitId});

  @override
  State<ChitMemberDetailPage> createState() => _ChitMemberDetailPageState();
}

class _ChitMemberDetailPageState extends State<ChitMemberDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChitFundCubit>().loadMemberDetail(widget.chitId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      body: BlocConsumer<ChitFundCubit, ChitFundState>(
        listener: (context, state) {
          if (state is ChitFundError) {
            ErrorHandler.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ChitFundLoading || state is ChitFundInitial) {
            return _buildLoadingShimmer();
          }

          if (state is ChitFundError) {
            return _buildErrorState(state.message);
          }

          if (state is ChitMemberDetailLoaded) {
            return _buildLoadedState(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.h,
          backgroundColor: KhaataTheme.primaryBlue,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: List.generate(3, (index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  height: 150.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100.w,
                          height: 16.h,
                          color: Colors.grey.shade200,
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          width: double.infinity,
                          height: 60.h,
                          color: Colors.grey.shade100,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: KhaataTheme.dangerRed),
            SizedBox(height: 16.h),
            Text(
              'Oops!',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: KhaataTheme.textGrey,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                context.read<ChitFundCubit>().loadMemberDetail(widget.chitId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(ChitMemberDetailLoaded state) {
    final chitName = state.chitInfo['name'] ?? 'Chit Group';
    final isActive = state.chitInfo['status'] != 'registration';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 140.h,
          pinned: true,
          backgroundColor: KhaataTheme.primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: 48.w,
              bottom: 16.h,
              right: 16.w,
            ),
            title: Text(
              chitName,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 48.h,
                    right: 16.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE ●' : 'REGISTRATION',
                        style: GoogleFonts.inter(
                          color: isActive
                              ? Colors.white
                              : KhaataTheme.warningYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSubscriptionCard(state),
                SizedBox(height: 16.h),
                _buildAuctionHistoryCard(state.auctionHistory, state.chitInfo),
                SizedBox(height: 16.h),
                _buildPaymentHistoryCard(state.paymentHistory),
                SizedBox(height: 24.h),
                _buildFooterInfo(),
                SizedBox(height: 48.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(ChitMemberDetailLoaded state) {
    final slotNumber = state.memberData['slotNumber'] ?? 0;
    final totalMembers = state.chitInfo['totalMembers'] ?? 0;
    final monthlyEmi = state.chitInfo['monthlyContribution'] ?? 0.0;
    final dividendEarned = state.memberData['dividendEarnedThisMonth'] ?? 0.0;
    final prizePool = state.chitInfo['totalValue'] ?? 0.0;

    // Check if nextDueDate exists in chitInfo or memberData
    DateTime? nextDue;
    if (state.chitInfo['nextDueDate'] != null) {
      try {
        nextDue = DateTime.parse(state.chitInfo['nextDueDate'].toString());
      } catch (_) {}
    }

    final hasWonAuction = state.memberData['hasWonAuction'] == true;
    final wonMonth = state.memberData['wonMonth'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: const Border(
          left: BorderSide(color: KhaataTheme.primaryBlue, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: KhaataTheme.textGrey, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'YOUR SUBSCRIPTION',
                style: GoogleFonts.inter(
                  color: KhaataTheme.textGrey,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: const BoxDecoration(
                  color: KhaataTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$slotNumber',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slot Number',
                    style: GoogleFonts.inter(
                      color: KhaataTheme.textGrey,
                      fontSize: 14.sp,
                    ),
                  ),
                  Text(
                    '# $slotNumber of $totalMembers',
                    style: GoogleFonts.inter(
                      color: KhaataTheme.textDark,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(child: _buildStatColumn('Monthly EMI', '₹$monthlyEmi')),
              Expanded(child: _buildNextDueColumn(nextDue)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'Dividend Earned',
                  '₹$dividendEarned',
                  valueColor: KhaataTheme.primaryBlue,
                ),
              ),
              Expanded(child: _buildStatColumn('Prize Pool', '₹$prizePool')),
            ],
          ),
          if (hasWonAuction) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  Text('🏆', style: TextStyle(fontSize: 20.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    'You won Month $wonMonth!',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextDueColumn(DateTime? nextDue) {
    String value = 'N/A';
    Color valColor = KhaataTheme.textDark;

    if (nextDue != null) {
      value = DateFormat('dd MMM yyyy').format(nextDue);
      final daysDiff = nextDue.difference(DateTime.now()).inDays;
      if (daysDiff >= 0 && daysDiff <= 7) {
        valColor = KhaataTheme.warningYellow;
      }
    }

    return _buildStatColumn('Next Due', value, valueColor: valColor);
  }

  Widget _buildStatColumn(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: KhaataTheme.textGrey,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor ?? KhaataTheme.textDark,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAuctionHistoryCard(
    List<dynamic> auctionHistory,
    Map<String, dynamic> chitInfo,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: KhaataTheme.textGrey, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'AUCTION HISTORY',
                style: GoogleFonts.inter(
                  color: KhaataTheme.textGrey,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (auctionHistory.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'No auctions yet',
                style: GoogleFonts.inter(
                  color: KhaataTheme.textGrey,
                  fontSize: 14.sp,
                ),
              ),
            )
          else
            ...auctionHistory.map((auction) {
              final month = auction['monthNumber'] ?? 1;
              final winnerName = auction['winnerName'] ?? 'Someone';
              final prizeAmount = auction['prizeAmount'] ?? 0;
              final dividendPerMember = auction['dividendPerMember'] ?? 0;

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: const BoxDecoration(
                        color: KhaataTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$month',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$winnerName won',
                            style: GoogleFonts.inter(
                              color: KhaataTheme.textDark,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Div: +₹$dividendPerMember/member',
                            style: GoogleFonts.inter(
                              color: KhaataTheme.primaryBlue,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹$prizeAmount',
                      style: GoogleFonts.inter(
                        color: KhaataTheme.textDark,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),

          if (chitInfo['status'] == 'active' &&
              chitInfo['completedMonths'] != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: const BoxDecoration(
                      color: KhaataTheme.warningYellow,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${(chitInfo['completedMonths'] as int) + 1}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Month ${(chitInfo['completedMonths'] as int) + 1} • Upcoming',
                      style: GoogleFonts.inter(
                        color: KhaataTheme.textDark,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: KhaataTheme.warningYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'LIVE SOON',
                      style: GoogleFonts.inter(
                        color: KhaataTheme.warningYellow,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard(List<dynamic> paymentHistory) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: KhaataTheme.textGrey,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'PAYMENT HISTORY',
                style: GoogleFonts.inter(
                  color: KhaataTheme.textGrey,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (paymentHistory.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'No payment records yet',
                style: GoogleFonts.inter(
                  color: KhaataTheme.textGrey,
                  fontSize: 14.sp,
                ),
              ),
            )
          else
            ...paymentHistory.map((payment) {
              final status = payment['status'] ?? 'pending';
              final monthLabel =
                  payment['monthLabel'] ?? 'Month ${payment['monthNumber']}';
              final amount = payment['amount'] ?? 0;
              final dividendEarned = payment['dividendEarned'] ?? 0;

              IconData icon;
              Color iconColor;
              if (status == 'paid') {
                icon = Icons.check_circle;
                iconColor = KhaataTheme.primaryBlue;
              } else if (status == 'overdue') {
                icon = Icons.cancel;
                iconColor = KhaataTheme.dangerRed;
              } else {
                icon = Icons.warning;
                iconColor = KhaataTheme.warningYellow;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24.w),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monthLabel,
                            style: GoogleFonts.inter(
                              color: KhaataTheme.textDark,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (dividendEarned > 0)
                            Text(
                              'Div saved: ₹$dividendEarned',
                              style: GoogleFonts.inter(
                                color: KhaataTheme.textGrey,
                                fontSize: 12.sp,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '₹$amount',
                      style: GoogleFonts.inter(
                        color: KhaataTheme.textDark,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: KhaataTheme.textGrey, size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment is managed by your group admin',
                  style: GoogleFonts.inter(
                    color: KhaataTheme.textDark,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Contact your admin if your payment is not marked',
                  style: GoogleFonts.inter(
                    color: KhaataTheme.textGrey,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
