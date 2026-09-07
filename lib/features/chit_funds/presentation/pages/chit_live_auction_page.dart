import 'package:khataa/core/utils/error_handler.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/services/biometric_auth_service.dart';

class ChitLiveAuctionPage extends StatefulWidget {
  final String ledgerId;
  const ChitLiveAuctionPage({super.key, required this.ledgerId});

  @override
  State<ChitLiveAuctionPage> createState() => _ChitLiveAuctionPageState();
}

class _ChitLiveAuctionPageState extends State<ChitLiveAuctionPage> {
  late io.Socket _socket;
  bool _isConnected = false;
  double _currentLowestBid = 0;
  String _currentWinnerId = '';
  String _currentWinnerName = 'No bids yet';
  int _timeLeftSeconds = 0;
  bool _auctionEnded = false;
  bool _isPlacingBid = false;
  List<Map<String, dynamic>> _bidFeed = [];
  final TextEditingController _bidController = TextEditingController();
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    final serverUrl =
        dotenv.env['BASE_URL']?.replaceAll('/api', '') ??
        'https://khataa-backend.onrender.com';
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();

    _socket.onConnect((_) {
      if (!mounted) return;
      _reconnectAttempts = 0; // Reset backoff on successful connect
      setState(() => _isConnected = true);
      final authState = context.read<AuthCubit>().state;
      String userId = 'unknown';
      if (authState is AuthenticatedKycComplete) userId = authState.user.id;
      _socket.emit('join_auction', {
        'ledgerId': widget.ledgerId,
        'userId': userId,
      });
    });

    _socket.on('auction_sync', (data) => _handleAuctionData(data));

    _socket.on('bid_update', (data) {
      if (!mounted) return;
      _handleAuctionData(data);
      setState(() {
        _bidFeed.insert(0, {
          'winnerId': data['winnerUser'] ?? '',
          'amount': (data['lowestBid'] ?? 0).toDouble(),
          'time': DateTime.now(),
        });
        if (_bidFeed.length > 20) _bidFeed = _bidFeed.take(20).toList();
      });
    });

