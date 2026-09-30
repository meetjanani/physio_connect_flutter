// lib/ui/booking/history/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/model/bookings_model.dart';
import 'package:physio_connect/services/letter_head_service.dart';
import 'package:physio_connect/ui/booking_history/show_html_editor_for_doctor_note.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:physio_connect/utils/view_extension.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/invoice_service.dart';
import '../../services/booking_payment_flow.dart';
import '../../services/razorpay_checkout.dart';
import '../../utils/constants.dart';
import '../../utils/enum.dart';
import 'booking_history_controller.dart';
import '../../route/route_module.dart';

class BookingDetailScreen extends StatefulWidget {
  BookingDetailScreen({Key? key}) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingHistoryController controller =
      Get.isRegistered<BookingHistoryController>()
      ? Get.find<BookingHistoryController>()
      : Get.put(BookingHistoryController());

  final BookingsModel appointment = Get.arguments as BookingsModel;
  int _refundLongPressCount = 0;
  bool _refundUnlocked = false;
  List<int> _payingBookingIds = [];
  late final BookingPaymentFlow _payment;

  @override
  void initState() {
    super.initState();
    _payment = BookingPaymentFlow(
      bookingIds: () {
        final current = controller.selectedAppointment.value ?? appointment;
        return _payingBookingIds.isEmpty ? [current.id] : _payingBookingIds;
      },
      userId: () {
        final bookingUser =
            (controller.selectedAppointment.value ?? appointment).userId;
        if (bookingUser > 0) return bookingUser;
        return controller.userModelSupabase?.id ?? 0;
      },
      onPaid: _onPaid,
      onVerifyFailed: () async {
        final current = controller.selectedAppointment.value ?? appointment;
        await _refreshAppointment(current.id);
      },
      onCheckoutFailed: _onCheckoutFailed,
      // Pay-again is for an existing booking. Never delete it on cancel.
      deleteDraftsIfNoPaymentId: false,
    );
  }

