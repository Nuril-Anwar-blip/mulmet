class QrisData {
  final String merchantName;
  final String merchantCity;
  final double? amount;
  final String rawPayload;

  QrisData({
    required this.merchantName,
    this.merchantCity = '',
    this.amount,
    required this.rawPayload,
  });
}

class QrisParser {
  QrisParser._();

  static Map<String, String> _parseTlv(String data) {
    final result = <String, String>{};
    var index = 0;

    while (index + 4 <= data.length) {
      final tag = data.substring(index, index + 2);
      index += 2;
      final length = int.tryParse(data.substring(index, index + 2));
      index += 2;
      if (length == null || length <= 0 || index + length > data.length) break;
      final value = data.substring(index, index + length);
      index += length;
      result[tag] = value;
    }

    return result;
  }

  static QrisData? parse(String raw) {
    final payload = raw.trim();
    if (payload.isEmpty) return null;

    final tlv = _parseTlv(payload);
    if (tlv.containsKey('59') || tlv.containsKey('00')) {
      final merchantName = tlv['59'] ?? 'Merchant QRIS';
      final merchantCity = tlv['60'] ?? '';
      double? amount;
      final amountRaw = tlv['54'];
      if (amountRaw != null && amountRaw.isNotEmpty) {
        amount = double.tryParse(amountRaw);
      }

      return QrisData(
        merchantName: merchantName,
        merchantCity: merchantCity,
        amount: amount,
        rawPayload: payload,
      );
    }

    if (payload.contains('|')) {
      final parts = payload.split('|').map((part) => part.trim()).toList();
      if (parts.length >= 2) {
        return QrisData(
          merchantName: parts[1],
          merchantCity: parts.length > 2 ? parts[2] : '',
          amount: parts.length > 3 ? double.tryParse(parts[3]) : null,
          rawPayload: payload,
        );
      }
    }

    if (payload.length >= 3 && payload.length <= 120) {
      return QrisData(
        merchantName: payload,
        rawPayload: payload,
      );
    }

    return null;
  }
}
