import 'package:qr/qr.dart';

/// Utility class for generating QR codes
class QrCodeGenerator {
  /// Generate QR code data matrix
  static QrCode generateQrCode(
    String data, {
    int errorCorrectLevel = QrErrorCorrectLevel.L,
  }) {
    final qrCode = QrCode(errorCorrectLevel, 4); // Version 4
    qrCode.addData(data);
    // QrCode is automatically encoded when addData is called
    return qrCode;
  }

  /// Generate QR code data string for student ID card
  static String generateStudentIdQrData({
    required String admissionNo,
    required String studentName,
    String? studentId,
  }) {
    // Create JSON-like structure for QR code
    final data = {
      'type': 'student_id',
      'admission_no': admissionNo,
      'name': studentName,
      if (studentId != null) 'id': studentId,
    };

    // Convert to string format (could be JSON or custom format)
    return data.entries.map((e) => '${e.key}:${e.value}').join('|');
  }
}
