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

class PrescriptionData {
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

  const PrescriptionData({
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

class PrescriptionService {
  static Future<File> generatePrescription(PrescriptionData data) async {
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

    final String prescriptionDate = DateFormat('yyyy-MM-dd').format(data.createdAt);
    final String prescriptionNumber =
        'Prescription No: ${DateFormat('yyyyMMddHHmmss').format(data.createdAt)}';

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
                    pw.Image(logoImage, height: 60),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'PRESCRIPTION',
                          style: pw.TextStyle(
                            color: medicalBlueDark,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          prescriptionNumber,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Date: ${formatDateToReadable(prescriptionDate)}',
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
                    'Page ${context.pageNumber} of ${context.pagesCount}',
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
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FROM',
                        style: pw.TextStyle(color: medicalBlue, fontSize: 14),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Physio Connect',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Email: physioconnect.app@gmail.com'),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PRESCRIPTION TO',
                        style: pw.TextStyle(color: medicalBlue, fontSize: 14),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        data.patientName,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(data.patientAddress),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              decoration: pw.BoxDecoration(
                color: medicalBlueLight,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'APPOINTMENT DETAILS',
                    style: pw.TextStyle(
                      color: medicalBlueDark,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Session Type', data.sessionType),
                  _buildInfoRow('Session Qty', data.sessionQty.toString()),
                  _buildInfoRow('Session Amount', _inr(data.sessionAmount)),
                  _buildInfoRow('Doctor Name', data.doctorName),
                  _buildInfoRow('Specialist', data.specialist),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: medicalBlue),
                  children: [
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell(
                      'Quantity',
                      isHeader: true,
                      alignment: pw.Alignment.center,
                    ),
                    _buildTableCell(
                      'Total',
                      isHeader: true,
                      alignment: pw.Alignment.center,
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell(data.sessionDescription + " (" + data.sessionType + ")"),
                    _buildTableCell(
                      data.sessionQty.toString(),
                      alignment: pw.Alignment.center,
                    ),
                    _buildTableCell(
                      _inr(data.totalAmount),
                      alignment: pw.Alignment.center,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildTotalRow('Subtotal', _inr(data.totalAmount)),
                  _buildTotalRow('Total', _inr(data.totalAmount), isBold: true),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Thank you for choosing Physio Connect',
                        style: pw.TextStyle(color: medicalBlueDark, fontSize: 12),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'This is a computer-generated prescription and requires no signature.',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      data.doctorName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      data.doctorCredentials,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      width: 120,
                      height: 1,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Authorized Signatory'),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/prescription_${DateFormat('yyyyMMddHHmmss').format(data.createdAt)}.pdf',
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

  static pw.Widget _buildInfoRow(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              key,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: isHeader ? PdfColors.white : PdfColors.black,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 300),
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              amount,
              style: pw.TextStyle(
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
