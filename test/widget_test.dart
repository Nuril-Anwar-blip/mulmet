import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tugas_akhir_bank/main.dart';

void main() {
  testWidgets('shows login screen and opens register page', (WidgetTester tester) async {
    await tester.pumpWidget(const BankMandiriApp());

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('Bank Mandiri'), findsOneWidget);

    await tester.tap(find.text('Buka Rekening Baru'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Akun Baru'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
