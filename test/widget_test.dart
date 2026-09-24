import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitstack/main.dart';

void main() {
  testWidgets('App renders login screen by default', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitStackApp()));
    expect(find.text('FitStack'), findsWidgets);
    expect(find.text('Log In'), findsOneWidget);
  });
}
