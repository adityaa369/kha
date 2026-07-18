import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChitLiveAuctionPage extends StatefulWidget {
  final String ledgerId;
  const ChitLiveAuctionPage({super.key, required this.ledgerId});

  @override
  State<ChitLiveAuctionPage> createState() => _ChitLiveAuctionPageState();
}

class _ChitLiveAuctionPageState extends State<ChitLiveAuctionPage> {
  late io.Socket _socket;
  
  // UI State mapping
  bool _isConnected = false;
  double _currentLowestBid = 0;
  String _currentWinner = 'None';
  int _timeLeft = 0;
  bool _auctionEnded = false;

  final TextEditingController _bidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    final serverUrl = dotenv.env['BASE_URL']?.replaceAll('/api', '') ?? 'https://khataa-backend.onrender.com';
    
    _socket = io.io(serverUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build()
    );

    _socket.connect();

    _socket.onConnect((_) {
      if (!mounted) return;
      setState(() => _isConnected = true);
      
      final authState = context.read<AuthCubit>().state;
      String userId = 'unknown';
      if (authState is AuthenticatedFull) userId = authState.user.id;

      _socket.emit('join_auction', {
        'ledgerId': widget.ledgerId,
        'userId': userId,
      });
    });

    _socket.on('auction_sync', (data) {
      if (!mounted) return;
      _updateStateFromData(data);
    });

    _socket.on('bid_update', (data) {
      if (!mounted) return;
      _updateStateFromData(data);
    });

    _socket.on('auction_ended', (data) {
      if (!mounted) return;
      setState(() {
        _auctionEnded = true;
        _currentLowestBid = (data['lowestBid'] ?? 0).toDouble();
        _currentWinner = data['winnerUser'] ?? 'None';
        _timeLeft = 0;
      });
    });

    _socket.onDisconnect((_) {
      if (!mounted) return;
      setState(() => _isConnected = false);
    });
  }

  void _updateStateFromData(dynamic data) {
    setState(() {
      _currentLowestBid = (data['lowestBid'] ?? 0).toDouble();
      _currentWinner = data['winnerUser'] ?? 'None';
      
      if (data['endTime'] != null) {
        final endTime = data['endTime'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        _timeLeft = ((endTime - now) / 1000).clamp(0, double.infinity).toInt();
      }
    });
  }

  void _placeBid() {
    if (_auctionEnded) return;
    
    final bidAmount = double.tryParse(_bidController.text) ?? 0.0;
    
    // Predictive Local Validation: Prevent wasting network calls
    if (bidAmount >= _currentLowestBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid must be lower than current lowest bid!')),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    String userId = 'unknown';
    if (authState is AuthenticatedFull) userId = authState.user.id;

    _socket.emit('place_bid', {
      'ledgerId': widget.ledgerId,
      'userId': userId,
      'bidAmount': bidAmount,
    });
    
    _bidController.clear();
  }

  @override
  void dispose() {
    // Explicit teardown to prevent memory leaks and zombie sockets
    _socket.disconnect();
    _socket.dispose();
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Live Auction Room', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: KhaataTheme.cardWhite,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _isConnected ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isConnected ? 'Connected to Socket' : 'Disconnected',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                  Icon(
                    _isConnected ? Icons.wifi : Icons.wifi_off,
                    color: _isConnected ? Colors.green : Colors.red,
                  )
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Seconds Remaining',
              style: TextStyle(color: Colors.grey, fontSize: 16.sp),
            ),
            Text(
              '$_timeLeft',
              style: TextStyle(color: Colors.white, fontSize: 48.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.redAccent.shade700.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Column(
                children: [
                  Text('Lowest Bid', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                  Text(
                    '₹${_currentLowestBid.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.redAccent, fontSize: 32.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text('Current Winner: $_currentWinner', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
            const Spacer(),
            if (!_auctionEnded)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bidController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter lower bid...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: KhaataTheme.cardWhite,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: _placeBid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700,
                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: const Text('BID DOWN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green),
                ),
                child: Center(
                  child: Text(
                    'Auction Closed. Winner: $_currentWinner\nValidating math on backend...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.greenAccent, fontSize: 16.sp),
                  ),
                ),
              ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
