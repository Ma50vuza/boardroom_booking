import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boardroom_booking/providers/auth_provider.dart';
import 'package:boardroom_booking/providers/boardroom_provider.dart';
import 'package:boardroom_booking/providers/booking_provider.dart';
import 'package:boardroom_booking/services/api_service.dart';
import 'package:boardroom_booking/screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (context) => ApiService(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider<BoardroomProvider>(
          create: (context) => BoardroomProvider(),
        ),
        ChangeNotifierProvider<BookingProvider>(
          create: (context) => BookingProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Boardroom Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF6366F1),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
