
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_motos/main.dart';

void main() {
  testWidgets('Moto Ride inicia corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MotoRideApp());

    expect(find.byType(MotoRideApp), findsOneWidget);
  });
}
