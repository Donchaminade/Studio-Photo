import 'package:Picon/booking_screen.dart';
import 'package:Picon/confirmation_screen.dart';
import 'package:Picon/contact_screen.dart';
import 'package:Picon/edit_profile_page.dart';
import 'package:Picon/history_screen.dart';
import 'package:Picon/home_screen.dart';
import 'package:Picon/login_screen.dart';
import 'package:Picon/no_connection_screen.dart';
import 'package:Picon/notifications_screen.dart';
import 'package:Picon/order_summary_screen.dart';
import 'package:Picon/payment_selection_screen.dart';
import 'package:Picon/portfolio_screen.dart';
import 'package:Picon/pricing_screen.dart';
import 'package:Picon/profile_page.dart';
import 'package:Picon/recovery_screen.dart';
import 'package:Picon/signup_screen.dart';
import 'package:Picon/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final order = {
    'assets/images/pro.png': {'size': '10x15 cm', 'quantity': 2},
  };

  final screens = <String, Widget>{
    'login': const LoginScreen(),
    'signup': const SignupScreen(),
    'recovery': const RecoveryScreen(),
    'notifications': const NotificationsScreen(),
    'history': const HistoryScreen(),
    'contact': const ContactScreen(),
    'offline': const NoConnectionScreen(),
    'booking': const BookingScreen(),
    'portfolio': const PortfolioScreen(),
    'pricing': const PricingScreen(),
    'payment': const PaymentSelectionScreen(
      orderDetails: {},
      totalAmount: 300,
      isExpress: false,
    ),
    'summary': OrderSummaryScreen(orderDetails: order, isExpress: false),
    'confirmation': ConfirmationScreen(
      orderDetails: order,
      paymentMethod: 'Flooz',
      totalAmount: 300,
      orderId: 1,
    ),
    'edit': const EditProfilePage(
      currentName: 'Tega',
      currentEmail: 'tega@studio.tg',
      currentPhone: '90123456',
    ),
    'home': const HomeScreen(userName: 'Tega', userId: 1),
    'profile': ProfilePage(
      userName: 'Tega',
      userEmail: 'tega@studio.tg',
      avatar: null,
      onAvatarChanged: (_) {},
      onProfileUpdated: (_, __) {},
    ),
  };

  for (final size in const [Size(320, 640), Size(390, 844)]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(theme: buildPiconTheme(), home: entry.value),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
      });
    }
  }
}