  @override
  void dispose() {
    _payment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar("Appointment Details", isBackButtonVisible: true),
      body: Obx(
        () => controller.isLoading.value
            ? Center(
                child: CircularProgressIndicator(color: AppColors.medicalBlue),
              )
            : controller.selectedAppointment.value == null
            ? _buildErrorState()
            : _buildDetailsContent(context),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withOpacity(0.7),
          ),
          SizedBox(height: 16),
          Text(
            'Appointment not found',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "The appointment you're looking for does not exist",
            style: GoogleFonts.inter(
              textStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medicalBlue,
              foregroundColor: AppColors.textOnDark,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContent(BuildContext context) {
    final appointment = controller.selectedAppointment.value!;
    final isAppointmentRefunded =
        appointment.razorpayRefundId?.trim().isNotEmpty == true ||
        appointment.paymentStatus.toLowerCase() == 'refunded';
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final dateObj = DateFormat('yyyy-MM-dd').parse(appointment.bookingDate);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _getStatusColor(
                isAppointmentRefunded ? 'refunded' : appointment.bookingStatus,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(
                    isAppointmentRefunded
                        ? 'refunded'
                        : appointment.bookingStatus,
                  ),
                  color: AppColors.textOnDark,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isDoctorTypeUser(controller.userModelSupabase) &&
                              !isAppointmentRefunded
                          /*appointment.aPatient().userType?.toLowerCase() ==
                              UserType.doctor.name*/
                          ? Obx(
                              () => controller.isLoading.value
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            color: AppColors.textOnDark,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Updating status...',
                                          style: GoogleFonts.inter(
                                            textStyle: TextStyle(
                                              color: AppColors.textOnDark,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : DropdownButton<String>(
                                      value: appointment.bookingStatus
                                          .toLowerCase(),
                                      dropdownColor: AppColors.medicalBlueDark,
                                      style: GoogleFonts.inter(
                                        textStyle: TextStyle(
                                          color: AppColors.textOnDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      underline: Container(),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.textOnDark,
                                      ),
                                      onChanged: (String? newValue) {
                                        if (newValue != null &&
                                            newValue !=
                                                appointment.bookingStatus
                                                    .toLowerCase()) {
                                          appointment.bookingStatus = newValue;
                                          controller
                                              .updateAppointmentStatus(
                                                appointment,
                                              )
                                              .then((value) {
                                                setState(() {});
                                              });
                                        }
                                      },
                                      items:
                                          [
                                            BookingStatus.pending.name,
                                            BookingStatus.confirmed.name,
                                            BookingStatus.completed.name,
                                            BookingStatus.cancelled.name,
                                            BookingStatus.noShow.name,
                                            BookingStatus.refunded.name,
                                          ].map<DropdownMenuItem<String>>((
                                            String value,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                _getStatusText(value),
                                                style: GoogleFonts.inter(
                                                  textStyle: TextStyle(
                                                    color: AppColors.textOnDark,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                            )
                          : Text(
                              _getStatusText(
                                isAppointmentRefunded
                                    ? 'refunded'
                                    : appointment.bookingStatus,
                              ),
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                      SizedBox(height: 4),
                      Text(
                        _getStatusDescription(
                          isAppointmentRefunded
                              ? 'refunded'
                              : appointment.bookingStatus,
                        ),
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            color: AppColors.textOnDark.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Appointment info
          Text(
            'Appointment Details',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 16),
          if (appointment.paymentStatus.toLowerCase() == 'refunded')
            _buildRefundNotice(appointment),
          if (appointment.paymentStatus.toLowerCase() == 'refunded')
            SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow(
              'Session Type',
              "${appointment.aSessionType().name}\n${appointment.aSessionType().description}",
              () {},
              Icons.healing,
            ),
            _buildInfoRow(
              'Date',
              dateFormatter.format(dateObj),
              () {},
              Icons.calendar_today,
            ),
            _buildInfoRow(
              'Time',
              appointment.aTimeslot().time,
              () {},
              Icons.access_time,
            ),
            _buildInfoRow(
              'Duration',
              appointment.aSessionType().duration,
              () {},
              Icons.timelapse,
            ),
            _buildInfoRow('Address', appointment.address ?? 'N/A', () async {
              if (appointment.latLong != null) {
                var latLongPoint = appointment.latLong!.split(
                  LAT_LONG_SEPRATOR,
                );
                var lat = latLongPoint[0];
                var long = latLongPoint[1];
                final url =
                    'https://www.google.com/maps/dir/?api=1&destination=$lat,$long&travelmode=driving';
                try {
                  await launchUrl(Uri.parse(url));
                } catch (e) {
                  showErrorSnackbar('Could not open the map: ${e.toString()}');
                }
              }
            }, Icons.location_pin),
          ]),

          SizedBox(height: 24),

          // Therapist info
          Text(
            'Therapist',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildTherapistCard(appointment),

          SizedBox(height: 24),

          // Payment info
          Text(
            'Payment Information',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildInfoCard([
            _buildInfoRow(
              'Amount',
              '₹${appointment.price.toStringAsFixed(0)}',
              () {},
              Icons.payments,
              valueColor: AppColors.medicalBlueDark,
              valueBold: true,
            ),
            _buildInfoRow(
              'Status',
              _getPaymentStatusText(appointment.paymentStatus),
              () {},
              appointment.paymentStatus.toLowerCase() == 'refunded'
                  ? Icons.replay
                  : Icons.check_circle,
              valueColor: _getPaymentStatusColor(appointment.paymentStatus),
              valueBold: true,
            ),
            if (appointment.paymentId?.isNotEmpty == true)
              _buildInfoRow(
                'Payment Reference',
                appointment.paymentId ?? 'N/A',
                () {},
                Icons.receipt_long,
                valueStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            if (appointment.orderId?.isNotEmpty == true)
              _buildInfoRow(
                'Order ID',
                appointment.orderId!,
                () {},
                Icons.shopping_bag_outlined,
                valueStyle: _referenceTextStyle,
              ),
            if (appointment.paymentVerifiedAt?.isNotEmpty == true)
              _buildInfoRow(
                'Payment Date',
                _formatDateTime(appointment.paymentVerifiedAt!),
                () {},
                Icons.event_available,
              ),
            if (appointment.paymentFailureReason?.trim().isNotEmpty == true)
              _buildInfoRow(
                'Failure reason',
                appointment.paymentFailureReason!,
                () {},
                Icons.error_outline,
                valueColor: AppColors.error,
              ),
            if (appointment.paymentStatus.toLowerCase() == 'refunded') ...[
              _buildInfoRow(
                'Refunded Amount',
                '₹${appointment.price.toStringAsFixed(0)}',
                () {},
                Icons.currency_exchange,
                valueColor: AppColors.warningDark,
                valueBold: true,
              ),
              if (appointment.razorpayRefundId?.isNotEmpty == true)
                _buildInfoRow(
                  'Refund Reference',
                  appointment.razorpayRefundId!,
                  () {},
                  Icons.receipt_long,
                  valueStyle: _referenceTextStyle,
                ),
            ],
            if (appointment.razorpayTransferId?.isNotEmpty == true)
              _buildInfoRow(
                'Transfer Reference',
                appointment.razorpayTransferId!,
                () {},
                Icons.account_balance_outlined,
                valueStyle: _referenceTextStyle,
              ),
            if (appointment.transferStatus?.isNotEmpty == true)
              _buildInfoRow(
                'Transfer Status',
                _getPaymentStatusText(appointment.transferStatus!),
                () {},
                Icons.sync,
                valueColor: _getPaymentStatusColor(appointment.transferStatus!),
              ),
          ]),

          SizedBox(height: 24),

          // Notes
          Text(
            'Doctor\'s Notes',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildNotesCard(
            appointment.doctorNotes ?? 'No additional notes provided.',
          ),
          SizedBox(height: 24),
          _buildRefundAction(context, appointment),
          _buildPayAgainButton(appointment),
          _buildInvoiceButton(context, appointment),
          _buildRescheduleButton(context, appointment),
          _buildPatientCancelButton(context, appointment),
          _buildPatientRating(appointment),

          // Prescription Button
          if (controller.isDoctor.value) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(
                AppPage.generatePrescription,
                arguments: appointment,
              ),
              icon: Icon(Icons.description_outlined),
              label: Text('Generate Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medicalBlueDark,
                foregroundColor: AppColors.textOnDark,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final doctor = appointment.aDoctor();
                final file = await LetterHeadService.generateLetterHead(
                  doctorName: doctor.name,
                  doctorRegNumber: doctor.drRegNumber,
                  doctorDegree: doctor.degree,
                );
                await LetterHeadService.openPdf(file);
              },
              icon: Icon(Icons.description_outlined),
              label: Text('Generate Letter Head'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medicalBlueDark,
                foregroundColor: AppColors.textOnDark,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
            SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildRefundAction(BuildContext context, BookingsModel appointment) {
    if (!_canAttemptRefund(appointment)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _buildRefundButton(context, appointment),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (index) {
          if (index.isEven) {
            return children[index ~/ 2];
          } else {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            );
          }
        }),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    VoidCallback iconTap,
    IconData icon, {
    Color? valueColor,
    bool valueBold = false,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.medicalBlueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: iconTap,
            child: Icon(icon, color: AppColors.medicalBlueDark, size: 16),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style:
                    valueStyle ??
                    GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: valueColor ?? AppColors.textPrimary,
                        fontWeight: valueBold
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTherapistCard(BookingsModel appointment) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(controller.therapistsImage),
            backgroundColor: AppColors.medicalBlueLight,
            child: controller.therapistsImage.isEmpty
                ? Icon(Icons.person, color: AppColors.medicalBlueDark)
                : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.aDoctor().name ?? '',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  appointment.aDoctor().degree ?? '',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              showSuccessSnackbar(
                "Request for call has been initiated\n"
                "Doctor may call you back within 8 hours",
              );
              controller.sendReminderNotification();
            },
            icon: Icon(Icons.call, size: 16),
            label: Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wellnessGreen,
              foregroundColor: AppColors.textOnDark,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(80, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return InkWell(
      onTap: () {
        if (isDoctorTypeUser(controller.userModelSupabase))
          showHtmlEditorForDoctorNote(
            context: Get.context!,
            initialHtml: appointment.doctorNotes ?? "",
            onSave: (String updatedHtml) async {
              appointment.doctorNotes = updatedHtml;
              await controller.updateDoctorNote(appointment);
            },
            title: "Edit Doctor's Note",
          );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppColors.medicalBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  color: AppColors.medicalBlue,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recommendations & Precautions',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.medicalBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            HtmlWidget(notes),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundNotice(BookingsModel appointment) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.warningDark),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment refunded',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      color: AppColors.warningDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '₹${appointment.price.toStringAsFixed(0)} has been refunded. '
                  'Keep this receipt for your records.',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      color: AppColors.warningDark,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
      case 'booked':
        return AppColors.wellnessGreen;
      case 'completed':
        return AppColors.medicalBlue;
      case 'cancelled':
        return AppColors.error;
      case 'refunded':
      case 'no-show':
      case 'no_show':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top;
      case 'confirmed':
      case 'booked':
        return Icons.event_available;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.currency_exchange;
      case 'no-show':
      case 'no_show':
        return Icons.event_busy;
      default:
        return Icons.event_note;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Payment';
      case 'confirmed':
      case 'booked':
        return 'Upcoming Appointment';
      case 'completed':
        return 'Completed Session';
      case 'cancelled':
        return 'Cancelled Appointment';
      case 'refunded':
        return 'Refunded Appointment';
      case 'no-show':
      case 'no_show':
        return 'Missed Appointment';
      default:
        return status.capitalize!;
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Complete payment to confirm your session';
      case 'confirmed':
      case 'booked':
        return 'Your session is scheduled and confirmed';
      case 'completed':
        return 'Your session has been successfully completed';
      case 'cancelled':
        return 'This appointment was cancelled';
      case 'refunded':
        return 'The payment for this appointment has been refunded';
      case 'no-show':
      case 'no_show':
        return 'You did not attend this appointment';
      default:
        return '';
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.wellnessGreen;
      case 'created':
      case 'pending':
        return AppColors.warning;
      case 'refunded':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return 'Payment Created';
      case 'paid':
        return 'Paid';
      case 'refunded':
        return 'Refunded';
      case 'failed':
        return 'Payment Failed';
      case 'pending':
        return 'Payment Pending';
      default:
        return status.capitalize ?? status;
    }
  }

  String _formatDateTime(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? value
        : DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
  }

  TextStyle get _referenceTextStyle => TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
    fontFamily: 'monospace',
  );

  // TODO: Test Refund properly form doctor & patient side. Refund is only allowed for doctor role, and only within 48 hours of payment verification.
  bool _canAttemptRefund(BookingsModel appointment) {
    if (!controller.isDoctor.value) return false;

    final verifiedAt = DateTime.tryParse(appointment.paymentVerifiedAt ?? '');
    if (verifiedAt == null ||
        verifiedAt.isAfter(DateTime.now()) ||
        DateTime.now().difference(verifiedAt) > const Duration(hours: 48)) {
      return false;
    }

    return appointment.paymentStatus.toLowerCase() == 'paid' &&
        appointment.razorpayRefundId?.trim().isEmpty != false;
  }

  Widget _buildRefundButton(BuildContext context, BookingsModel appointment) {
    final isProcessing = controller.isLoading.value;
    final isEnabled = _refundUnlocked && !isProcessing;

    return GestureDetector(
      onLongPress: isProcessing
          ? null
          : () {
              if (!_canAttemptRefund(appointment)) {
                return;
              }

              setState(() {
                _refundLongPressCount++;
                if (_refundLongPressCount >= 2) {
                  _refundUnlocked = true;
                }
              });

              if (_refundUnlocked) {
                showSuccessSnackbar(
                  'Refund unlocked. Tap the button to continue.',
                );
              } else {
                showSnackbar(
                  'Refund Locked',
                  'Long press once more to enable the refund button.',
                );
              }
            },
      child: ElevatedButton.icon(
        onPressed: isEnabled
            ? () => _confirmAndProcessRefund(context, appointment)
            : null,
        icon: Icon(Icons.currency_exchange),
        label: Text(
          isProcessing
              ? 'Processing Refund...'
              : _refundUnlocked
              ? 'Refund Payment'
              : 'Long Press Twice to Unlock Refund',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          disabledBackgroundColor: AppColors.errorLight,
          foregroundColor: AppColors.textOnDark,
          disabledForegroundColor: AppColors.errorDark,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndProcessRefund(
    BuildContext context,
    BookingsModel appointment,
  ) async {
    final shouldRefund = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirm Refund'),
        content: Text(
          'This payment can only be refunded once. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnDark,
            ),
            child: Text('Refund Payment'),
          ),
        ],
      ),
    );

    if (shouldRefund != true || !_canAttemptRefund(appointment)) {
      return;
    }

    final result = await controller.processRefundForPatient(
      appointment.id.toString(),
      appointment.doctorId.toString(),
    );

    if (result.success && result.refundId?.trim().isNotEmpty == true) {
      setState(() {
        appointment.razorpayRefundId = result.refundId;
        appointment.paymentStatus = 'refunded';
        appointment.bookingStatus = 'refunded';
        _refundUnlocked = false;
        _refundLongPressCount = 0;
      });
      await controller.updateAppointmentStatus(appointment);
    }
  }

  Widget _buildInvoiceButton(BuildContext context, BookingsModel appointment) {
    final canGenerateInvoice =
        appointment.bookingStatus.toLowerCase() ==
            BookingStatus.completed.name &&
        [
          PaymentStatus.paid.name,
          PaymentStatus.refunded.name,
        ].contains(appointment.paymentStatus.toLowerCase());
    if (!canGenerateInvoice) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _generateInvoice(context, appointment),
          icon: Icon(Icons.receipt_long),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.medicalBlue,
            foregroundColor: AppColors.textOnDark,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          label: Text('Generate Invoice'),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRescheduleButton(
    BuildContext context,
    BookingsModel appointment,
  ) {
    final canRescheduleUserRoleWise = controller.isDoctor.value
        ? true
        : _isAfterToday(appointment.bookingDate);
    final canReschedule =
        (appointment.paymentStatus.toLowerCase() == PaymentStatus.paid.name ||
            appointment.paymentStatus.toLowerCase() ==
                PaymentStatus.refunded.name) &&
        (appointment.bookingStatus.toLowerCase() !=
            BookingStatus.completed.name) &&
        (canRescheduleUserRoleWise);
    if (!canReschedule) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showRescheduleDialog(context, appointment),
            icon: Icon(Icons.edit_calendar),
            label: Text('Reschedule'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppColors.medicalBlue),
              foregroundColor: AppColors.medicalBlue,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showRescheduleDialog(
    BuildContext context,
    BookingsModel appointment,
  ) async {
    final currentDate =
        DateTime.tryParse(appointment.bookingDate) ?? DateTime.now();
    DateTime? selectedDate = currentDate;

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Reschedule Appointment',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please confirm a new date for this appointment.',
                    style: GoogleFonts.inter(),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warningDark,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The appointment date will be updated for the patient.',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 12,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate!.isBefore(DateTime.now())
                            ? DateTime.now()
                            : selectedDate!,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    icon: Icon(Icons.calendar_month),
                    label: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'keep'),
                  child: Text('Keep Current Date'),
                ),
                ElevatedButton(
                  onPressed: selectedDate == currentDate
                      ? null
                      : () => Navigator.pop(dialogContext, 'reschedule'),
                  child: Text('Confirm Date'),
                ),
              ],
            );
          },
        );
      },
    );

    if (action == 'reschedule' && selectedDate != null) {
      await controller.rescheduleAppointment(appointment, selectedDate!);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildPayAgainButton(BookingsModel appointment) {
    if (!_canPayAgain(appointment)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Obx(
        () => ElevatedButton(
          onPressed: _payment.isBusy.value
              ? null
              : () => _payAgain(appointment),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.medicalBlue,
            foregroundColor: AppColors.textOnDark,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(_payment.isBusy.value ? 'Starting payment...' : 'Pay now'),
        ),
      ),
    );
  }

  bool _canPayAgain(BookingsModel appointment) {
    if (controller.isDoctor.value) return false;
    final payment = appointment.paymentStatus.toLowerCase();
    final booking = appointment.bookingStatus.toLowerCase();
    final unpaid =
        payment == PaymentStatus.paid.name ||
        payment == PaymentStatus.refunded.name;
    final closed =
        booking == BookingStatus.cancelled.name ||
        booking == BookingStatus.completed.name ||
        booking == BookingStatus.refunded.name;
    return !unpaid && !closed;
  }

  // TODO : Improve Query filter instade of filtering in code. This is a temporary solution to get unpaid booking ids for bulk appointments.
  Future<List<int>> _unpaidBookingIds(BookingsModel appointment) async {
    if (appointment.isBulkAppointment &&
        appointment.bulkAppointmentId?.trim().isNotEmpty == true) {
      final group = await controller.supabaseController
          .getBookingsByBulkAppointmentId(
            appointment.userId,
            appointment.bulkAppointmentId!,
          );
      final ids = group
          .where((booking) {
            final status = booking.paymentStatus.toLowerCase();
            return status != PaymentStatus.paid.name &&
                status != PaymentStatus.refunded.name;
          })
          .map((booking) => booking.id)
          .toList();
      if (ids.isNotEmpty) return ids;
    }
    return [appointment.id];
  }

  String _paymentContact(BookingsModel appointment) {
    try {
      return appointment.aPatient().mobileNumber ??
          controller.userModelSupabase?.mobileNumber ??
          '';
    } catch (_) {
      return controller.userModelSupabase?.mobileNumber ?? '';
    }
  }

  String _paymentDescription(BookingsModel appointment) {
    try {
      return 'Payment for ${appointment.aSessionType().name}';
    } catch (_) {
      return 'Physiotherapy session';
    }
  }

  Future<void> _payAgain(BookingsModel appointment) async {
    final bookingIds = await _unpaidBookingIds(appointment);
    _payingBookingIds = bookingIds;
    await _payment.collectPayment(
      createOrder: () => controller.supabaseController
          .callCreateRazorPayOrderForBookings(
            bookingIds: bookingIds,
            userId: appointment.userId,
            isBulkAppointment: appointment.isBulkAppointment,
            bulkAppointmentId: appointment.bulkAppointmentId,
          ),
      description: _paymentDescription(appointment),
      contact: _paymentContact(appointment),
    );
  }

  Future<void> _onPaid(PaidPaymentResult paid) async {
    final current = controller.selectedAppointment.value ?? appointment;
    current
      ..bookingStatus = BookingStatus.confirmed.name
      ..paymentStatus = PaymentStatus.paid.name
      ..paymentId = paid.paymentId
      ..orderId = paid.orderId
      ..signature = paid.signature;
    controller.selectedAppointment.value = current;
    controller.selectedAppointment.refresh();
    await _refreshAppointment(current.id);
    _showPaymentSnackbar(
      'Payment successful',
      'Your session payment is confirmed.',
    );
  }

  Future<void> _onCheckoutFailed(RazorpayFailureDetails failure) async {
    final current = controller.selectedAppointment.value ?? appointment;
    final bookingIds = _payingBookingIds.isEmpty
        ? [current.id]
        : _payingBookingIds;
    final refreshed = await controller.supabaseController.getBookingById(
      current.id.toString(),
    );
    if (refreshed == null) {
      _removeDeletedBookings(bookingIds);
      _showPaymentSnackbar(failure.title, failure.message);
      if (mounted) Get.back();
      return;
    }
    controller.selectedAppointment.value = refreshed;
    if (mounted) setState(() {});
    _showPaymentSnackbar(failure.title, failure.message);
  }

  void _removeDeletedBookings(List<int> bookingIds) {
    controller.upComingBookings.removeWhere(
      (booking) => bookingIds.contains(booking.id),
    );
    controller.selectedAppointment.value = null;
  }

  Future<void> _refreshAppointment(int bookingId) async {
    final refreshed = await controller.supabaseController.getBookingById(
      bookingId.toString(),
    );
    if (refreshed != null) {
      controller.selectedAppointment.value = refreshed;
      final index = controller.upComingBookings.indexWhere(
        (booking) => booking.id == refreshed.id,
      );
      if (index >= 0) {
        controller.upComingBookings[index] = refreshed;
      }
    } else {
      _removeDeletedBookings([bookingId]);
    }
    if (mounted) setState(() {});
  }

  void _showPaymentSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: title == 'Payment successful'
          ? AppColors.wellnessGreen
          : AppColors.error,
      colorText: AppColors.textOnDark,
    );
  }

  Widget _buildPatientCancelButton(
    BuildContext context,
    BookingsModel appointment,
  ) {
    if (controller.isDoctor.value || !_canPatientCancel(appointment)) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmPatientCancel(context, appointment),
            icon: Icon(Icons.cancel_outlined),
            label: Text('Cancel Appointment'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppColors.error),
              foregroundColor: AppColors.error,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Cancelling frees the slot. Refunds are processed by support '
            '($SUPPORT_EMAIL / WhatsApp). Free refund if cancelled more than '
            '$FREE_CANCEL_HOURS hours ahead; later cancels may be partial.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  bool _canPatientCancel(BookingsModel appointment) {
    final status = appointment.bookingStatus.toLowerCase();
    return (status == BookingStatus.pending.name ||
            status == BookingStatus.confirmed.name) &&
        _isAfterToday(appointment.bookingDate);
  }

  bool _isAfterToday(String date) {
    final bookingDate = DateTime.tryParse(date);
    if (bookingDate == null) return false;

    final today = DateTime.now();
    final appointmentDay = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
    );
    final todayDay = DateTime(today.year, today.month, today.day);
    return appointmentDay.isAfter(todayDay);
  }

  Future<void> _confirmPatientCancel(
    BuildContext context,
    BookingsModel appointment,
  ) async {
    final bookingDate = DateTime.tryParse(appointment.bookingDate);
    final hoursAhead = bookingDate == null
        ? 0
        : bookingDate.difference(DateTime.now()).inHours;
    final freeCancel = hoursAhead >= FREE_CANCEL_HOURS;

    final shouldCancel = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Cancel appointment?'),
        content: Text(
          freeCancel
              ? 'You are cancelling more than $FREE_CANCEL_HOURS hours ahead. '
                    'This frees the slot. For a refund, contact support at '
                    '$SUPPORT_EMAIL or WhatsApp — it is not automatic in the app.'
              : 'This cancellation is within $FREE_CANCEL_HOURS hours of the session. '
                    'The slot will be freed. Refunds (if any) are handled by support '
                    'and may be partial. Contact $SUPPORT_EMAIL.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    appointment.bookingStatus = BookingStatus.cancelled.name;
    await controller.updateAppointmentStatus(appointment);
    setState(() {});
    Get.snackbar('Cancelled', 'Your appointment was cancelled.');
  }

  // Add this new method for invoice generation
  void _generateInvoice(BuildContext context, BookingsModel appointment) async {
    // Show loading indicator
    Get.dialog(
      Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.medicalBlue),
              SizedBox(height: 16),
              Text(
                'Generating Invoice...',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      var invoiceAppointments = <BookingsModel>[appointment];
      if (appointment.isBulkAppointment &&
          appointment.bulkAppointmentId?.trim().isNotEmpty == true) {
        invoiceAppointments = await controller.supabaseController
            .getBookingsByBulkAppointmentId(
              appointment.userId,
              appointment.bulkAppointmentId!,
            );
      }
      final pdfFile = await InvoiceService.generateInvoice(
        appointment,
        appointments: invoiceAppointments,
      );
      Get.back(); // Close loading dialog

      // Show and open PDF
      await InvoiceService.openPdf(pdfFile);
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to generate invoice: ${e.toString()}',
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildPatientRating(BookingsModel appointment) {
    if (controller.isDoctor.value ||
        [
          BookingStatus.pending.name,
          BookingStatus.confirmed.name,
          BookingStatus.noShow.name,
        ].contains(appointment.bookingStatus.toLowerCase())) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: _buildRatingSection(appointment),
    );
  }

  Widget _buildRatingSection(BookingsModel appointment) {
    final existing = appointment.rating ?? 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            existing > 0 ? 'Your rating' : 'Rate your session',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: existing > 0
                    ? null
                    : () => _submitRating(appointment, star),
                icon: Icon(
                  star <= existing ? Icons.star : Icons.star_border,
                  color: AppColors.ratingGold,
                ),
              );
            }),
          ),
          if (appointment.ratingComment?.isNotEmpty == true)
            Text(
              appointment.ratingComment!,
              style: TextStyle(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Future<void> _submitRating(BookingsModel appointment, int stars) async {
    final commentController = TextEditingController();
    final comment = await Get.dialog<String>(
      AlertDialog(
        title: Text('Thanks! Add a short note?'),
        content: TextField(
          controller: commentController,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'How was your physio session?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: ''),
            child: Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: commentController.text.trim()),
            child: Text('Submit'),
          ),
        ],
      ),
    );
    await controller.submitRating(appointment, stars, comment ?? '');
    setState(() {
      appointment.rating = stars;
      appointment.ratingComment = comment;
    });
  }
}