    _socket.on('auction_ended', (data) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _auctionEnded = true;
        _currentLowestBid = (data['lowestBid'] ?? 0).toDouble();
        _currentWinnerId = data['winnerUser'] ?? '';
        _currentWinnerName = data['winnerUser'] ?? ''; // fallback
        _timeLeftSeconds = 0;
      });
    });

    _socket.onDisconnect((_) {
      if (!mounted) return;
      setState(() => _isConnected = false);
      _scheduleReconnect();
    });
  }

  int _reconnectAttempts = 0;

  void _scheduleReconnect() {
    if (!mounted || _auctionEnded) return;
    // Exponential backoff: 3s, 6s, 12s, 24s, 30s cap
    final delay = Duration(
      seconds: math.min(3 * math.pow(2, _reconnectAttempts).toInt(), 30),
    );
    Future.delayed(delay, () {
      if (!mounted || _isConnected || _auctionEnded) return;
      _reconnectAttempts++;
      _socket.connect();
    });
  }

  void _handleAuctionData(dynamic data) {
    if (!mounted) return;
    setState(() {
      if (data['lowestBid'] != null) {
        _currentLowestBid = (data['lowestBid']).toDouble();
      }
      if (data['winnerUser'] != null) {
        _currentWinnerId = data['winnerUser'].toString();
        _currentWinnerName = data['winnerUser'].toString();
      }
      if (data['endTime'] != null) {
        final endTime = data['endTime'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        _timeLeftSeconds = ((endTime - now) / 1000)
            .clamp(0, double.infinity)
            .toInt();
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeftSeconds > 0) {
          _timeLeftSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _placeBid() async {
    if (_auctionEnded || _isPlacingBid) return;

    final bidAmount = double.tryParse(_bidController.text.replaceAll(',', ''));
    if (bidAmount == null || bidAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid bid amount'),
          backgroundColor: KhaataTheme.dangerRed,
        ),
      );
      return;
    }

    if (_currentLowestBid > 0 && bidAmount >= _currentLowestBid) {
      ErrorHandler.showError(
        context,
        'Bid must be LOWER than current lowest bid of ₹${_currentLowestBid.toStringAsFixed(0)}',
      );
      return;
    }

    setState(() => _isPlacingBid = true);
    final authState = authCubit.state;
    String userId = 'unknown';
    if (authState is AuthenticatedKycComplete) userId = authState.user.id;

    _socket.emit('place_bid', {
      'ledgerId': widget.ledgerId,
      'userId': userId,
      'bidAmount': bidAmount,
    });

    _bidController.clear();
    if (mounted) setState(() => _isPlacingBid = false);
  }

  String _formatTime(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _socket.disconnect();
    _socket.dispose();
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthParts = widget.ledgerId.split("_");
    final monthLabel = monthParts.isNotEmpty ? monthParts.last : '';

    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF047857),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              '🔴 LIVE AUCTION • Month $monthLabel',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Bidding Room',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.sp),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Icon(
              Icons.circle,
              color: _isConnected
                  ? const Color(0xFF34D399)
                  : KhaataTheme.dangerRed,
              size: 12.w,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (!_isConnected)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                color: KhaataTheme.warningYellow,
                child: Text(
                  'Reconnecting...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildTimerCard(),
                  SizedBox(height: 16.h),
                  _buildLowestBidCard(),
                  SizedBox(height: 16.h),
                  if (!_auctionEnded) _buildBidInputCard(),
                  if (_auctionEnded) _buildAuctionEndedCard(),
                  SizedBox(height: 16.h),
                  _buildLiveBidFeedCard(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: KhaataTheme.primaryBlue, width: 2),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Text(
                  'TIME REMAINING',
                  style: GoogleFonts.inter(
                    color: KhaataTheme.textGrey,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _auctionEnded
                      ? 'AUCTION ENDED'
                      : _formatTime(_timeLeftSeconds),
                  style: GoogleFonts.inter(
                    color: _auctionEnded
                        ? KhaataTheme.dangerRed
                        : KhaataTheme.primaryBlue,
                    fontSize: _auctionEnded ? 28.sp : 48.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (!_auctionEnded && _timeLeftSeconds > 0)
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14.r),
                bottomRight: Radius.circular(14.r),
              ),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  KhaataTheme.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLowestBidCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
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
      child: Column(
        children: [
          Text(
            'CURRENT LOWEST BID',
            style: GoogleFonts.inter(
              color: KhaataTheme.textGrey,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 8.h),
          if (_currentLowestBid > 0) ...[
            Text(
              '₹${_currentLowestBid.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                color: KhaataTheme.textDark,
                fontSize: 36.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: KhaataTheme.primaryBlue,
                  size: 16.w,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Leading: $_currentWinnerName',
                  style: GoogleFonts.inter(
                    color: KhaataTheme.primaryBlue,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No bids yet — be the first!',
              style: GoogleFonts.inter(
                color: KhaataTheme.textGrey,
                fontSize: 18.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveBidFeedCard() {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Text(
                  'LIVE BIDS',
                  style: GoogleFonts.inter(
                    color: KhaataTheme.textDark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8.w),
                if (!_auctionEnded)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: KhaataTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_bidFeed.isEmpty)
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Center(
                child: Text(
                  'Bids will appear here in real time',
                  style: GoogleFonts.inter(
                    color: KhaataTheme.textGrey,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 160.h),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.all(16.w),
                itemCount: _bidFeed.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final bid = _bidFeed[index];
                  final isWinning =
                      bid['winnerId'] == _currentWinnerId && index == 0;

                  return Row(
                    children: [
                      Text(
                        _timeAgo(bid['time'] as DateTime),
                        style: GoogleFonts.inter(
                          color: KhaataTheme.textGrey,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          bid['winnerId']?.toString() ?? 'User',
                          style: GoogleFonts.inter(
                            color: KhaataTheme.textDark,
                            fontSize: 14.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isWinning
                              ? KhaataTheme.primaryBlue.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '₹${(bid['amount'] as double).toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: isWinning
                                ? KhaataTheme.primaryBlue
                                : KhaataTheme.textDark,
                            fontSize: 14.sp,
                            fontWeight: isWinning
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBidInputCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR BID',
                style: GoogleFonts.inter(
                  color: KhaataTheme.textGrey,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              if (_currentLowestBid > 0)
                Text(
                  'Must be less than ₹${_currentLowestBid.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: KhaataTheme.warningYellow,
                    fontSize: 12.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _bidController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: KhaataTheme.textDark,
            ),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: GoogleFonts.inter(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
              hintText: 'Enter amount',
              filled: true,
              fillColor: KhaataTheme.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPlacingBid ? null : _placeBid,
              icon: _isPlacingBid
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.fingerprint, color: Colors.white),
              label: Text(
                _isPlacingBid ? 'Authorizing...' : 'Authorize & Place Bid',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KhaataTheme.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionEndedCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: KhaataTheme.primaryBlue,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            '🏆 Auction Complete!',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Winner: $_currentWinnerName',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            'Winning Bid: ₹${_currentLowestBid.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'The backend is calculating dividends for all members...',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.sp),
          ),
          SizedBox(height: 24.h),
          OutlinedButton(
            onPressed: () {
              if (mounted && context.canPop()) {
                context.pop();
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Return to Hub',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
