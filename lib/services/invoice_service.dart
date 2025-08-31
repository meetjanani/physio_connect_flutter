import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:physio_connect/model/bookings_model.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:printing/printing.dart';

class InvoiceService {
  /// Generate a PDF invoice for the given appointment
  static Future<File> generateInvoice(BookingsModel appointment) async {
    // Create a PDF document
    final pdf = pw.Document();

    // Load logo image - replace with your actual logo path
    final ByteData logoBytes = await rootBundle.load('assets/app_icon.png');
    final Uint8List logoData = logoBytes.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(logoData);

    // Load signature image - replace with your actual signature image path
    // final ByteData signatureBytes = await rootBundle.load('assets/images/signature.png');
    // final Uint8List signatureData = signatureBytes.buffer.asUint8List();
    // final pw.MemoryImage signatureImage = pw.MemoryImage(signatureData);

    // Load stamp image - replace with your actual stamp image path
    // final ByteData stampBytes = await rootBundle.load('assets/images/stamp.png');
    // final Uint8List stampData = stampBytes.buffer.asUint8List();
    // final pw.MemoryImage stampImage = pw.MemoryImage(stampData);

    // PdfColors from AppColors
    final PdfColor medicalBlue = PdfColor.fromHex(AppColors.medicalBlue.value.toRadixString(16).substring(2));
    final PdfColor medicalBlueLight = PdfColor.fromHex(AppColors.medicalBlueLight.value.toRadixString(16).substring(2));
    final PdfColor medicalBlueDark = PdfColor.fromHex(AppColors.medicalBlueDark.value.toRadixString(16).substring(2));
    final PdfColor wellnessGreen = PdfColor.fromHex(AppColors.wellnessGreen.value.toRadixString(16).substring(2));

    // Format dates
    final dateFormatter = DateFormat('dd MMMM yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    final invoiceDate = dateFormatter.format(DateTime.now());
    final appointmentDate = dateFormatter.format(DateFormat('yyyy-MM-dd').parse(appointment.bookingDate));

    // Get doctor and patient
    final doctor = appointment.aDoctor();
    final patient = appointment.aPatient(); // In this case, you'll need to get the patient details

    // Invoice number (you might want to generate this differently)
    final invoiceNumber = 'INV-${appointment.id}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    // Add page to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
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
                          'INVOICE',
                          style: pw.TextStyle(
                            color: medicalBlueDark,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoiceNumber,
                          style: pw.TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Date: $invoiceDate',
                          style: pw.TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
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
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.Text(
                    'Physio Connect - Care You Can Trust',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: medicalBlue,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Billing information
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // From (Clinic/Hospital)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FROM',
                        style: pw.TextStyle(
                          color: medicalBlue,
                          fontSize: 14,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Physio Connect Clinic',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('123 Healthcare Avenue'),
                      pw.Text('Mumbai, Maharashtra 400001'),
                      pw.Text('India'),
                      pw.SizedBox(height: 4),
                      pw.Text('Phone: +91 98765 43210'),
                      pw.Text('Email: info@physioconnect.app'),
                    ],
                  ),
                ),
                // To (Patient)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO',
                        style: pw.TextStyle(
                          color: medicalBlue,
                          fontSize: 14,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        patient.name,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      // TODO: atient.address
                      pw.Text('Address not available'),
                      if (patient.mobileNumber?.isNotEmpty == true)
                        pw.Text('Phone: ${patient.mobileNumber}'),
                     /* if (patient.email?.isNotEmpty == true)
                        pw.Text('Email: ${patient.email}'),*/
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Service details
            pw.Container(
              decoration: pw.BoxDecoration(
                color: medicalBlueLight,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: pw.EdgeInsets.all(16),
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
                  _buildInfoRow('Session Type', appointment.aSessionType().name),
                  _buildInfoRow('Doctor', doctor?.name ?? 'N/A'),
                  _buildInfoRow('Date', appointmentDate),
                  _buildInfoRow('Time', appointment.aTimeslot().time),
                  _buildInfoRow('Duration', appointment.aSessionType().duration),
                  if (doctor.degree?.isNotEmpty == true)
                    _buildInfoRow('Specialist', doctor.degree ?? ''),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Service breakdown
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 1,
              ),
              children: [
                // Table header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: medicalBlue,
                  ),
                  children: [
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell('Quantity', isHeader: true, alignment: pw.Alignment.center),
                    _buildTableCell('Unit Price', isHeader: true, alignment: pw.Alignment.center),
                    _buildTableCell('Total', isHeader: true, alignment: pw.Alignment.center),
                  ],
                ),
                // Service item
                pw.TableRow(
                  children: [
                    _buildTableCell(appointment.aSessionType().name),
                    _buildTableCell('1', alignment: pw.Alignment.center),
                    _buildTableCell('₹${appointment.price.toStringAsFixed(0)}', alignment: pw.Alignment.center),
                    _buildTableCell('₹${appointment.price.toStringAsFixed(0)}', alignment: pw.Alignment.center),
                  ],
                ),
                // Add more rows if there are additional charges
              ],
            ),

            pw.SizedBox(height: 12),

            // Totals
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildTotalRow('Subtotal', '₹${appointment.price.toStringAsFixed(0)}'),
                  _buildTotalRow('Tax (0%)', '₹0.00'),
                  _buildTotalRow('Total', '₹${appointment.price.toStringAsFixed(0)}', isBold: true),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Payment information
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: wellnessGreen,
                  width: 1,
                ),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: pw.EdgeInsets.all(12),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 30,
                    height: 30,
                    decoration: pw.BoxDecoration(
                      color: wellnessGreen,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '✓',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PAYMENT RECEIVED',
                          style: pw.TextStyle(
                            color: wellnessGreen,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Payment Reference: ${appointment.paymentId ?? "N/A"}',
                          style: pw.TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Payment Status: ${appointment.paymentStatus}',
                          style: pw.TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Doctor's notes if available
            if (appointment.doctorNotes?.isNotEmpty == true) ...[
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey300,
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DOCTOR\'S NOTES',
                      style: pw.TextStyle(
                        color: medicalBlueDark,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      _stripHtmlTags(appointment.doctorNotes ?? ''),
                      style: pw.TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
            ],

            // Signature and stamp
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Thank you for choosing Physio Connect',
                      style: pw.TextStyle(
                        color: medicalBlueDark,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'This is a computer-generated invoice and requires no signature.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      doctor.name ?? '',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      doctor.degree ?? '',
                      style: pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.Container(
                      height: 60,
                      width: 120,
                      child: buildAuthorizedSignature(), // signatureImage
                    ),
                  ],
                ),
              ],
            ),

            pw.Positioned(
              bottom: 40,
              right: 20,
              child: pw.Opacity(
                opacity: 0.3,
                child: pw.Container(
                  height: 100,
                  width: 100,
                  child: buildDoctorStamp(),// stampImage
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${appointment.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Helper method to build a key-value row for appointment details
  static pw.Widget _buildInfoRow(String key, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              key,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build a table cell
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
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

  /// Helper method to build a total row
  static pw.Widget _buildTotalRow(String label, String amount, {bool isBold = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
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

  /// Open the PDF for viewing, printing, or sharing
  static Future<void> openPdf(File file) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => file.readAsBytes(),
    );
  }

  /// Helper method to strip HTML tags from text
  static String _stripHtmlTags(String htmlString) {
    // A very basic HTML tag stripper
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static pw.Widget buildDoctorStamp() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Dr. Parul Desai',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.Text(
            'Reg. No. 123456',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Degree: Physiotherapist',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildAuthorizedSignature() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // You can replace this with a signature image from a byte array
        // like this: pw.Image(pw.MemoryImage(signatureImageBytes)),
        /*pw.Text(
          'Signature',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 5),*/
        pw.Container(
          width: 150,
          height: 1,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Authorized Signatory',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}

