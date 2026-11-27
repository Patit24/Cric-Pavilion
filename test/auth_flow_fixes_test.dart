import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';
import 'package:cricket_app/widgets/auth_modal_dialog.dart';

void main() {
  group('Auth Modal & Model Fixes Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase(loadDemoSeed: false);
      db.purgeAllDemoData();
    });

    Widget createWidgetUnderTest() {
      return ChangeNotifierProvider<MockDatabase>.value(
        value: db,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuthModalDialog(),
            ),
          ),
        ),
      );
    }

    testWidgets('1. First-time Mobile Number login requires OTP AND then requires Gmail + Name', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Switch to Mobile Number (OTP) login mode
      await tester.ensureVisible(find.text('Mobile Number (OTP)'));
      await tester.tap(find.text('Mobile Number (OTP)'));
      await tester.pumpAndSettle();

      // Enter 10-digit mobile number
      await tester.enterText(find.widgetWithText(TextField, '10-digit Mobile Number'), '9876543210');
      await tester.pumpAndSettle();

      // Tap Send Login OTP
      await tester.ensureVisible(find.text('Send Login OTP'));
      await tester.tap(find.text('Send Login OTP'));
      await tester.pumpAndSettle();

      // Fill test OTP & Verify
      expect(find.text('Verify OTP & Sign In'), findsOneWidget);
      await tester.tap(find.text('Testing offline? Fill test OTP'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Verify OTP & Sign In'));
      await tester.tap(find.text('Verify OTP & Sign In'));
      await tester.pumpAndSettle();

      // Since first-time mobile user has no Gmail yet, FIRST-TIME SETUP • LINK GMAIL is shown!
      expect(find.text('FIRST-TIME SETUP • LINK GMAIL'), findsOneWidget);

      // Enter Full Name and Gmail
      await tester.enterText(find.widgetWithText(TextField, 'Full Name *'), 'Rohan Das');
      await tester.enterText(find.widgetWithText(TextField, 'Gmail Address (e.g. name@gmail.com) *'), 'rohan.das@gmail.com');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Complete Setup & Sign In'));
      await tester.tap(find.text('Complete Setup & Sign In'));
      await tester.pumpAndSettle();

      // Verify both Gmail and verified mobile are saved in database!
      expect(db.isAuthenticated, isTrue);
      expect(db.currentUser?.fullName, equals('Rohan Das'));
      expect(db.currentUser?.email, equals('rohan.das@gmail.com'));
      expect(db.currentUser?.mobileNumber, equals('9876543210'));
      expect(db.currentUser?.isMobileVerified, isTrue);
      expect(db.currentUser?.isProfileComplete, isTrue);
    });

    testWidgets('2. Returning Mobile Number login still requires OTP, then signs in WITHOUT asking Gmail again', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Pre-register returning user with both Gmail and verified mobile
      db.loginWithVerifiedMobile(
        mobileNumber: '9123456789',
        email: 'returning.mobile@gmail.com',
        fullName: 'Returning Mobile User',
      );
      db.logoutUser();
      expect(db.isAuthenticated, isFalse);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Mobile Number (OTP)'));
      await tester.tap(find.text('Mobile Number (OTP)'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '10-digit Mobile Number'), '9123456789');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Send Login OTP'));
      await tester.tap(find.text('Send Login OTP'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Testing offline? Fill test OTP'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Verify OTP & Sign In'));
      await tester.tap(find.text('Verify OTP & Sign In'));
      await tester.pumpAndSettle();

      // Should NOT ask for Gmail again, and user is authenticated!
      expect(find.text('FIRST-TIME SETUP • LINK GMAIL'), findsNothing);
      expect(db.isAuthenticated, isTrue);
      expect(db.currentUser?.email, equals('returning.mobile@gmail.com'));
      expect(db.currentUser?.mobileNumber, equals('9123456789'));
    });

    testWidgets('3. Closing AuthModalDialog before finishing first-time setup logs out incomplete session', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Start first-time Mobile OTP sign in (transitions to Name & Email step)
      await tester.ensureVisible(find.text('Mobile Number (OTP)'));
      await tester.tap(find.text('Mobile Number (OTP)'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '10-digit Mobile Number'), '9988776655');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Send Login OTP'));
      await tester.tap(find.text('Send Login OTP'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Testing offline? Fill test OTP'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Verify OTP & Sign In'));
      await tester.tap(find.text('Verify OTP & Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('FIRST-TIME SETUP • LINK GMAIL'), findsOneWidget);
      expect(db.currentUser?.isProfileComplete, isFalse);

      // User closes the modal without completing Name & Email setup
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Incomplete session MUST be cleared so they cannot bypass setup!
      expect(db.isAuthenticated, isFalse);
      expect(db.currentUser, isNull);
    });

    test('4. verifyUserMobileOtp rejects wrong OTP and validates generated OTP', () {
      db.registerUser(
        fullName: 'Test Player',
        email: 'test.otp@gmail.com',
        mobileNumber: '9988776655',
        password: 'password123',
      );
      final otp = db.sendMobileOtp('9988776655');

      // Wrong OTP fails
      expect(db.verifyUserMobileOtp(mobileNumber: '9988776655', otp: '000000'), isFalse);
      expect(db.currentUser?.isMobileVerified, isFalse);

      // Correct OTP succeeds
      expect(db.verifyUserMobileOtp(mobileNumber: '9988776655', otp: otp), isTrue);
      expect(db.currentUser?.isMobileVerified, isTrue);
      expect(db.currentUser?.isProfileComplete, isTrue);
    });

    testWidgets('5. Cross-device returning mobile user (verified Player in Firestore) skips Name & Email after OTP', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Simulate a player already registered & verified on another device (synced via Firestore players)
      final p = db.registerPermanentPlayer(
        fullName: 'Cross Device Player',
        mobileNumber: '9876501122',
        role: PlayerRole.allRounder,
      );
      p.isMobileVerified = true;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Mobile Number (OTP)'));
      await tester.tap(find.text('Mobile Number (OTP)'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '10-digit Mobile Number'), '9876501122');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Send Login OTP'));
      await tester.tap(find.text('Send Login OTP'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Testing offline? Fill test OTP'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Verify OTP & Sign In'));
      await tester.tap(find.text('Verify OTP & Sign In'));
      await tester.pumpAndSettle();

      // Should NOT ask for Name & Email again, and should restore fullName from Player!
      expect(find.text('FIRST-TIME SETUP • LINK GMAIL'), findsNothing);
      expect(db.isAuthenticated, isTrue);
      expect(db.currentUser?.fullName, equals('Cross Device Player'));
    });
  });
}
