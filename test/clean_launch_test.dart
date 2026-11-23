import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cricket_app/main.dart';
import 'package:cricket_app/screens/home_screen.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  testWidgets('CricPavilionApp launches into clean slate without error', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = MockDatabase(loadDemoSeed: false);
    db.purgeAllDemoData();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MockDatabase>.value(value: db),
        ],
        child: const CricPavilionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(MainNavigationShell), findsOneWidget);
  });
}
