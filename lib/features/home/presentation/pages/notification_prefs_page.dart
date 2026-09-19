import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/theme.dart';
import '../cubit/notification_prefs_cubit.dart';


class NotificationPrefsPage extends StatelessWidget {
  const NotificationPrefsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Notification Preferences',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: KhaataTheme.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: KhaataTheme.textDark,
        elevation: 0,
      ),
      body: BlocConsumer<NotificationPrefsCubit, NotificationPrefsState>(
        listener: (context, state) {
          if (state is NotificationPrefsLoaded && state.saveError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.saveError!),
                backgroundColor: KhaataTheme.dangerRed,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationPrefsLoading || state is NotificationPrefsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationPrefsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: KhaataTheme.dangerRed, size: 48.sp),
                  SizedBox(height: 16.h),
                  Text(state.message, style: TextStyle(color: KhaataTheme.textDark)),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => context.read<NotificationPrefsCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationPrefsLoaded) {
            final prefs = state.prefs;
            return ListView(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              children: [
                _buildSectionHeader('MANDATORY'),
                _buildPrefTile(
                  title: 'Security Alerts',
                  subtitle: 'New logins, MPIN changes, profile updates.',
                  value: prefs.securityAlerts,
                  onChanged: null, // Disabled / Read-only
                ),
                SizedBox(height: 24.h),
                
                _buildSectionHeader('TRANSACTIONAL'),
                _buildPrefTile(
                  title: 'Loan Updates',
                  subtitle: 'New loans, agreement approvals, status changes.',
                  value: prefs.loanUpdates,
                  onChanged: (val) => context.read<NotificationPrefsCubit>().update(
                    prefs.copyWith(loanUpdates: val),
                  ),
                ),
                _buildPrefTile(
                  title: 'Payment Updates',
                  subtitle: 'Payments recorded, credited, or failed.',
                  value: prefs.paymentUpdates,
                  onChanged: (val) => context.read<NotificationPrefsCubit>().update(
                    prefs.copyWith(paymentUpdates: val),
                  ),
                ),
                _buildPrefTile(
                  title: 'KYC Updates',
                  subtitle: 'Verification status and document requirements.',
                  value: prefs.kycUpdates,
                  onChanged: (val) => context.read<NotificationPrefsCubit>().update(
                    prefs.copyWith(kycUpdates: val),
                  ),
                ),
                _buildPrefTile(
                  title: 'Chit Fund Updates',
                  subtitle: 'Invitations, auctions, and ledger updates.',
                  value: prefs.chitFundUpdates,
                  onChanged: (val) => context.read<NotificationPrefsCubit>().update(
                    prefs.copyWith(chitFundUpdates: val),
                  ),
                ),
                SizedBox(height: 24.h),

                _buildSectionHeader('OPTIONAL'),
                _buildPrefTile(
                  title: 'Promotional',
                  subtitle: 'Offers, tips, and new feature announcements.',
                  value: prefs.promotional,
                  onChanged: (val) => context.read<NotificationPrefsCubit>().update(
                    prefs.copyWith(promotional: val),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: KhaataTheme.textGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPrefTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      color: Colors.white,
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: KhaataTheme.textDark,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.sp,
              color: KhaataTheme.textGrey,
            ),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: KhaataTheme.primaryBlue,
        activeThumbColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      ),
    );
  }
}
