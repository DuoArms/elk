import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/customer_cubit.dart';
import 'cubits/driver_cubit.dart';
import 'cubits/store_cubit.dart';
import 'cubits/store_type_cubit.dart';   // 🆕
import 'cubits/unit_cubit.dart';
import 'cubits/size_cubit.dart';         // 🆕
import 'cubits/product_cubit.dart';
import 'cubits/order_cubit.dart';
import 'screens/splash_screen.dart';
import 'cubits/NotificationCubit.dart';
import 'cubits/accounting_cubit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => CustomerCubit()),
        BlocProvider(create: (_) => DriverCubit()),
        BlocProvider(create: (_) => StoreCubit()),
        BlocProvider(create: (_) => StoreTypeCubit()),   // ✅
        BlocProvider(create: (_) => UnitCubit()),
        BlocProvider(create: (_) => SizeCubit()),
        BlocProvider(create: (_) => ProductCubit()),
        BlocProvider(create: (_) => OrderCubit()),
        BlocProvider(create: (_) => NotificationCubit()), // <-- أضف هذا السطر
        BlocProvider(create: (_) => AccountingCubit()),


      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ELK Delivery',
        theme: ThemeData(
          primarySwatch: Colors.cyan,
          fontFamily: 'OsamaFont',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}