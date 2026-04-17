import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../core/services/biometric_auth_service.dart';
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
          onPressed: () {
             context.read<ChitFundCubit>().loadInvitesAndOwned();
             context.pop();
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            color: KhaataTheme.primaryBlue,
            child: Row(
              children: [
                _buildTab(0, "Members"),
                _buildTab(1, "Auctions"),
              ],
            ),
          ),
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
      body: BlocConsumer<ChitFundCubit, ChitFundState>(
        listener: (context, state) {
          if (state is ChitFundActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: KhaataTheme.accentGreen),
            );
          } else if (state is ChitFundError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: KhaataTheme.dangerRed),
            );
          }
        },
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

          return CustomScrollView(
            slivers: [
               SliverToBoxAdapter(
                 child: SizedBox(height: 16.h),
               ),
               if (_selectedIndex == 0)
                  SliverToBoxAdapter(child: _buildMembersTracker(members, chitDetails)),
               if (_selectedIndex == 1)
                  SliverToBoxAdapter(child: _buildAuctionTimeline(auctions, members, chitDetails)),
            ],
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
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
               if (completedMonths == 0 && (chitDetails['status'] ?? '') == 'registration')
                 const Center(child: Text("Process hasn't started yet")),
               if (chitDetails['status'] != 'registration')
                 Flexible(
                   child: ListView.builder(
                     shrinkWrap: true,
                     itemCount: completedMonths + 1, // Include current active month
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
    
    int currentMonth = (chitDetails['completedMonths'] ?? 0) + 1;
    final currentUser = context.read<AuthCubit>().currentUser;
    final currentUserId = currentUser?.id ?? '';
    
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final user = member['user'] ?? {};
        final bool hasWon = member['hasWonAuction'] == true;
        
        final List paidMonthsStr = member['paidMonths'] ?? [];
        final Set<int> paidMonthsSet = paidMonthsStr.map((e) => e as int).toSet();
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
                if (canViewPayment)
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasPaidCurrentMonth ? KhaataTheme.accentGreen : KhaataTheme.dangerRed,
                    ),
                  ),
                if (isOwner) SizedBox(width: 8.w),
                if (isOwner) Icon(Icons.chevron_right, color: KhaataTheme.textGrey)
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAuctionDetails(Map<String, dynamic> auction, Map<String, dynamic> chitDetails) {
    if (auction['status'] == 'pending' || auction['status'] == 'active') {
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
               _DetailRow(label: 'Dividend Distributed to Members', value: currencyFormatter.format(auction['dividendPerMember'] ?? 0), isGreen: true),
            ],
          ),
        );
      }
    );
  }
  
  void _showFinalizeAuctionSheet(Map<String, dynamic> auction, List members, Map<String, dynamic> chitDetails) {
     String? selectedUserId;
     final TextEditingController _bidController = TextEditingController();
     final _formKey = GlobalKey<FormState>();
     
     // Filter members who haven't won
     List eligibleMembers = members.where((m) => m['hasWonAuction'] != true).toList();
     
     showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
        builder: (ctx) {
           return Padding(
             padding: EdgeInsets.only(
               bottom: MediaQuery.of(ctx).viewInsets.bottom,
               left: 20.w, right: 20.w, top: 20.h,
             ),
             child: Form(
               key: _formKey,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Text('Finalize Month ${auction['monthNumber']} Auction', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16.h),
                    
                    DropdownButtonFormField<String>(
                       decoration: InputDecoration(
                          labelText: 'Select Winner',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))
                       ),
                       items: eligibleMembers.map((m) {
                          final user = m['user'];
                          return DropdownMenuItem<String>(
                             value: user['id'],
                             child: Text('${user['firstName']} ${user['lastName']}'),
                          );
                       }).toList(),
                       onChanged: (val) {
                          selectedUserId = val;
                       },
                       validator: (val) => val == null ? 'Select a user' : null,
                    ),
                    SizedBox(height: 16.h),
                    
                    TextFormField(
                       controller: _bidController,
                       keyboardType: TextInputType.number,
                       decoration: InputDecoration(
                          labelText: 'Bid Discount Amount (₹)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))
                       ),
                       validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter discount amount';
                          double? v = double.tryParse(val);
                          if (v == null || v < 0) return 'Invalid amount';
                          if (v > chitDetails['totalValue'] * 0.40) return 'Max 40% bid allowed';
                          return null;
                       },
                    ),
                    SizedBox(height: 24.h),
                    
                    SizedBox(
                       width: double.infinity,
                       height: 50.h,
                       child: ElevatedButton(
                          onPressed: () {
                             if (_formKey.currentState!.validate()) {
                                double bidVal = double.parse(_bidController.text);
                                Navigator.pop(ctx);
                                context.read<ChitFundCubit>().manualFinalizeAuction(
                                   chitId: chitDetails['id'],
                                   winnerUserId: selectedUserId!,
                                   bidDiscount: bidVal
                                );
                             }
                          },
                          style: ElevatedButton.styleFrom(
                             backgroundColor: KhaataTheme.primaryBlue,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))
                          ),
                          child: Text('Process Auction Results', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                       ),
                    ),
                    SizedBox(height: 24.h),
                 ],
               ),
             ),
           );
        }
     );
  }

  Widget _buildAuctionTimeline(List auctions, List members, Map<String, dynamic> chitDetails) {
    if (auctions.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("Detailed Timeline preparing...")));
    }
    
    bool isOwner = chitDetails['isOwner'] == true;
    int activeAuctionMonth = chitDetails['activeAuctionMonth'] ?? 0;
    
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
        String badgeText = isCompleted ? 'Completed' : (isActive ? 'Active Now' : 'Upcoming');

        final bool isAuctionOpened = activeAuctionMonth == auction['monthNumber'];

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: KhaataTheme.cardWhite,
            border: Border.all(color: isActive ? Colors.amber.shade400 : KhaataTheme.borderGrey, width: isActive ? 1.5 : 1.0),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                   if (isCompleted) {
                      _showAuctionDetails(auction, chitDetails);
                   }
                },
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
                            Row(
                              children: [
                                Text(
                                  'Winner: ${auction['winner']['firstName'] ?? ''}',
                                  style: TextStyle(color: KhaataTheme.textGrey, fontSize: 13.sp),
                                ),
                                SizedBox(width: 4.w),
                                const Icon(Icons.workspace_premium, color: Colors.amber, size: 16), // Crown 👑
                              ],
                            )
                          else if (isActive && isOwner && !isAuctionOpened)
                            Text(
                              'Tap Open below to start',
                              style: TextStyle(color: Colors.amber.shade800, fontSize: 13.sp, fontWeight: FontWeight.w600),
                            )
                          else if (isActive && isOwner && isAuctionOpened)
                            Text(
                              'Bidding & Payments Active',
                              style: TextStyle(color: KhaataTheme.accentGreen, fontSize: 13.sp, fontWeight: FontWeight.w600),
                            )
                          else if (isActive)
                            Text(
                              'Awaiting owner processing',
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
              if (isActive && isOwner && !isAuctionOpened) ...[
                 SizedBox(height: 16.h),
                 const Divider(),
                 SizedBox(height: 8.h),
                 _OpenAuctionForm(chitDetails: chitDetails, auction: auction),
              ],
              if (isActive && isOwner && isAuctionOpened) ...[
                 SizedBox(height: 16.h),
                 const Divider(),
                 SizedBox(height: 8.h),
                 _ActiveAuctionPanel(chitDetails: chitDetails, auction: auction, members: members, finalizeSheet: () => _showFinalizeAuctionSheet(auction, members, chitDetails)),
              ],
              if (isActive && !isOwner && isAuctionOpened) ...[
                 SizedBox(height: 16.h),
                 const Divider(),
                 SizedBox(height: 8.h),
                 _UserBidForm(chitDetails: chitDetails, auction: auction),
              ]
            ],
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

