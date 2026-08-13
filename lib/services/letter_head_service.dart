import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:printing/printing.dart';

import '../utils/units_extensions.dart';

class LetterHeadData {
  final String patientName;
  final String patientAddress;
  final String sessionType;
  final String sessionDescription;
  final int sessionQty;
  final double sessionAmount;
  final String doctorName;
  final String specialist;
  final String doctorCredentials;
  final DateTime createdAt;

  const LetterHeadData({
    required this.patientName,
    required this.patientAddress,
    required this.sessionType,
    required this.sessionDescription,
    required this.sessionQty,
    required this.sessionAmount,
    required this.doctorName,
    required this.specialist,
    required this.doctorCredentials,
    required this.createdAt,
  });

  double get totalAmount => sessionQty * sessionAmount;
}

class LetterHeadService {
  static Future<File> generateLetterHead() async {
    final pdf = pw.Document();

    final ByteData logoBytes = await rootBundle.load('assets/app_icon.png');
    final Uint8List logoData = logoBytes.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(logoData);

    final PdfColor medicalBlue = PdfColor.fromHex(
      AppColors.medicalBlue.toARGB32().toRadixString(16).padLeft(8, '0').substring(2),
    );
    final PdfColor medicalBlueLight = PdfColor.fromHex(
      AppColors.medicalBlueLight.toARGB32().toRadixString(16).padLeft(8, '0').substring(2),
    );
    final PdfColor medicalBlueDark = PdfColor.fromHex(
      AppColors.medicalBlueDark.toARGB32().toRadixString(16).padLeft(8, '0').substring(2),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logoImage, height: 60, width: 60, fit: pw.BoxFit.cover),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Physio Connect',
                          style: pw.TextStyle(
                            color: medicalBlueDark,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Physiotherapy | Fitness | Rehab',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Dr. Parul Desai | GPC-2345',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Divider(color: medicalBlue),
              ],
            );
          }
          return pw.Container();
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: medicalBlue),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'physioconnect.app@gmail.com',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'Physio Connect - Care You Can Trust',
                    style: pw.TextStyle(fontSize: 12, color: medicalBlue),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [pw.Expanded(child:
          // pw.Center(child: pw.Opacity(opacity: 0.1, child: pw.Image(logoImage, height: 200),),),)
          pw.Center(child: pw.Opacity(opacity: 0.1, child: pw.Text(
            'Physio Connect',
            style: pw.TextStyle(
              color: medicalBlueDark,
              fontWeight: pw.FontWeight.bold,
              fontSize: 36,
            ),
          ),),),)
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/prescription_${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static Future<void> openPdf(File file) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => file.readAsBytes(),
    );
  }

  static String _inr(double amount) {
    if (amount == amount.roundToDouble()) {
      return 'INR ${amount.toStringAsFixed(0)}';
    }
    return 'INR ${amount.toStringAsFixed(2)}';
  }
}
