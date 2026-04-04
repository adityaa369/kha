import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/blocs/chit_funds/chit_fund_cubit.dart';
import '../../../../core/blocs/chit_funds/chit_fund_state.dart';

class ChitGroupAdminPage extends StatefulWidget {
  final String chitId;
  const ChitGroupAdminPage({super.key, required this.chitId});

  @override
  State<ChitGroupAdminPage> createState() => _ChitGroupAdminPageState();
}

class _ChitGroupAdminPageState extends State<ChitGroupAdminPage> {
  int _selectedIndex = 0; // 0 = Members Tracker, 1 = Auction Timeline

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChitFundCubit>().loadAdminDashboard(widget.chitId);
    });
  }

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Group Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: KhaataTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<ChitFundCubit, ChitFundState>(
            builder: (context, state) {
              if (state is ChitAdminDashboardLoaded && state.dashboardData['chitDetails']?['isOwner'] == true) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final authenticated = await BiometricAuthService.authenticate();
                      if (!authenticated) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Biometric auth required to delete group', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
                          );
                        }
                        return;
                      }
                      
                      if (context.mounted) {
                        context.read<ChitFundCubit>().deleteChitFund(widget.chitId);
                        context.pop();
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Group', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<ChitFundCubit, ChitFundState>(
        builder: (context, state) {
          if (state is ChitFundLoading || state is ChitFundInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! ChitAdminDashboardLoaded) {
            return Center(child: Text('Failed to load dashboard', style: TextStyle(color: KhaataTheme.dangerRed)));
          }

          final data = state.dashboardData;
          final chitDetails = data['chitDetails'] ?? {};
          final List members = data['members'] ?? [];
          final List auctions = data['auctionTimeline'] ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: Text(
                    'Group Members',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: KhaataTheme.textDark,
                    ),
                  ),
                ),
                _buildMembersTracker(members, chitDetails),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: Text(
                    'Auction Timeline',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: KhaataTheme.textDark,
                    ),
                  ),
                ),
                _buildAuctionTimeline(auctions, chitDetails),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3.h,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showMemberPaymentDetails(Map<String, dynamic> member, Map<String, dynamic> chitDetails) {
    final int completedMonths = chitDetails['completedMonths'] ?? 0;
    final List paidMonthsStr = member['paidMonths'] ?? [];
    final Set<int> paidMonthsSet = paidMonthsStr.map((e) => e as int).toSet();
    final userDoc = member['user'] ?? {};

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                 'Payment Tracker: ${userDoc['firstName'] ?? 'User'}', 
                 style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)
               ),
               SizedBox(height: 16.h),
               if (completedMonths == 0)
                 const Center(child: Text("Process hasn't started (0 months)")),
               if (completedMonths > 0)
                 Flexible(
                   child: ListView.builder(
                     shrinkWrap: true,
                     itemCount: completedMonths,
                     itemBuilder: (c, idx) {
                       int monthNum = idx + 1;
                       bool isPaid = paidMonthsSet.contains(monthNum);
                       return ListTile(
                         leading: Icon(
                           isPaid ? Icons.check_circle : Icons.cancel, 
                           color: isPaid ? KhaataTheme.accentGreen : KhaataTheme.dangerRed
                         ),
                         title: Text('Month $monthNum Contribution', style: TextStyle(fontWeight: FontWeight.w600)),
                         subtitle: Text(isPaid ? 'Payment Confirmed' : 'Payment Pending', style: TextStyle(color: isPaid ? KhaataTheme.accentGreen : KhaataTheme.dangerRed)),
                       );
                     },
                   ),
                 ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMembersTracker(List members, Map<String, dynamic> chitDetails) {
    bool isOwner = chitDetails['isOwner'] == true;
    if (members.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("No members arrived yet.")));
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final user = member['user'] ?? {};
        final bool hasWon = member['hasWonAuction'] == true;
        
        return InkWell(
          onTap: () {
            if (isOwner) {
              _showMemberPaymentDetails(member, chitDetails);
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: KhaataTheme.cardWhite,
              border: Border.all(color: KhaataTheme.borderGrey),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: KhaataTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    user['firstName']?.substring(0, 1) ?? 'U',
                    style: TextStyle(color: KhaataTheme.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ),
                      Text(
                        user['phone'] ?? '',
                        style: TextStyle(color: KhaataTheme.textGrey, fontSize: 13.sp),
                      ),
                      if (hasWon)
                        Container(
                          margin: EdgeInsets.only(top: 4.h),
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                             color: Colors.amber.withOpacity(0.2),
                             borderRadius: BorderRadius.circular(4.r)
                          ),
                          child: Text('Took payout in Month ${member['wonMonth']}', style: TextStyle(color: Colors.amber.shade800, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ),
                if (isOwner) Icon(Icons.chevron_right, color: KhaataTheme.textGrey)
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAuctionDetails(Map<String, dynamic> auction, Map<String, dynamic> chitDetails) {
    if (auction['status'] == 'pending') {
      return;
    }
    
    final winner = auction['winner'] ?? {};
    final String winnerName = '${winner['firstName'] ?? 'User'} ${winner['lastName'] ?? ''}'.trim();
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                 'Month ${auction['monthNumber']} Auction Results', 
                 style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)
               ),
               SizedBox(height: 16.h),
               _DetailRow(label: 'Winner', value: winnerName),
               _DetailRow(label: 'Bid Discount Offered', value: currencyFormatter.format(auction['winningBidDiscount'] ?? 0), isRed: true),
               _DetailRow(label: 'Net Prize Remitted', value: currencyFormatter.format(auction['prizeMoneyPaid'] ?? 0), isGreen: true),
               const Divider(),
               _DetailRow(label: 'Dividend Distributed per Member', value: currencyFormatter.format(auction['dividendPerMember'] ?? 0), isGreen: true),
            ],
          ),
        );
      }
    );
  }

  Widget _buildAuctionTimeline(List auctions, Map<String, dynamic> chitDetails) {
    if (auctions.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("Detailed Timeline preparing...")));
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: auctions.length,
      itemBuilder: (context, index) {
        final auction = auctions[index];
        final bool isCompleted = auction['status'] == 'completed';
        final bool isActive = auction['status'] == 'active';
        
        Color badgeColor = isCompleted ? KhaataTheme.accentGreen : (isActive ? Colors.amber.shade700 : KhaataTheme.textGrey);
        String badgeText = isCompleted ? 'Completed' : (isActive ? 'Ongoing' : 'Upcoming');

        return InkWell(
          onTap: () => _showAuctionDetails(auction, chitDetails),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: KhaataTheme.cardWhite,
              border: Border.all(color: KhaataTheme.borderGrey),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 45.w,
                  height: 45.w,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'M${auction['monthNumber']}',
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auction Timeline',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ),
                      if (isCompleted && auction['winner'] != null)
                        Text(
                          'Winner: ${auction['winner']['firstName'] ?? ''}',
                          style: TextStyle(color: KhaataTheme.textGrey, fontSize: 13.sp),
                        )
                      else if (isActive)
                        Text(
                          'Awaiting finalization',
                          style: TextStyle(color: KhaataTheme.textGrey, fontSize: 13.sp),
                        )
                       else
                        Text(
                          'Scheduled Future Phase',
                          style: TextStyle(color: KhaataTheme.textGrey, fontSize: 13.sp),
                        ),
                    ],
                  ),
                ),
                Container(
                   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                   decoration: BoxDecoration(
                     color: badgeColor.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(4.r)
                   ),
                   child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;
  final bool isRed;

  const _DetailRow({required this.label, required this.value, this.isGreen = false, this.isRed = false});

  @override
  Widget build(BuildContext context) {
    Color valColor = KhaataTheme.textDark;
    if (isGreen) valColor = KhaataTheme.accentGreen;
    if (isRed) valColor = KhaataTheme.dangerRed;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: KhaataTheme.textGrey, fontSize: 15.sp)),
          Text(value, style: TextStyle(color: valColor, fontSize: 15.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
