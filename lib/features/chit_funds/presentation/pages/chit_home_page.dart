import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../core/blocs/chit_funds/chit_fund_cubit.dart';
import '../../../../core/blocs/chit_funds/chit_fund_state.dart';
import '../../../../data/models/chit_fund_model.dart';
import '../../../../data/models/chit_invite_model.dart';

class ChitHomePage extends StatefulWidget {
  const ChitHomePage({super.key});

  @override
  State<ChitHomePage> createState() => _ChitHomePageState();
}

class _ChitHomePageState extends State<ChitHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<ChitFundCubit>().loadInvitesAndOwned();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Chit Funds Hub',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: KhaataTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
          tabs: const [
            Tab(text: 'My Joined Groups'),
            Tab(text: 'Groups Manage'),
            Tab(text: 'Pending Invites'),
          ],
        ),
      ),
      body: BlocBuilder<ChitFundCubit, ChitFundState>(
        builder: (context, state) {
          if (state is ChitFundLoading) {
            return const Center(child: CircularProgressIndicator(color: KhaataTheme.primaryBlue));
          } else if (state is ChitFundError) {
            return Center(child: Text(state.message, style: TextStyle(color: KhaataTheme.dangerRed)));
          } else if (state is ChitFundInvitesLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildJoinedList(
                  items: state.mySubscriptions,
                ),
                _buildList(
                  items: state.ownedChits,
                  emptyMessage: 'You do not manage any Chit Funds.',
                  emptyIcon: Icons.admin_panel_settings,
                  isManaged: true,
                ),
                _buildInvitesList(state.pendingInvites),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.createChit),
        backgroundColor: KhaataTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
                _buildNavItem(icon: Icons.gavel_rounded, label: 'Bid', index: 1),
                _buildNavItem(icon: Icons.notifications_rounded, label: 'Notifications', index: 2),
                _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList({required List<ChitFundModel> items, required String emptyMessage, required IconData emptyIcon, required bool isManaged}) {
    if (items.isEmpty) return _buildEmptyState(emptyMessage, emptyIcon);
    
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final chit = items[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            leading: CircleAvatar(
              backgroundColor: KhaataTheme.primaryBlue.withValues(alpha: 0.1),
              child: Icon(isManaged ? Icons.admin_panel_settings : Icons.group, color: KhaataTheme.primaryBlue),
            ),
            title: Text(chit.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            subtitle: Text('Pot: ₹${chit.totalValue} • ${chit.totalMonths} Months'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
            onTap: () {
                if (isManaged) {
                    context.push(AppConstants.chitAdminDashboard, extra: chit.id);
                } else {
                    context.push(AppConstants.myChits); 
                }
            },
          ),
        );
      },
    );
  }
  
  Widget _buildJoinedList({required List<Map<String, dynamic>> items}) {
    if (items.isEmpty) return _buildEmptyState('You are not part of any Chit Funds yet.', Icons.groups);
    
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final chitMap = items[index];
        final name = chitMap['name'] ?? 'Chit Fund';
        final val = chitMap['totalValue'] ?? 0;
        final months = chitMap['totalMonths'] ?? 0;
        
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            leading: CircleAvatar(
              backgroundColor: KhaataTheme.primaryBlue.withValues(alpha: 0.1),
              child: Icon(Icons.group, color: KhaataTheme.primaryBlue),
            ),
            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            subtitle: Text('Pot: ₹$val • $months Months'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
            onTap: () {
                context.push(AppConstants.myChits); 
            },
          ),
        );
      },
    );
  }

  Widget _buildInvitesList(List<ChitInviteModel> invites) {
    if (invites.isEmpty) return _buildEmptyState('No pending invites.', Icons.mail_outline);
    
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: invites.length,
      itemBuilder: (context, index) {
        final invite = invites[index];
        
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            title: Text(invite.chitFund?.name ?? 'Chit Invite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            subtitle: const Text('You have been invited to join this chit fund.'),
            trailing: ElevatedButton(
              onPressed: () {
                  context.read<ChitFundCubit>().respondToInvite(invite.id, 'accepted');
              },
              style: ElevatedButton.styleFrom(backgroundColor: KhaataTheme.primaryBlue),
              child: const Text('Accept', style: TextStyle(color: Colors.white)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: KhaataTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64.sp, color: KhaataTheme.primaryBlue),
          ),
          SizedBox(height: 24.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: KhaataTheme.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (icon == Icons.groups) ...[
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => context.push(AppConstants.createChit),
              style: ElevatedButton.styleFrom(
                backgroundColor: KhaataTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              ),
              child: Text(
                'Create a New Group',
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 2) {
            context.push(AppConstants.notifications);
        } else if (index == 3) {
            context.push(AppConstants.profile);
        } else if (index == 0) {
            context.go(AppConstants.home);
        } else {
            setState(() => _bottomNavIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? KhaataTheme.primaryBlue : Colors.grey,
            size: 24.sp,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isSelected ? KhaataTheme.primaryBlue : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
