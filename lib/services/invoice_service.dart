import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:physio_connect/model/bookings_model.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:printing/printing.dart';

import '../utils/units_extensions.dart';

class InvoiceService {
  /// Generate a PDF invoice for one appointment or a bulk appointment group.
  static Future<File> generateInvoice(
    BookingsModel appointment, {
    List<BookingsModel>? appointments,
  }) async {
    final invoiceAppointments = appointments?.isNotEmpty == true
        ? List<BookingsModel>.from(appointments!)
        : <BookingsModel>[appointment];
    invoiceAppointments.sort(
      (a, b) => a.bookingDate.compareTo(b.bookingDate),
    );
    final totalAmount = invoiceAppointments.fold<double>(
      0,
      (total, item) => total + item.price,
    );
    final refundedAppointments = invoiceAppointments
        .where((item) => item.razorpayRefundId?.trim().isNotEmpty == true)
        .toList();
    final refundedAmount = refundedAppointments.fold<double>(
      0,
      (total, item) => total + item.price,
    );
    final paidAmount = totalAmount - refundedAmount;
    final hasPartialRefund = refundedAppointments.isNotEmpty &&
        refundedAppointments.length < invoiceAppointments.length;
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
    final PdfColor medicalBlue = PdfColor.fromHex(
      AppColors.medicalBlue.value.toRadixString(16).substring(2),
    );
    final PdfColor medicalBlueLight = PdfColor.fromHex(
      AppColors.medicalBlueLight.value.toRadixString(16).substring(2),
    );
    final PdfColor medicalBlueDark = PdfColor.fromHex(
      AppColors.medicalBlueDark.value.toRadixString(16).substring(2),
    );
    final PdfColor wellnessGreen = PdfColor.fromHex(
      AppColors.wellnessGreen.value.toRadixString(16).substring(2),
    );
    final PdfColor warning = PdfColor.fromHex(
      AppColors.warning.value.toRadixString(16).substring(2),
    );
    final PdfColor warningDark = PdfColor.fromHex(
      AppColors.warningDark.value.toRadixString(16).substring(2),
    );
    final bool isRefunded = refundedAppointments.length ==
        invoiceAppointments.length;

    // Format dates
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final timeFormatter = DateFormat('hh:mm a');
    final invoiceDate = dateFormatter.format(DateTime.now());
    final appointmentDate =
        "${formatDateToReadable(appointment.bookingDate)}, ${formatDateToWeekday(appointment.bookingDate)}";

    // Get doctor and patient
    final doctor = appointment.aDoctor();
    final timeSlot = appointment.aTimeslot();
    final sessionType = appointment.aSessionType();
    final patient = appointment
        .aPatient(); // In this case, you'll need to get the patient details

    // Invoice number (you might want to generate this differently)
    final invoiceNumber = appointment.isBulkAppointment &&
            appointment.bulkAppointmentId?.isNotEmpty == true
        ? 'Invoice No:${invoiceAppointments.first.id}_${invoiceAppointments.last.id}'
        : 'Invoice No:${appointment.id}';

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
                          isRefunded ? 'REFUNDED INVOICE' : 'INVOICE',
                          style: pw.TextStyle(
                            color: isRefunded ? warningDark : medicalBlueDark,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoiceNumber,
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Date: ${formatDateToReadable(invoiceDate)}',
                          style: pw.TextStyle(fontSize: 14),
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
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
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
                      // TODO: Physio Connect Address
                      /*pw.Text('123 Healthcare Avenue'),
                      pw.Text('Mumbai, Maharashtra 400001'),
                      pw.Text('India'),
                      pw.SizedBox(height: 4),*/
                      // pw.Text('Phone: +91 98765 43210'),
                      pw.Text('Email: physioconnect.app@gmail.com'),
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
                        style: pw.TextStyle(color: medicalBlue, fontSize: 14),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        patient.name ?? "",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(appointment.address ?? 'Address not available'),
                      if (patient.mobileNumber?.isNotEmpty == true)
                        pw.Text('Phone: ${patient.mobileNumber}'),
                      /* if (patient.email?.isNotEmpty == true)
                        pw.Text('Email: ${patient.email}'),*/
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

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
                    _buildInfoRow(
                      'Session Type',
                      appointment.aSessionType().name,
                    ),
                  if (invoiceAppointments.length == 1) ...[
                    _buildInfoRow('Date', appointmentDate),
                  ] else _buildInfoRow(
                      'Date',
                      '${formatDateToReadable(invoiceAppointments.first.bookingDate)} to '
                          '${formatDateToReadable(invoiceAppointments.last.bookingDate)}'
                  ),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildInfoRow(
                          'Time',
                          appointment.aTimeslot().time,
                        ),
                      ),
                      pw.Expanded(
                        child: _buildInfoRow(
                          'Duration',
                          appointment.aSessionType().duration,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildInfoRow('Doctor', doctor?.name ?? 'N/A'),
                      ),
                      if (doctor.degree?.isNotEmpty == true)
                        pw.Expanded(
                          child: _buildInfoRow(
                            'Specialist',
                            doctor.degree ?? '',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Service breakdown
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
              children: [
                // Table header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: medicalBlue),
                  children: [
                    _buildTableCell('Description / Status', isHeader: true),
                    _buildTableCell(
                      'Quantity',
                      isHeader: true,
                      alignment: pw.Alignment.center,
                    ),
                    // _buildTableCell('Unit Price', isHeader: true, alignment: pw.Alignment.center),
                    _buildTableCell(
                      'Total',
                      isHeader: true,
                      alignment: pw.Alignment.center,
                    ),
                  ],
                ),
                ...invoiceAppointments.map(
                  (item) => pw.TableRow(
                    children: [
                      _buildTableCell(
                        '${formatDateToReadable(item.bookingDate)} - '
                        '${item.aSessionType().name}\n'
                        '${item.razorpayRefundId?.trim().isNotEmpty == true ? "REFUNDED" : "PAID"}',
                        textColor: item.razorpayRefundId?.trim().isNotEmpty == true
                            ? warningDark
                            : null,
                      ),
                      _buildTableCell(
                        '1 Session',
                        alignment: pw.Alignment.center,
                      ),
                      _buildTableCell(
                        'INR ${item.price.toStringAsFixed(0)}',
                        alignment: pw.Alignment.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // Totals
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildTotalRow(
                    'Subtotal',
                    'INR ${totalAmount.toStringAsFixed(0)}',
                  ),
                  // _buildTotalRow('Tax (0%)', '₹0.00'),
                  _buildTotalRow(
                    'Total',
                    'INR ${totalAmount.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                  _buildTotalRow(
                    'Paid by customer',
                    'INR ${totalAmount.toStringAsFixed(0)}',
                  ),
                  _buildTotalRow(
                    'Refunded',
                    'INR ${refundedAmount.toStringAsFixed(0)}',
                  ),
                  _buildTotalRow(
                    'Net amount retained',
                    'INR ${paidAmount.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Signature and stamp
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.start,
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
                ),
                pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      doctor.name ?? '',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '${doctor.degree ?? ''} ${doctor.drRegNumber ?? ''}',
                      style: pw.TextStyle(fontSize: 10),
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

            // Payment information
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: isRefunded || hasPartialRefund
                      ? warning
                      : wellnessGreen,
                  width: 1,
                ),
                color: isRefunded || hasPartialRefund
                    ? PdfColor.fromHex('FFFBEB')
                    : null,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: pw.EdgeInsets.all(12),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isRefunded
                              ? 'PAYMENT FULLY REFUNDED'
                              : hasPartialRefund
                              ? 'PAYMENT PARTIALLY REFUNDED'
                              : 'PAYMENT RECEIVED',
                          style: pw.TextStyle(
                            color: isRefunded || hasPartialRefund
                                ? warningDark
                                : wellnessGreen,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Payment Reference: ${appointment.paymentId ?? "N/A"}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Payment Status: ${isRefunded
                              ? "Fully refunded"
                              : hasPartialRefund
                              ? "Partially refunded"
                              : "Paid"}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                        if (appointment.orderId?.isNotEmpty == true)
                          pw.Text(
                            'Order ID: ${appointment.orderId}',
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        if (appointment.paymentVerifiedAt?.isNotEmpty == true)
                          pw.Text(
                            'Payment Date: ${_formatDate(appointment.paymentVerifiedAt!)}',
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        pw.Text(
                          'Original amount paid by customer: INR ${totalAmount.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Total refunded: INR ${refundedAmount.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            color: refundedAmount > 0 ? warningDark : null,
                            fontSize: 12,
                          ),
                        ),
                        pw.Text(
                          'Refunded appointments: ${refundedAppointments.length} of ${invoiceAppointments.length}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                        if (refundedAmount > 0) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Net amount retained: INR ${paidAmount.toStringAsFixed(0)}',
                            style: pw.TextStyle(
                              color: wellnessGreen,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          ...refundedAppointments.map(
                            (item) => pw.Text(
                              'Refund reference (${formatDateToReadable(item.bookingDate)}): '
                              '${item.razorpayRefundId}',
                              style: pw.TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        if (appointment.razorpayTransferId?.isNotEmpty == true)
                          pw.Text(
                            'Transfer Reference: ${appointment.razorpayTransferId}',
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        if (appointment.transferStatus?.isNotEmpty == true)
                          pw.Text(
                            'Transfer Status: ${appointment.transferStatus}',
                            style: pw.TextStyle(fontSize: 12),
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
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
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
                    _buildHtmlNotes(
                      appointment.doctorNotes ?? '',
                      medicalBlueDark,
                    ),
                  ],
                ),
              ),
            ],
            /* pw.Positioned(
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
            ),*/
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
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  static String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? value
        : DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
  }

  /// Helper method to build a table cell
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? textColor,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: textColor ?? (isHeader ? PdfColors.white : PdfColors.black),
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Helper method to build a total row
  static pw.Widget _buildTotalRow(
    String label,
    String amount, {
    bool isBold = false,
  }) {
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
    final document = html_parser.parseFragment(htmlString);
    final buffer = StringBuffer();

    void appendNode(Node node) {
      if (node.nodeType == Node.TEXT_NODE) {
        buffer.write(node.text);
        return;
      }

      if (node is! Element) {
        return;
      }

      final tag = node.localName?.toLowerCase();
      if (tag == 'br') {
        buffer.write('\n');
        return;
      }

      if (tag == 'li') {
        buffer.write('• ');
      }

      for (final child in node.nodes) {
        appendNode(child);
      }

      if ({
        'address',
        'article',
        'blockquote',
        'div',
        'h1',
        'h2',
        'h3',
        'h4',
        'h5',
        'h6',
        'li',
        'ol',
        'p',
        'pre',
        'section',
        'ul',
      }.contains(tag)) {
        buffer.write('\n');
      }
    }

    for (final node in document.nodes) {
      appendNode(node);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static pw.Widget _buildHtmlNotes(String htmlString, PdfColor accentColor) {
    final fragment = html_parser.parseFragment(htmlString);
    final blocks = <pw.Widget>[];

    for (final node in fragment.nodes) {
      _appendNoteBlocks(node, blocks, accentColor);
    }

    if (blocks.isEmpty) {
      return pw.Text(
        _stripHtmlTags(htmlString),
        style: const pw.TextStyle(fontSize: 11),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: blocks,
    );
  }

  static void _appendNoteBlocks(
    Node node,
    List<pw.Widget> blocks,
    PdfColor accentColor, {
    bool insideList = false,
  }) {
    if (node is! Element) {
      if (node.nodeType == Node.TEXT_NODE &&
          node.text?.trim().isNotEmpty == true) {
        blocks.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: _normaliseText(node.text),
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return;
    }

    final tag = node.localName?.toLowerCase();
    if (tag == 'br') {
      blocks.add(pw.SizedBox(height: 5));
      return;
    }

    if (tag == 'ul' || tag == 'ol') {
      for (final child in node.children) {
        if (child.localName?.toLowerCase() == 'li') {
          _appendNoteBlocks(child, blocks, accentColor, insideList: true);
        }
      }
      return;
    }

    final isBlock = {
      'address',
      'article',
      'blockquote',
      'div',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'li',
      'p',
      'pre',
      'section',
    }.contains(tag);

    if (isBlock) {
      final style = _noteTextStyle(tag, accentColor);
      final spans = _buildNoteSpans(node, style);
      if (spans.isNotEmpty) {
        blocks.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(
              left: insideList ? 12 : 0,
              bottom: tag?.startsWith('h') == true ? 6 : 4,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (tag == 'li')
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 6, top: 2),
                    child: pw.Text(
                      '•',
                      style: pw.TextStyle(
                        color: accentColor,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                pw.Expanded(
                  child: pw.RichText(text: pw.TextSpan(children: spans)),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    for (final child in node.nodes) {
      _appendNoteBlocks(child, blocks, accentColor, insideList: insideList);
    }
  }

  static List<pw.TextSpan> _buildNoteSpans(
    Node node,
    pw.TextStyle inheritedStyle,
  ) {
    if (node.nodeType == Node.TEXT_NODE) {
      final text = _normaliseText(node.text);
      return text.isEmpty
          ? []
          : [pw.TextSpan(text: text, style: inheritedStyle)];
    }

    if (node is! Element) {
      return [];
    }

    final tag = node.localName?.toLowerCase();
    final style = _noteInlineStyle(tag, inheritedStyle);
    final spans = <pw.TextSpan>[];
    for (final child in node.nodes) {
      spans.addAll(_buildNoteSpans(child, style));
    }
    return spans;
  }

  static pw.TextStyle _noteTextStyle(String? tag, PdfColor accentColor) {
    final isHeading = tag?.startsWith('h') == true;
    return pw.TextStyle(
      color: isHeading ? accentColor : PdfColors.black,
      fontSize: isHeading ? 12 : 11,
      fontWeight: isHeading ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
  }

  static pw.TextStyle _noteInlineStyle(
    String? tag,
    pw.TextStyle inheritedStyle,
  ) {
    if (tag == 'strong' || tag == 'b') {
      return inheritedStyle.copyWith(fontWeight: pw.FontWeight.bold);
    }
    if (tag == 'em' || tag == 'i') {
      return inheritedStyle.copyWith(fontStyle: pw.FontStyle.italic);
    }
    if (tag == 'u') {
      return inheritedStyle.copyWith(decoration: pw.TextDecoration.underline);
    }
    return inheritedStyle;
  }

  static String _normaliseText(String? value) {
    return (value ?? '')
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
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
          pw.Text('Reg. No. 123456', style: const pw.TextStyle(fontSize: 10)),
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
        pw.SizedBox(height: 5),
        pw.Container(width: 150, height: 1, color: PdfColors.black),
        pw.SizedBox(height: 5),
        pw.Text(
          'Authorized Signatory',
          style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
        ),
      ],
    );
  }
}
