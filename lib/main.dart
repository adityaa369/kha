import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'core/blocs/auth/auth_cubit.dart';
import 'core/blocs/loans/loan_cubit.dart';
import 'core/blocs/credit_score/credit_score_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://cufknkxlxcigwxtxmqmc.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1Zmtua3hseGNpZ3d4dHhtcW1jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwMjMzOTQsImV4cCI6MjA4NTU5OTM5NH0.o3MYsC7NX1HVYZmROJcwXFpAAhtegRMGwL2IUi1oESk', // Replace with your Supabase anon key
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KhaataApp());
}

class KhaataApp extends StatelessWidget {
  const KhaataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()..checkAuthStatus()),
        BlocProvider(create: (_) => LoanCubit()),
        BlocProvider(create: (_) => CreditScoreCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Khaata',
            theme: KhaataTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}