import 'package:flutter_test/flutter_test.dart';
import 'package:dhbh_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DHBHApp());
    expect(find.text('Login'), findsOneWidget);
  });
}