class _OpenAuctionForm extends StatefulWidget {
  final Map<String, dynamic> chitDetails;
  final Map<String, dynamic> auction;

  const _OpenAuctionForm({required this.chitDetails, required this.auction});

  @override
  State<_OpenAuctionForm> createState() => _OpenAuctionFormState();
}

class _OpenAuctionFormState extends State<_OpenAuctionForm> {
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Base amount (e.g. Due)',
              prefixText: '₹ ',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        ElevatedButton(
          onPressed: () {
            double? amount = double.tryParse(_amountController.text);
            if (amount != null && amount > 0) {
              context.read<ChitFundCubit>().openAuctionMonth(
                chitId: widget.chitDetails['id'],
                monthNumber: widget.auction['monthNumber'],
                baseAmount: amount,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: KhaataTheme.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
          child: const Text('Open', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

class _ActiveAuctionPanel extends StatefulWidget {
  final Map<String, dynamic> chitDetails;
  final Map<String, dynamic> auction;
  final List members;
  final VoidCallback finalizeSheet;

  const _ActiveAuctionPanel({required this.chitDetails, required this.auction, required this.members, required this.finalizeSheet});

  @override
  State<_ActiveAuctionPanel> createState() => _ActiveAuctionPanelState();
}

class _ActiveAuctionPanelState extends State<_ActiveAuctionPanel> {
  final NumberFormat _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  void _showBidsBottomSheet(BuildContext context) async {
    final cubit = context.read<ChitFundCubit>();
    final bids = await cubit.getAuctionBids(widget.chitDetails['id'], widget.auction['monthNumber']);
    
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
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
                  Text('Current Bids', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.finalizeSheet();
                    },
                    child: Text('Finalize', style: TextStyle(color: KhaataTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  )
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
                          backgroundColor: KhaataTheme.primaryBlue.withOpacity(0.1),
                          child: Text(bUser['firstName']?.substring(0,1) ?? 'U', style: TextStyle(color: KhaataTheme.primaryBlue)),
                        ),
                        title: Text('${bUser['firstName']} ${bUser['lastName']}'),
                        trailing: Text(_fmt.format(bid['bidDiscount']), style: TextStyle(fontWeight: FontWeight.bold, color: KhaataTheme.accentGreen, fontSize: 16.sp)),
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

  @override
  Widget build(BuildContext context) {
    int monthNumber = widget.auction['monthNumber'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Members Paid Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            TextButton.icon(
              onPressed: () => _showBidsBottomSheet(context),
              icon: const Icon(Icons.gavel, size: 16),
              label: const Text('View Bids'),
              style: TextButton.styleFrom(
                foregroundColor: KhaataTheme.primaryBlue,
                visualDensity: VisualDensity.compact,
              ),
            )
          ],
        ),
        SizedBox(height: 8.h),
        ...widget.members.map((m) {
          final user = m['user'] ?? {};
          final paidMonths = ((m['paidMonths'] ?? []) as List).map((e) => e as int).toSet();
          final bool isPaid = paidMonths.contains(monthNumber);

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Text('${user['firstName']} ${user['lastName']}', style: TextStyle(fontSize: 13.sp)),
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
                      color: isPaid ? KhaataTheme.accentGreen : KhaataTheme.dangerRed,
                      borderRadius: BorderRadius.circular(4.r)
                    ),
                    child: Icon(isPaid ? Icons.check : Icons.close, color: Colors.white, size: 16.sp),
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _UserBidForm extends StatefulWidget {
  final Map<String, dynamic> chitDetails;
  final Map<String, dynamic> auction;

  const _UserBidForm({required this.chitDetails, required this.auction});

  @override
  State<_UserBidForm> createState() => _UserBidFormState();
}

class _UserBidFormState extends State<_UserBidForm> {
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final baseAmountStr = widget.chitDetails['activeAuctionBaseAmount']?.toString() ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: KhaataTheme.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: KhaataTheme.primaryBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: KhaataTheme.primaryBlue, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Owner requested payment of ₹$baseAmountStr. Please arrange payment and submit your bid below.',
                  style: TextStyle(color: KhaataTheme.textDark, fontSize: 13.sp, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Submit your Bid / Discount',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter discount amount',
                  prefixText: '₹ ',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              ),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            )
          ],
        )
      ],
    );
  }
}
