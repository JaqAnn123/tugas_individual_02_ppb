import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nottia/core/theme/app_theme.dart';
import 'package:nottia/features/auth/login_page.dart';
import 'package:nottia/features/splash/splash_page.dart';

void main() {
  testWidgets('splash screen renders on a 393 x 852 canvas', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(onFinished: () => finished = true),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('nottia'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(6));
    expect(
      tester.widget<Text>(find.text('nottia')).style?.fontSize,
      44,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 700));
    expect(finished, isTrue);

    // Dispose the splash so its tickers and timer are released.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('login shows the form and rejects wrong credentials', (
    WidgetTester tester,
  ) async {
    await _pumpLogin(tester);

    expect(find.text('login to continue'), findsOneWidget);
    expect(find.text('email'), findsOneWidget);
    expect(find.text('password'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    expect(find.text('login with google'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'nope');
    await tester.tap(find.text('login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('email atau password salah'), findsOneWidget);
    expect(_loggedInEmail, isNull);
  });

  testWidgets('login accepts the demo credentials', (
    WidgetTester tester,
  ) async {
    await _pumpLogin(tester);

    await tester.enterText(
      find.byType(TextField).at(0),
      'anngelicaaa00@gmail.com',
    );
    await tester.enterText(find.byType(TextField).at(1), '12345678');
    await tester.tap(find.text('login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(_loggedInEmail, 'anngelicaaa00@gmail.com');
  });
}

String? _loggedInEmail;

Future<void> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  _loggedInEmail = null;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: LoginScreen(onLoggedIn: (String email) => _loggedInEmail = email),
    ),
  );
}
