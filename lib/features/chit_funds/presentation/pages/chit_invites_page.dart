import 'package:flutter/material.dart';
import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../core/blocs/chit_funds/chit_fund_cubit.dart';
import '../../../../core/blocs/chit_funds/chit_fund_state.dart';
import '../../../../data/models/chit_fund_model.dart';
import '../../../../data/models/chit_invite_model.dart';
import '../../../../config/constants.dart';
import '../../../../core/services/biometric_auth_service.dart';

class ChitInvitesPage extends StatefulWidget {
  const ChitInvitesPage({super.key});

  @override
  State<ChitInvitesPage> createState() => _ChitInvitesPageState();
}

class _ChitInvitesPageState extends State<ChitInvitesPage> {
  int _selectedIndex = 0; // 0 = Invites, 1 = My Created Groups

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChitFundCubit>().loadInvitesAndOwned();
    });
  }

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  void _showInviteDialog(ChitFundModel chit) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Invite to ${chit.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the mobile number of the user you want to invite to this group.'),
              SizedBox(height: 16.h),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+91 XXXXXXXXXX',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.isNotEmpty) {
                Navigator.pop(ctx);
                context.read<ChitFundCubit>().sendInvite(chit.id, phoneController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: KhaataTheme.primaryBlue),
            child: const Text('Send Invite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(ChitInviteModel invite) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Invitation?'),
        content: Text(
          'Join ${invite.chitFund.name} created by ${invite.senderName}?\n\n'
          'Monthly Installment: ${currencyFormatter.format(invite.chitFund.monthlySubscription)}\n'
          'Duration: ${invite.chitFund.totalMonths} Months',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChitFundCubit>().respondToInvite(invite.id, 'declined');
            },
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChitFundCubit>().respondToInvite(invite.id, 'accepted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: KhaataTheme.primaryBlue),
            child: const Text('Accept & Join', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Chit Fund Network',
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
      ),
      body: BlocConsumer<ChitFundCubit, ChitFundState>(
        listener: (context, state) {
          if (state is ChitFundActionSuccess) {
            context.push(AppConstants.chitSuccess);
          } else if (state is ChitFundError) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is ChitFundLoading || state is ChitFundInitial) {
             return const Center(child: CircularProgressIndicator());
          }
          
          List<ChitInviteModel> invites = [];
          List<ChitFundModel> owned = [];
          if (state is ChitFundInvitesLoaded) {
             invites = state.pendingInvites;
             owned = state.ownedChits;
          }

          return Column(
            children: [
              // Custom Tab Bar
              Container(
                color: KhaataTheme.primaryBlue,
                child: Row(
                  children: [
                    _buildTab(0, 'Received Invites (${invites.length})'),
                    _buildTab(1, 'My Groups (${owned.length})'),
                  ],
                ),
              ),
              Expanded(
                child: _selectedIndex == 0
                    ? _buildInvitesList(invites)
                    : _buildOwnedList(owned),
              ),
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
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvitesList(List<ChitInviteModel> invites) {
    if (invites.isEmpty) {
       return const Center(child: Text("No pending invites.", style: TextStyle(color: KhaataTheme.textGrey)));
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: invites.length,
      itemBuilder: (context, index) {
        final invite = invites[index];
        final chit = invite.chitFund;
        return _buildCard(
          title: chit.name,
          badge: 'From: ${invite.senderName}',
          detail1Label: 'Total Value', detail1Val: currencyFormatter.format(chit.totalValue),
          detail2Label: 'Monthly', detail2Val: currencyFormatter.format(chit.monthlySubscription),
          detail3Label: 'Duration', detail3Val: '${chit.totalMonths} Mo',
          actionLabel: 'Review Invitation',
          onAction: () => _showAcceptDialog(invite),
        );
      },
    );
  }

  Widget _buildOwnedList(List<ChitFundModel> owned) {
    if (owned.isEmpty) {
       return const Center(child: Text("You haven't created any forming groups.", style: TextStyle(color: KhaataTheme.textGrey)));
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: owned.length,
      itemBuilder: (context, index) {
        final chit = owned[index];
        final bool isFull = chit.currentSubscribersCount >= chit.totalMonths;
        return _buildCard(
          title: chit.name,
          badge: isFull ? 'Active/Full' : 'Forming',
          detail1Label: 'Total Value', detail1Val: currencyFormatter.format(chit.totalValue),
          detail2Label: 'Members', detail2Val: '${chit.currentSubscribersCount}/${chit.totalMonths}',
          detail3Label: 'Monthly', detail3Val: currencyFormatter.format(chit.monthlySubscription),
          actionLabel: isFull ? 'Manage Group' : 'Invite Members',
          onAction: () {
             if (isFull) {
                 context.push(AppConstants.chitAdminDashboard, extra: chit.id);
             } else {
                 _showInviteDialog(chit);
             }
          },
          onDelete: () async {
            final auth = await BiometricAuthService.authenticate();
            if (auth && context.mounted) {
              context.read<ChitFundCubit>().deleteChitFund(chit.id);
            }
          },
          secondaryActionLabel: !isFull ? 'Dashboard' : null,
          onSecondaryAction: !isFull ? () => context.push(AppConstants.chitAdminDashboard, extra: chit.id) : null,
        );
      },
    );
  }

  Widget _buildCard({
     required String title,
     required String badge,
     required String detail1Label, required String detail1Val,
     required String detail2Label, required String detail2Val,
     required String detail3Label, required String detail3Val,
     required String actionLabel,
     required VoidCallback onAction,
     String? secondaryActionLabel,
     VoidCallback? onSecondaryAction,
     VoidCallback? onDelete,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: KhaataTheme.cardWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: KhaataTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Text(
                title,
                style: TextStyle(
                  color: KhaataTheme.textDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: KhaataTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: KhaataTheme.primaryBlue,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: KhaataTheme.textGrey),
                      onSelected: (val) {
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (c) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Group', style: TextStyle(color: Colors.red)),
                        )
                      ],
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoCol(title: detail1Label, value: detail1Val),
              _InfoCol(title: detail2Label, value: detail2Val, isCenter: true),
              _InfoCol(title: detail3Label, value: detail3Val, isRight: true),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhaataTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              if (secondaryActionLabel != null) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondaryAction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KhaataTheme.primaryBlue,
                      side: BorderSide(color: KhaataTheme.primaryBlue),
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        secondaryActionLabel,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String title;
  final String value;
  final bool isCenter;
  final bool isRight;

  const _InfoCol({
    required this.title,
    required this.value,
    this.isCenter = false,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isCenter
            ? CrossAxisAlignment.center
            : (isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start),
        children: [
          Text(
            title,
            style: TextStyle(
              color: KhaataTheme.textGrey,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: KhaataTheme.textDark,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
