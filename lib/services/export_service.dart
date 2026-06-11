import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';

class ExportService {
  ExportService._();

  static String toCsv(List<Transaction> transactions) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Judul,Kategori,Status,Nominal,Tipe,Tanggal');
    final formatter = NumberFormat('#,##0', 'id_ID');

    for (final tx in transactions) {
      final amount = formatter.format(tx.amount);
      final type = tx.isCredit ? 'Masuk' : 'Keluar';
      buffer.writeln(
        '"${tx.id}","${tx.title}","${tx.category}","${tx.status}","$amount","$type","${tx.subtitle}"',
      );
    }
    return buffer.toString();
  }

  static Future<void> shareCsv(List<Transaction> transactions) async {
    final csv = toCsv(transactions);
    final fileName =
        'mutasi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    await Share.share(csv, subject: fileName);
  }
}
