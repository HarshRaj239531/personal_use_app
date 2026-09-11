import 'package:flutter_test/flutter_test.dart';
import 'package:personal_use_app/main.dart';
import 'package:provider/provider.dart';
import 'package:personal_use_app/controllers/life_os_provider.dart';

void main() {
  testWidgets('LifeOS App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LifeOsProvider(),
        child: const LifeOsApp(),
      ),
    );

    expect(find.byType(LifeOsApp), findsOneWidget);
  });
}
