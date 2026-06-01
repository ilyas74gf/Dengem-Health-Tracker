import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Uygulama baslangic testi', (WidgetTester tester) async {
    // Eski MyApp yerine yeni sınıf ismimiz olan RutinUygulamam'ı çağırıyoruz
    await tester.pumpWidget(const RutinUygulamam(kayitliMi: false));
    
    // Uygulamanın başarıyla ayağa kalktığını doğrulamak için basit bir kontrol
    expect(find.byType(RutinUygulamam), findsOneWidget);
  });
}