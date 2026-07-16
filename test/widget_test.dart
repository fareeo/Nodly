import 'package:flutter_test/flutter_test.dart';
import 'package:nodly/main.dart';
import 'package:nodly/services/settings_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final settings = SettingsService();
    await tester.pumpWidget(NodlyApp(settings: settings));
    expect(find.text('Nodly'), findsWidgets);
  });
}
