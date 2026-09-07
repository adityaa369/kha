import 'package:khatha/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/chit_funds/chit_fund_cubit.dart';
import '../../../../core/blocs/chit_funds/chit_fund_state.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';

class ChitGroupAdminPage extends StatefulWidget {
  final String chitId;
  const ChitGroupAdminPage({super.key, required this.chitId});

  @override
  State<ChitGroupAdminPage> createState() => _ChitGroupAdminPageState();
}

class _ChitGroupAdminPageState extends State<ChitGroupAdminPage> {
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            onPressed: () {
              context.read<ChitFundCubit>().loadInvitesAndOwned();
              context.pop();
            },
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3.h,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Members"),
              Tab(text: "Auctions"),
            ],
          ),
        ),
        body: BlocConsumer<ChitFundCubit, ChitFundState>(
          listener: (context, state) {
            if (state is ChitFundActionSuccess) {
              ErrorHandler.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is ChitFundLoading || state is ChitFundInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is! ChitAdminDashboardLoaded) {
              return const Center(
                child: Text(
                  'Failed to load dashboard',
                  style: TextStyle(color: KhaataTheme.dangerRed),
                ),
              );
            }

            final data = state.dashboardData;
            final chitDetails = data['chitDetails'] ?? {};
            final List members = data['members'] ?? [];
            final List auctions = data['auctionTimeline'] ?? [];

            return TabBarView(
              children: [
                RefreshIndicator(
                  color: KhaataTheme.primaryBlue,
                  onRefresh: () => context
                      .read<ChitFundCubit>()
                      .loadAdminDashboard(widget.chitId),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: 16.h),
                    children: [_buildMembersTracker(members, chitDetails)],
                  ),
                ),
                RefreshIndicator(
                  color: KhaataTheme.primaryBlue,
                  onRefresh: () => context
                      .read<ChitFundCubit>()
                      .loadAdminDashboard(widget.chitId),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: 16.h),
                    children: [
                      _buildAuctionTimeline(auctions, members, chitDetails),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMemberPaymentDetails(
    Map<String, dynamic> member,
    Map<String, dynamic> chitDetails,
  ) {
    final int completedMonths = chitDetails['completedMonths'] ?? 0;
    final userDoc = member['user'] ?? {};

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Payment Check: ${userDoc['firstName'] ?? 'User'}',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          content: BlocBuilder<ChitFundCubit, ChitFundState>(
            builder: (context, state) {
              if ((chitDetails['status'] ?? '') == 'registration') {
                return const Text("Group process hasn't started yet");
              }

              int currentMonthToPay = completedMonths + 1;
              Map<String, dynamic> currentMember = member; // default to passed
              if (state is ChitAdminDashboardLoaded) {
                final mm = (state.dashboardData['members'] as List?)
                    ?.firstWhere(
                      (m) => m['id'] == member['id'],
                      orElse: () => member,
                    );
                if (mm != null) currentMember = mm as Map<String, dynamic>;
              }

              final Set<int> currentPaidSet =
                  ((currentMember['paidMonths'] ?? []) as List)
                      .map((e) => e as int)
                      .toSet();
              bool isPaid = currentPaidSet.contains(currentMonthToPay);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Month $currentMonthToPay Status:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: KhaataTheme.textGrey,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPaid ? Icons.check_circle : Icons.cancel,
                            color: isPaid
                                ? KhaataTheme.accentGreen
                                : KhaataTheme.dangerRed,
                            size: 28.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            isPaid ? 'Payment Confirmed' : 'Payment Pending',
                            style: TextStyle(
                              color: isPaid
                                  ? KhaataTheme.accentGreen
                                  : KhaataTheme.dangerRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (chitDetails['isOwner'] == true) ...[
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 45.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPaid
                              ? KhaataTheme.accentGreen.withValues(alpha: 0.2)
                              : KhaataTheme.primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: () {
                          context.read<ChitFundCubit>().verifyMonthPayment(
                            chitId: chitDetails['id'],
                            monthNumber: currentMonthToPay,
                            subscriberId: currentMember['id'],
                            isPaid: !isPaid,
                          );
                        },
                        child: Text(
                          isPaid ? 'PAID' : 'MARK PAID',
                          style: TextStyle(
                            color: isPaid
                                ? KhaataTheme.accentGreen
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembersTracker(List members, Map<String, dynamic> chitDetails) {
    bool isOwner = chitDetails['isOwner'] == true;
    if (members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("No members arrived yet.")),
      );
    }

    int currentMonth = (chitDetails['completedMonths'] ?? 0) + 1;
    final currentUser = context.read<AuthCubit>().currentUser;
    final currentUserId = currentUser?.id ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: members.map((member) {
          final user = member['user'] ?? {};
          final bool hasWon = member['hasWonAuction'] == true;

          final List paidMonthsStr = member['paidMonths'] ?? [];
          final Set<int> paidMonthsSet = paidMonthsStr
              .map((e) => e as int)
              .toSet();
          final bool hasPaidCurrentMonth = paidMonthsSet.contains(currentMonth);
          final bool isMe = user['id'] == currentUserId;
          final bool canViewPayment = isOwner || isMe;

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
                    backgroundColor: KhaataTheme.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      user['firstName']?.substring(0, 1) ?? 'U',
                      style: const TextStyle(
                        color: KhaataTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                              .trim(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user['phone'] ?? '',
                          style: TextStyle(
                            color: KhaataTheme.textGrey,
                            fontSize: 13.sp,
                          ),
                        ),
                        if (hasWon)
                          Container(
                            margin: EdgeInsets.only(top: 4.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'Took payout in Month ${member['wonMonth']}',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (canViewPayment)
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasPaidCurrentMonth
                            ? KhaataTheme.accentGreen
                            : KhaataTheme.dangerRed,
                      ),
                    ),
                  if (isOwner) SizedBox(width: 8.w),
                  if (isOwner)
                    const Icon(
                      Icons.chevron_right,
                      color: KhaataTheme.textGrey,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAuctionDetails(
    Map<String, dynamic> auction,
    Map<String, dynamic> chitDetails,
  ) {
    if (auction['status'] == 'pending' || auction['status'] == 'active') {
      return;
    }

    final winner = auction['winner'] ?? {};
    final String winnerName =
        '${winner['firstName'] ?? 'User'} ${winner['lastName'] ?? ''}'.trim();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Month ${auction['monthNumber']} Auction Results',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              _DetailRow(label: 'Winner', value: winnerName),
              _DetailRow(
                label: 'Bid Discount Offered',
                value: currencyFormatter.format(
                  auction['winningBidDiscount'] ?? 0,
                ),
                isRed: true,
              ),
              _DetailRow(
                label: 'Net Prize Remitted',
                value: currencyFormatter.format(auction['prizeMoneyPaid'] ?? 0),
                isGreen: true,
              ),
              const Divider(),
              _DetailRow(
                label: 'Dividend Distributed to Members',
                value: currencyFormatter.format(
                  auction['dividendPerMember'] ?? 0,
                ),
                isGreen: true,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFinalizeAuctionSheet(
    Map<String, dynamic> auction,
    List members,
    Map<String, dynamic> chitDetails,
  ) {
    String? selectedUserId;
    final TextEditingController bidController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Filter members who haven't won and ensure unique users for the dropdown
    final Set<String> uniqueIds = {};
    final List eligibleMembers = members.where((m) {
      if (m['hasWonAuction'] == true) return false;
      final String? uid = m['user']?['id']?.toString();
      if (uid == null || uniqueIds.contains(uid)) return false;
      uniqueIds.add(uid);
      return true;
    }).toList();

    // Pre-fetch future to avoid reloading UI on keyboard popup
    final Future<List<Map<String, dynamic>>> bidsFuture = context
        .read<ChitFundCubit>()
        .getAuctionBids(chitDetails['id'], auction['monthNumber']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: bidsFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200.h,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            }
            final bids = snapshot.data ?? [];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Finalize Month ${auction['monthNumber']} Auction',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // If we have live bids, show them in Dropdown
                    if (bids.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Bidder (Top Bids highest first)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        items: bids.map((b) {
                          final user = b['user'];
                          return DropdownMenuItem<String>(
                            value: user['id'],
                            child: Text(
                              '${user['firstName']} ${user['lastName']} - Bid: ₹${b['bidDiscount']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          selectedUserId = val;
                          final b = bids.firstWhere(
                            (x) => x['user']['id'] == val,
                          );
                          bidController.text = b['bidDiscount'].toString();
                        },
                        validator: (val) =>
                            val == null ? 'Select a user' : null,
                      )
                    else
                      // Fallback to active members list if no live bids fetched
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Winner (No Live Bids yet)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        items: eligibleMembers.map((m) {
                          final user = m['user'];
                          return DropdownMenuItem<String>(
                            value: user['id'],
                            child: Text(
                              '${user['firstName']} ${user['lastName']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          selectedUserId = val;
                        },
                        validator: (val) =>
                            val == null ? 'Select a user' : null,
                      ),
                    SizedBox(height: 16.h),

                    TextFormField(
                      controller: bidController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Bid Discount Amount (₹)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Enter discount amount';
                        }
                        double? v = double.tryParse(val);
                        if (v == null || v < 0) return 'Invalid amount';
                        if (v > chitDetails['totalValue'] * 0.40) {
                          return 'Max 40% bid allowed';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),

                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            double bidVal = double.parse(bidController.text);
                            Navigator.pop(ctx);
                            context.read<ChitFundCubit>().manualFinalizeAuction(
                              chitId: chitDetails['id'],
                              winnerUserId: selectedUserId!,
                              bidDiscount: bidVal,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KhaataTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Process Auction Results',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAuctionTimeline(
    List auctions,
    List members,
    Map<String, dynamic> chitDetails,
  ) {
    if (auctions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("Detailed Timeline preparing...")),
      );
    }

    bool isOwner = chitDetails['isOwner'] == true;
    int activeAuctionMonth =
        int.tryParse(chitDetails['activeAuctionMonth']?.toString() ?? '0') ?? 0;

    final currentUser = context.read<AuthCubit>().currentUser;
    final currentUserId = currentUser?.id ?? '';

    Map<String, dynamic>? myMemberObj;
    for (var m in members) {
      if (m != null && m['user'] != null && m['user']['id'] == currentUserId) {
        myMemberObj = m;
        break;
      }
    }

    final bool hasWonAuction =
        myMemberObj != null && myMemberObj['hasWonAuction'] == true;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: auctions.map((auction) {
          final bool isCompleted = auction['status'] == 'completed';
          final bool isActive = auction['status'] == 'active';

          Color badgeColor = isCompleted
              ? KhaataTheme.accentGreen
              : (isActive ? Colors.amber.shade700 : KhaataTheme.textGrey);
          String badgeText = isCompleted
              ? 'Completed'
              : (isActive ? 'Active Now' : 'Upcoming');

          final int auctionMonth =
              int.tryParse(auction['monthNumber']?.toString() ?? '0') ?? 0;
          final bool isAuctionOpened =
              activeAuctionMonth == auctionMonth && activeAuctionMonth != 0;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: KhaataTheme.cardWhite,
              border: Border.all(
                color: isActive
                    ? Colors.amber.shade400
                    : KhaataTheme.borderGrey,
                width: isActive ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    if (isCompleted) {
                      _showAuctionDetails(auction, chitDetails);
                    } else if (isActive && isOwner && !isAuctionOpened) {
                      _showStartAuctionSheet(auction, chitDetails);
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 45.w,
                        height: 45.w,
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'M${auction['monthNumber']}',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auction Timeline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                            if (isCompleted && auction['winner'] != null)
                              Row(
                                children: [
                                  Text(
                                    'Winner: ${auction['winner']['firstName'] ?? ''}',
                                    style: TextStyle(
                                      color: KhaataTheme.textGrey,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  const Icon(
                                    Icons.workspace_premium,
                                    color: Colors.amber,
                                    size: 16,
                                  ), // Crown 👑
                                ],
                              )
                            else if (isActive && isOwner && !isAuctionOpened)
                              Text(
                                'Tap Open below to start',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else if (isActive && isOwner && isAuctionOpened)
                              Text(
                                'Bidding & Payments Active',
                                style: TextStyle(
                                  color: KhaataTheme.accentGreen,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else if (isActive && !isOwner && isAuctionOpened)
                              Text(
                                'Open for Bidding & Payments',
                                style: TextStyle(
                                  color: KhaataTheme.primaryBlue,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (isActive)
                              Text(
                                'Awaiting owner processing',
                                style: TextStyle(
                                  color: KhaataTheme.textGrey,
                                  fontSize: 13.sp,
                                ),
                              )
                            else
                              Text(
                                'Scheduled Future Phase',
                                style: TextStyle(
                                  color: KhaataTheme.textGrey,
                                  fontSize: 13.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive && isOwner && isAuctionOpened) ...[
                  SizedBox(height: 16.h),
                  const Divider(),
                  SizedBox(height: 8.h),
                  _ActiveAuctionPanel(
                    chitDetails: chitDetails,
                    auction: auction,
                    members: members,
                    finalizeSheet: () => _showFinalizeAuctionSheet(
                      auction,
                      members,
                      chitDetails,
                    ),
                  ),
                ],
                if (isActive && !isOwner && isAuctionOpened) ...[
                  SizedBox(height: 16.h),
                  const Divider(),
                  SizedBox(height: 8.h),
                  _UserBidForm(
                    chitDetails: chitDetails,
                    auction: auction,
                    hasWonAuction: hasWonAuction,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showStartAuctionSheet(
    Map<String, dynamic> auction,
    Map<String, dynamic> chitDetails,
  ) {
    final TextEditingController amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open Auction: Month ${auction['monthNumber']}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Enter the base requested amount for this month. Once opened, a push notification will be sent to all members.',
                  style: TextStyle(
                    color: KhaataTheme.textGrey,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Base Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {
                      double? amount = double.tryParse(amountCtrl.text);
                      if (amount != null && amount >= 0) {
                        Navigator.pop(ctx);
                        context.read<ChitFundCubit>().openAuctionMonth(
                          chitId: chitDetails['id'],
                          monthNumber: auction['monthNumber'],
                          baseAmount: amount,
                        );
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Enter a valid amount')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KhaataTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Open Auction & Notify Members',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
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

  const _DetailRow({
    required this.label,
    required this.value,
    this.isGreen = false,
    this.isRed = false,
  });

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
          Text(
            label,
            style: TextStyle(color: KhaataTheme.textGrey, fontSize: 15.sp),
          ),
          Text(
            value,
            style: TextStyle(
              color: valColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveAuctionPanel extends StatefulWidget {
  final Map<String, dynamic> chitDetails;
  final Map<String, dynamic> auction;
  final List members;
  final VoidCallback finalizeSheet;

  const _ActiveAuctionPanel({
    required this.chitDetails,
    required this.auction,
    required this.members,
    required this.finalizeSheet,
  });

  @override
  State<_ActiveAuctionPanel> createState() => _ActiveAuctionPanelState();
}

class _ActiveAuctionPanelState extends State<_ActiveAuctionPanel> {
  final NumberFormat _fmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  void _showBidsBottomSheet(BuildContext context) async {
    final cubit = context.read<ChitFundCubit>();
    final bids = await cubit.getAuctionBids(
      widget.chitDetails['id'],
      widget.auction['monthNumber'],
    );

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Bids',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.finalizeSheet();
                    },
                    child: const Text(
                      'Finalize',
                      style: TextStyle(
                        color: KhaataTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              if (bids.isEmpty)
                const Center(child: Text('No bids submitted yet.'))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: bids.length,
                    itemBuilder: (c, i) {
                      final bid = bids[i];
                      final bUser = bid['user'] ?? {};
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: KhaataTheme.primaryBlue.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            bUser['firstName']?.substring(0, 1) ?? 'U',
                            style: const TextStyle(
                              color: KhaataTheme.primaryBlue,
                            ),
                          ),
                        ),
                        title: Text(
                          '${bUser['firstName']} ${bUser['lastName']}',
                        ),
                        trailing: Text(
                          _fmt.format(bid['bidDiscount']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: KhaataTheme.accentGreen,
                            fontSize: 16.sp,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int monthNumber = widget.auction['monthNumber'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members Paid Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            TextButton.icon(
              onPressed: () => _showBidsBottomSheet(context),
              icon: const Icon(Icons.gavel, size: 16),
              label: const Text('View Bids'),
              style: TextButton.styleFrom(
                foregroundColor: KhaataTheme.primaryBlue,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ...widget.members.map((m) {
          final user = m['user'] ?? {};
          final paidMonths = ((m['paidMonths'] ?? []) as List)
              .map((e) => e as int)
              .toSet();
          final bool isPaid = paidMonths.contains(monthNumber);

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${user['firstName']} ${user['lastName']}',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.read<ChitFundCubit>().verifyMonthPayment(
                      chitId: widget.chitDetails['id'],
                      monthNumber: monthNumber,
                      subscriberId: m['id'] ?? user['id'],
                      isPaid: !isPaid,
                    );
                  },
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? KhaataTheme.accentGreen
                          : KhaataTheme.dangerRed,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Icon(
                      isPaid ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _UserBidForm extends StatefulWidget {
  final Map<String, dynamic> chitDetails;
  final Map<String, dynamic> auction;
  final bool hasWonAuction;

  const _UserBidForm({
    required this.chitDetails,
    required this.auction,
    required this.hasWonAuction,
  });

  @override
  State<_UserBidForm> createState() => _UserBidFormState();
}

class _UserBidFormState extends State<_UserBidForm> {
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final baseAmountStr =
        widget.chitDetails['activeAuctionBaseAmount']?.toString() ?? '0';

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: KhaataTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: KhaataTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: KhaataTheme.primaryBlue,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Owner requested payment of ₹$baseAmountStr. Please arrange payment and submit your bid below.',
                    style: TextStyle(
                      color: KhaataTheme.textDark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          if (widget.hasWonAuction)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: KhaataTheme.dangerRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.block, color: KhaataTheme.dangerRed, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'You have already won a previous auction. You are not eligible to bid.',
                      style: TextStyle(
                        color: KhaataTheme.dangerRed,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'Submit your Bid / Discount',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter discount amount',
                        prefixText: '₹ ',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton(
                    onPressed: () {
                      double? amount = double.tryParse(_amountController.text);
                      if (amount != null && amount >= 0) {
                        context.read<ChitFundCubit>().submitBid(
                          chitId: widget.chitDetails['id'],
                          bidDiscount: amount,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KhaataTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
}
