import 'package:flutter_test/flutter_test.dart';

import 'package:tugas_akhir_bank/main.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BankMandiriApp(hasSession: false));

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('Bank Mandiri'), findsOneWidget);
    expect(find.text('Buka Rekening Baru'), findsOneWidget);
  });
}
