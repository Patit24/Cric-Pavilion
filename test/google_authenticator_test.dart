import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cricket_app/services/mock_database.dart';
import 'package:cricket_app/services/totp_service.dart';
import 'package:cricket_app/widgets/auth_modal_dialog.dart';

void main() {
  group('Google Authenticator 2FA MockDatabase Unit Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase(loadDemoSeed: true);
    });

    test('Seeded user_gauth_01 has 2FA enabled with secret', () {
      final user = db.findUser('gauth@cricpavilion.com');
      expect(user, isNotNull);
      expect(user!.isGoogleAuthEnabled, isTrue);
      expect(user.googleAuthSecret, equals('JBSWY3DPEHPK3PXP'));
      expect(user.googleAuthRecoveryCodes.length, equals(3));
      expect(db.is2faRequired('gauth@cricpavilion.com'), isTrue);
    });

    test('Normal login without bypass fails for 2FA-protected user', () {
      final success = db.loginUser(
        emailOrMobile: 'gauth@cricpavilion.com',
        password: 'gauth123',
      );
      expect(success, isFalse);
      expect(db.currentUser, isNull);
    });

    test('Valid Google Authenticator TOTP code logs the user in successfully', () {
      final user = db.findUser('gauth@cricpavilion.com')!;
      final currentCode = TotpService.generateTotpCode(secret: user.googleAuthSecret!);

      final success = db.verifyAndLoginWithGoogleAuth(
        emailOrMobile: 'gauth@cricpavilion.com',
        code: currentCode,
      );

      expect(success, isTrue);
      expect(db.currentUser?.email, equals('gauth@cricpavilion.com'));
      expect(db.isAuthenticated, isTrue);
    });

    test('Invalid Google Authenticator code is rejected', () {
      final success = db.verifyAndLoginWithGoogleAuth(
        emailOrMobile: 'gauth@cricpavilion.com',
        code: '999999',
      );

      expect(success, isFalse);
      expect(db.currentUser, isNull);
    });

    test('Valid backup recovery code logs in and consumes the code', () {
      final user = db.findUser('gauth@cricpavilion.com')!;
      final recoveryCode = user.googleAuthRecoveryCodes.first;
      final initialCount = user.googleAuthRecoveryCodes.length;

      final success = db.verifyAndLoginWithGoogleAuth(
        emailOrMobile: 'gauth@cricpavilion.com',
        code: recoveryCode,
      );

      expect(success, isTrue);
      expect(db.currentUser?.email, equals('gauth@cricpavilion.com'));
      expect(user.googleAuthRecoveryCodes.length, equals(initialCount - 1));
      expect(user.googleAuthRecoveryCodes.contains(recoveryCode), isFalse);
    });

    test('enableGoogleAuthenticator verifies code and enables 2FA for regular user', () {
      final admin = db.findUser('admin@cricpavilion.com')!;
      expect(admin.isGoogleAuthEnabled, isFalse);

      final secret = db.generateGoogleAuthSecret();
      final validCode = TotpService.generateTotpCode(secret: secret);

      // Attempt with invalid code fails
      final failAttempt = db.enableGoogleAuthenticator(
        userId: admin.id,
        secret: secret,
        verificationCode: '000000',
      );
      expect(failAttempt, isFalse);
      expect(admin.isGoogleAuthEnabled, isFalse);

      // Attempt with valid code succeeds
      final success = db.enableGoogleAuthenticator(
        userId: admin.id,
        secret: secret,
        verificationCode: validCode,
      );
      expect(success, isTrue);
      expect(admin.isGoogleAuthEnabled, isTrue);
      expect(admin.googleAuthSecret, equals(secret));
      expect(admin.googleAuthRecoveryCodes.length, equals(6));
    });

    test('disableGoogleAuthenticator turns off 2FA and clears secrets', () {
      final user = db.findUser('gauth@cricpavilion.com')!;
      expect(user.isGoogleAuthEnabled, isTrue);

      db.disableGoogleAuthenticator(user.id);
      expect(user.isGoogleAuthEnabled, isFalse);
      expect(user.googleAuthSecret, isNull);
      expect(user.googleAuthRecoveryCodes, isEmpty);
      expect(db.is2faRequired(user.email), isFalse);
    });

    test('signInWithGoogle signs in instantly with Google OAuth profile', () {
      final user = db.signInWithGoogle(
        email: 'virat.fan@gmail.com',
        displayName: 'Virat Fan',
      );

      expect(user.email, equals('virat.fan@gmail.com'));
      expect(user.isGoogleOAuthUser, isTrue);
      expect(db.currentUser?.email, equals('virat.fan@gmail.com'));
    });
  });

  group('AuthModalDialog Widget Tests with Google Authenticator', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase(loadDemoSeed: true);
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: ChangeNotifierProvider<MockDatabase>.value(
          value: db,
          child: const Scaffold(
            body: Center(
              child: AuthModalDialog(),
            ),
          ),
        ),
      );
    }

    testWidgets('Displays Google Sign-In first and Google 2FA quick demo account', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Google Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('RECOMMENDED'), findsOneWidget);
    });

    testWidgets('Google Sign-In completes authentication immediately without forcing Mobile OTP', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(db.isAuthenticated, isFalse);

      // Sign in with Google -> completes immediately without asking for phone number OTP
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(db.isAuthenticated, isTrue);
      expect(db.currentUser?.email, equals('patitroy29@gmail.com'));
      expect(db.currentUser?.isGoogleOAuthUser, isTrue);
      expect(find.text('FIRST-TIME SETUP • LINK MOBILE'), findsNothing);
    });

    testWidgets('Returning Google user signs in immediately WITHOUT OTP', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Pre-save user with verified mobile in database
      final returningUser = db.signInWithGoogle(
        email: 'returning.player@gmail.com',
        displayName: 'Returning Player',
      );
      returningUser.mobileNumber = '9876500002';
      returningUser.isMobileVerified = true;
      db.logoutUser();
      expect(db.isAuthenticated, isFalse);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap to sign in with this returning Google account
      // Enter the email in the login box or call Google sign in
      final state = tester.state(find.byType(AuthModalDialog)) as dynamic;
      state.widget; // access state
      // Trigger sign in for returning user
      await tester.enterText(find.byType(TextField).first, 'returning.player@gmail.com');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Confirmed: User is signed in directly, NO OTP PROMPT!
      expect(db.isAuthenticated, isTrue);
      expect(db.currentUser?.email, equals('returning.player@gmail.com'));
      expect(find.text('FIRST-TIME SETUP • LINK MOBILE'), findsNothing);
    });

    testWidgets('Entering credentials for 2FA user transitions to Google Authenticator screen', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter credentials for 2FA user
      await tester.enterText(find.byType(TextField).at(0), 'gauth@cricpavilion.com');
      await tester.enterText(find.byType(TextField).at(1), 'gauth123');
      await tester.pumpAndSettle();

      // Tap Sign In button (NeoGlassButton)
      await tester.ensureVisible(find.text('Sign In').last);
      await tester.tap(find.text('Sign In').last);
      await tester.pumpAndSettle();

      // Verify that 2FA step view is displayed
      expect(find.text('GOOGLE AUTHENTICATOR (2FA)'), findsOneWidget);
      expect(find.text('Account: gauth@cricpavilion.com'), findsOneWidget);
      expect(find.text('Verify & Sign In'), findsOneWidget);
    });

    testWidgets('Verifying valid TOTP code completes authentication', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter credentials for 2FA user
      await tester.enterText(find.byType(TextField).at(0), 'gauth@cricpavilion.com');
      await tester.enterText(find.byType(TextField).at(1), 'gauth123');
      await tester.pumpAndSettle();

      // Tap Sign In
      await tester.ensureVisible(find.text('Sign In').last);
      await tester.tap(find.text('Sign In').last);
      await tester.pumpAndSettle();

      // Generate current valid code for 'JBSWY3DPEHPK3PXP'
      final validCode = TotpService.generateTotpCode(secret: 'JBSWY3DPEHPK3PXP');

      // Enter the code into the field
      await tester.enterText(find.byType(TextField).last, validCode);
      await tester.pumpAndSettle();

      // Tap Verify & Sign In
      await tester.ensureVisible(find.text('Verify & Sign In'));
      await tester.tap(find.text('Verify & Sign In'));
      await tester.pumpAndSettle();

      // Confirmed user is logged in
      expect(db.currentUser?.email, equals('gauth@cricpavilion.com'));
    });
  });
}
