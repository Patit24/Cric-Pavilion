import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket_app/services/mock_database.dart';
import 'package:cricket_app/services/database_persistence_service.dart';

void main() {
  test('Login via Mobile OTP + Complete Gmail persists across simulated app restart', () async {
    SharedPreferences.setMockInitialValues({});

    // 1. First boot
    final db1 = MockDatabase(loadDemoSeed: false);
    await db1.initPersistence();
    db1.purgeAllDemoData();
    expect(db1.isAuthenticated, isFalse);

    // 2. Mobile OTP login + Complete Gmail & Name
    db1.loginWithVerifiedMobile(mobileNumber: '9876543210');
    db1.completeFirstTimeEmailAndName(email: 'testuser@gmail.com', fullName: 'Test User');
    await DatabasePersistenceService.saveDatabase(db1);

    expect(db1.isAuthenticated, isTrue);
    expect(db1.currentUser?.fullName, 'Test User');

    // 3. Simulated page reload (new MockDatabase instance)
    final db2 = MockDatabase(loadDemoSeed: false);
    await db2.initPersistence();
    db2.purgeAllDemoData();

    expect(db2.isAuthenticated, isTrue);
    expect(db2.currentUser?.email, 'testuser@gmail.com');
    expect(db2.currentUser?.fullName, 'Test User');
  });
}
