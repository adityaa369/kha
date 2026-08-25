import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../../../core/blocs/chit_funds/chit_fund_cubit.dart';
import '../../../../core/blocs/chit_funds/chit_fund_state.dart';
import '../../../../data/models/chit_fund_model.dart';
import '../../../../data/models/chit_invite_model.dart';
import '../../../home/presentation/cubit/notification_cubit.dart';
import '../../../home/presentation/cubit/notification_state.dart';

class ChitHomePage extends StatefulWidget {
  const ChitHomePage({super.key});

  @override
  State<ChitHomePage> createState() => _ChitHomePageState();
}

class _ChitHomePageState extends State<ChitHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  
  final Color _primaryColor = const Color(0xFF059669);
  final Color _secondaryColor = const Color(0xFF10B981);
  final Color _bgColor = const Color(0xFFF8FAFC);
  final Color _textColorDark = const Color(0xFF1F2937);
  final Color _textColorGrey = const Color(0xFF6B7280);
  final Color _borderColor = const Color(0xFFE5E7EB);
  final Color _dangerColor = const Color(0xFFEF4444);
  final Color _warningColor = const Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChitFundCubit>().loadInvitesAndOwned();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChitFundCubit, ChitFundState>(
      listener: (context, state) {
        if (state is ChitFundActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: _primaryColor,
            ),
          );
        } else if (state is ChitFundError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: _dangerColor,
            ),
          );
        }
      },

      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: _buildAppBar(),
        body: BlocBuilder<ChitFundCubit, ChitFundState>(
          builder: (context, state) {
            if (state is ChitFundLoading) {
              return Center(child: CircularProgressIndicator(color: _primaryColor));
            }
            if (state is ChitFundError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }

            int activeGroups = 0;
            double totalPoolValue = 0;
            int pendingInvitesCount = 0;

            List<Map<String, dynamic>> mySubscriptions = [];
            List<ChitFundModel> ownedChits = [];
            List<ChitInviteModel> pendingInvites = [];

            if (state is ChitFundInvitesLoaded) {
              mySubscriptions = state.mySubscriptions
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
              ownedChits = state.ownedChits;
              pendingInvites = state.pendingInvites;
              activeGroups = mySubscriptions.length;
              for (var sub in mySubscriptions) {
                totalPoolValue += (sub['totalValue'] as num?)?.toDouble() ?? 0.0;
              }
              pendingInvitesCount = pendingInvites.length;
            }

            return Column(
              children: [
                _buildSummaryBanner(activeGroups, totalPoolValue, pendingInvitesCount),
                _buildTabBar(pendingInvitesCount),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyJoinedTab(mySubscriptions),
                      _buildIManageTab(ownedChits),
                      _buildInvitesTab(pendingInvites),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.push(AppConstants.createChit);
          },
          backgroundColor: _primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'New Group',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Chit Funds Hub',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            int unreadCount = 0;
            if (state.runtimeType.toString().contains('Loaded')) {
              try {
                unreadCount = (state as dynamic).unreadCount ?? 0;
              } catch (_) {}
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    context.push(AppConstants.notifications);
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryBanner(int activeGroups, double totalPoolValue, int pendingInvitesCount) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [Colors.white, _bgColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatColumn('Active Groups', activeGroups.toString()),
          Container(height: 40.h, width: 1.w, color: _borderColor),
          _buildStatColumn('Total Pool', _currencyFormat.format(totalPoolValue)),
          Container(height: 40.h, width: 1.w, color: _borderColor),
          _buildStatColumn('Invites', pendingInvitesCount.toString(), showDot: pendingInvitesCount > 0),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {bool showDot = false}) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: _textColorGrey, fontSize: 12.sp),
            ),
            if (showDot) ...[
              SizedBox(width: 4.w),
              Container(
                width: 6.r,
                height: 6.r,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              )
            ]
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.inter(
            color: _textColorDark,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(int pendingInvitesCount) {
    return Container(
      color: _primaryColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.08),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp),
        tabs: [
          const Tab(text: 'My Joined'),
          const Tab(text: 'I Manage'),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Invites'),
                if (pendingInvitesCount > 0) ...[
                  SizedBox(width: 4.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _dangerColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      pendingInvitesCount.toString(),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 10.sp),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyJoinedTab(List<Map<String, dynamic>> subscriptions) {
    if (subscriptions.isEmpty) {
      return Center(
        child: Text('No joined groups yet', style: GoogleFonts.inter(color: _textColorGrey)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        final chitName = sub['chitName'] as String? ?? 'Unknown Group';
        final status = sub['status'] as String? ?? 'FORMING';
        final completedMonths = (sub['completedMonths'] as num?)?.toInt() ?? 0;
        final totalMonths = (sub['totalMonths'] as num?)?.toInt() ?? 1;
        final totalValue = (sub['totalValue'] as num?)?.toDouble() ?? 0.0;
        final dueAmount = (sub['dueAmount'] as num?)?.toDouble() ?? 0.0;
        final activeAuctionMonth = sub['activeAuctionMonth'];
        final isLive = status == 'LIVE' || activeAuctionMonth != null;

        return GestureDetector(
          onTap: () => context.push('/chit-member-detail', extra: sub['chitId']),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        chitName,
                        style: GoogleFonts.inter(
                          color: _textColorDark,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(status, isLive: isLive),
                  ],
                ),
                if (isLive) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Live Auction Month ${activeAuctionMonth ?? completedMonths + 1}',
                    style: GoogleFonts.inter(color: _warningColor, fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                ],
                SizedBox(height: 12.h),
                Text(
                  'Pot Value: ${_currencyFormat.format(totalValue)}',
                  style: GoogleFonts.inter(color: _textColorGrey, fontSize: 13.sp),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: totalMonths > 0 ? completedMonths / totalMonths : 0,
                          backgroundColor: _borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                          minHeight: 6.h,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '$completedMonths/$totalMonths months',
                      style: GoogleFonts.inter(color: _textColorGrey, fontSize: 12.sp, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Due: ${_currencyFormat.format(dueAmount)}',
                      style: GoogleFonts.inter(color: _dangerColor, fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'View Details →',
                      style: GoogleFonts.inter(color: _primaryColor, fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIManageTab(List<ChitFundModel> ownedChits) {
    if (ownedChits.isEmpty) {
      return Center(
        child: Text('You don\'t manage any groups', style: GoogleFonts.inter(color: _textColorGrey)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: ownedChits.length,
      itemBuilder: (context, index) {
        final chit = ownedChits[index];
        final currentSubscribersCount = chit.currentSubscribersCount;
        final totalMonths = chit.totalMonths;
        final name = chit.name;
        final status = chit.status;

        return GestureDetector(
          onTap: () => context.push(AppConstants.chitAdminDashboard, extra: chit.id),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          color: _textColorDark,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$currentSubscribersCount/$totalMonths members joined',
                            style: GoogleFonts.inter(color: _textColorGrey, fontSize: 13.sp),
                          ),
                          SizedBox(height: 6.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: totalMonths > 0 ? currentSubscribersCount / totalMonths : 0,
                              backgroundColor: _borderColor,
                              valueColor: AlwaysStoppedAnimation<Color>(_secondaryColor),
                              minHeight: 4.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      status == 'registration' ? 'Invite Members →' : 'Manage Group →',
                      style: GoogleFonts.inter(color: _primaryColor, fontSize: 13.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitesTab(List<ChitInviteModel> invites) {
    if (invites.isEmpty) {
      return Center(
        child: Text('No pending invites', style: GoogleFonts.inter(color: _textColorGrey)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: invites.length,
      itemBuilder: (context, index) {
        final invite = invites[index];
        final senderName = invite.senderName;
        final chitFund = invite.chitFund;
        final chitName = chitFund.name;
        final potValue = chitFund.totalValue;
        final monthlyAmount = chitFund.monthlySubscription;
        final duration = chitFund.totalMonths;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chitName,
                style: GoogleFonts.inter(
                  color: _textColorDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Invited by $senderName',
                style: GoogleFonts.inter(color: _textColorGrey, fontSize: 13.sp),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInviteInfoCol('Pot Value', _currencyFormat.format(potValue)),
                  _buildInviteInfoCol('Monthly', _currencyFormat.format(monthlyAmount)),
                  _buildInviteInfoCol('Duration', '$duration months'),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _dangerColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onPressed: () => context.read<ChitFundCubit>().respondToInvite(invite.id, 'declined'),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.inter(color: _dangerColor, fontWeight: FontWeight.w600, fontSize: 14.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                      ),
                      onPressed: () => context.read<ChitFundCubit>().respondToInvite(invite.id, 'accepted'),
                      child: Text(
                        'Accept & Join',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.sp),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildInviteInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: _textColorGrey, fontSize: 12.sp),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.inter(color: _textColorDark, fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, {bool isLive = false}) {
    Color bg;
    Color fg;
    String text = status;

    if (isLive || status == 'LIVE') {
      bg = _dangerColor.withValues(alpha: 0.08);
      fg = _dangerColor;
      text = '🔴 LIVE';
    } else if (status == 'FORMING' || status == 'REGISTERING') {
      bg = _warningColor.withValues(alpha: 0.08);
      fg = _warningColor;
    } else {
      bg = _primaryColor.withValues(alpha: 0.08);
      fg = _primaryColor;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          color: fg,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textColorGrey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w500),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppConstants.home);
              break;
            case 1:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No active auction to bid in', style: GoogleFonts.inter(color: Colors.white)),
                  backgroundColor: _dangerColor,
                ),
              );
              break;
            case 2:
              context.push(AppConstants.notifications);
              break;
            case 3:
              context.push(AppConstants.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel_outlined), activeIcon: Icon(Icons.gavel), label: 'Bid'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

