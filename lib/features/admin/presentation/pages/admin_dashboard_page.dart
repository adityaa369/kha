import 'package:khatha/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/blocs/admin/admin_cubit.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _loanFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<AdminCubit>().loadStats();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      switch (_tabController.index) {
        case 0:
          context.read<AdminCubit>().loadStats();
          break;
        case 1:
          context.read<AdminCubit>().loadUsers();
          break;
        case 2:
          context.read<AdminCubit>().loadLoans();
          break;
        case 3:
          context.read<AdminCubit>().loadChitFunds();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
              style: TextStyle(fontSize: 11.sp, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined, size: 18),
              text: 'Overview',
            ),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Users'),
            Tab(
              icon: Icon(Icons.account_balance_wallet_outlined, size: 18),
              text: 'Loans',
            ),
            Tab(
              icon: Icon(Icons.group_work_outlined, size: 18),
              text: 'Chit Funds',
            ),
          ],
        ),
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (!mounted) return;
          if (state is AdminActionSuccess) {
            ErrorHandler.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverview(state),
              _buildUsers(state),
              _buildLoans(state),
              _buildChitFunds(state),
            ],
          );
        },
      ),
    );
  }

  // ── OVERVIEW TAB ─────────────────────────────────────────────────────────
  Widget _buildOverview(AdminState state) {
    if (state is AdminLoading)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF059669)),
      );
    if (state is! AdminStatsLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_outlined,
              size: 48.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12.h),
            Text(
              'Tap to load stats',
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () => context.read<AdminCubit>().loadStats(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
              ),
              child: const Text('Load', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    final s = state.stats;
    return RefreshIndicator(
      color: const Color(0xFF059669),
      onRefresh: () => context.read<AdminCubit>().loadStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Growth highlight
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Growth (30 days)',
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      _growthChip(
                        Icons.person_add_outlined,
                        '+${s.newUsers}',
                        'New Users',
                      ),
                      SizedBox(width: 16.w),
                      _growthChip(
                        Icons.add_card_outlined,
                        '+${s.newLoans}',
                        'New Loans',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Platform Stats',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.6,
              children: [
                _statCard(
                  'Total Users',
                  s.totalUsers.toString(),
                  Icons.people_outline,
                  const Color(0xFF3B82F6),
                ),
                _statCard(
                  'Total Loans',
                  s.totalLoans.toString(),
                  Icons.account_balance_wallet_outlined,
                  const Color(0xFF8B5CF6),
                ),
                _statCard(
                  'Active Loans',
                  s.activeLoans.toString(),
                  Icons.trending_up,
                  const Color(0xFF059669),
                ),
                _statCard(
                  'Chit Funds',
                  s.totalChits.toString(),
                  Icons.group_work_outlined,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              'Financial Volume',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _volumeCard(
                    'Loan Volume',
                    s.totalLoanVolume,
                    const Color(0xFF8B5CF6),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _volumeCard(
                    'Chit Volume',
                    s.totalChitVolume,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _growthChip(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20.sp),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 10.sp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _volumeCard(String label, double amount, Color color) {
    final formatted = '\u20b9${_fmtAmount(amount)}';
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey, fontSize: 11.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            formatted,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── USERS TAB ──────────────────────────────────────────────────────────────
  Widget _buildUsers(AdminState state) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, phone or email...',
              hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF059669)),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            onChanged: (v) {
              if (v.isEmpty || v.length >= 3) {
                context.read<AdminCubit>().loadUsers(search: v);
              }
            },
          ),
        ),
        Expanded(
          child: state is AdminLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF059669)),
                )
              : state is AdminUsersLoaded
              ? _buildUserList(state.users, state.total)
              : _buildEmptyOrError(
                  state,
                  () => context.read<AdminCubit>().loadUsers(),
                ),
        ),
      ],
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, int total) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12.h),
            Text(
              'No users found',
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF059669),
      onRefresh: () => context.read<AdminCubit>().loadUsers(),
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: users.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (context, i) => _userCard(users[i]),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final phone = user['phone'] ?? '';
    final email = user['email'] ?? '';
    final isSuspended = user['isSuspended'] == true;
    final isAdmin = user['isAdmin'] == true;
    final userId = user['id'] ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: isSuspended ? Border.all(color: Colors.red.shade200) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? const Color(0xFF059669)
              : const Color(0xFFE5E7EB),
          child: Text(
            initials,
            style: TextStyle(
              color: isAdmin ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name.isEmpty ? phone : name,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
              ),
            ),
            if (isAdmin)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Admin',
                  style: TextStyle(
                    color: const Color(0xFF059669),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (isSuspended)
              Container(
                margin: EdgeInsets.only(left: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Suspended',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phone,
              style: TextStyle(color: Colors.grey, fontSize: 12.sp),
            ),
            if (email.isNotEmpty)
              Text(
                email,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11.sp),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 18.sp, color: Colors.grey),
          onSelected: (action) {
            if (action == 'suspend') {
              context.read<AdminCubit>().suspendUser(userId, !isSuspended);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'suspend',
              child: Row(
                children: [
                  Icon(
                    isSuspended ? Icons.lock_open : Icons.block,
                    size: 16.sp,
                    color: isSuspended ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isSuspended ? 'Unsuspend' : 'Suspend',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOANS TAB ─────────────────────────────────────────────────────────────
  Widget _buildLoans(AdminState state) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in ['all', 'pending_otp', 'active', 'closed'])
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: FilterChip(
                      label: Text(
                        f == 'all'
                            ? 'All'
                            : f.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _loanFilter == f
                              ? Colors.white
                              : const Color(0xFF059669),
                        ),
                      ),
                      selected: _loanFilter == f,
                      selectedColor: const Color(0xFF059669),
                      checkmarkColor: Colors.white,
                      onSelected: (_) {
                        setState(() => _loanFilter = f);
                        context.read<AdminCubit>().loadLoans(
                          status: f == 'all' ? null : f,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: state is AdminLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF059669)),
                )
              : state is AdminLoansLoaded
              ? _buildLoanList(state.loans, state.total)
              : _buildEmptyOrError(
                  state,
                  () => context.read<AdminCubit>().loadLoans(),
                ),
        ),
      ],
    );
  }

  Widget _buildLoanList(List<Map<String, dynamic>> loans, int total) {
    if (loans.isEmpty) {
      return Center(
        child: Text(
          'No loans found',
          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF059669),
      onRefresh: () => context.read<AdminCubit>().loadLoans(),
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: loans.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, i) => _loanCard(loans[i]),
      ),
    );
  }

  Widget _loanCard(Map<String, dynamic> loan) {
    final amount = (loan['amountPaise'] != null
        ? loan['amountPaise'] / 100.0
        : (loan['amount'] ?? 0).toDouble());
    final status = loan['status'] ?? 'unknown';
    final type = loan['loanType'] ?? 'loan';
    final borrower = loan['borrowerName'] ?? 'Unknown';
    Color statusColor = status == 'active'
        ? const Color(0xFF059669)
        : status == 'closed'
        ? Colors.blue.shade700
        : Colors.orange.shade700;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: statusColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  borrower,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  type.replaceAll('_', ' '),
                  style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\u20b9${_fmtAmount(amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CHIT FUNDS TAB ────────────────────────────────────────────────────────
  Widget _buildChitFunds(AdminState state) {
    if (state is AdminLoading)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF059669)),
      );
    if (state is! AdminChitsLoaded) {
      return _buildEmptyOrError(
        state,
        () => context.read<AdminCubit>().loadChitFunds(),
      );
    }
    if (state.chits.isEmpty) {
      return Center(
        child: Text(
          'No chit funds found',
          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF059669),
      onRefresh: () => context.read<AdminCubit>().loadChitFunds(),
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: state.chits.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, i) => _chitCard(state.chits[i]),
      ),
    );
  }

  Widget _chitCard(Map<String, dynamic> chit) {
    final name = chit['name'] ?? 'Unnamed';
    final totalValue = (chit['totalValue'] ?? 0).toDouble();
    final members =
        (chit['members'] as List?)?.length ?? (chit['memberCount'] ?? 0);
    final currentMonth = chit['currentMonth'] ?? 1;
    final totalMonths = chit['totalMonths'] ?? 12;
    final status = chit['status'] ?? 'pending';
    Color statusColor = status == 'active'
        ? const Color(0xFF059669)
        : status == 'completed'
        ? Colors.blue
        : Colors.orange;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
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
                name,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.currency_rupee, size: 14.sp, color: Colors.grey),
              Text(
                '\u20b9${_fmtAmount(totalValue)}',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 16.w),
              Icon(Icons.people_outline, size: 14.sp, color: Colors.grey),
              Text(
                '$members members',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
              SizedBox(width: 16.w),
              Icon(
                Icons.calendar_today_outlined,
                size: 14.sp,
                color: Colors.grey,
              ),
              Text(
                'Month $currentMonth/$totalMonths',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: totalMonths > 0 ? currentMonth / totalMonths : 0,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 4.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrError(AdminState state, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state is AdminError) ...[
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red.shade400),
            SizedBox(height: 12.h),
            Text(
              state.message,
              style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Icon(
              Icons.inbox_outlined,
              size: 48.sp,
              color: Colors.grey.shade400,
            ),
          ],
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Load Data',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAmount(double amount) {
    if (amount >= 10000000)
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}
