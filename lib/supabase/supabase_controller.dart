import 'package:get/get.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/model/time_slots_model.dart';
import 'package:physio_connect/utils/enum.dart';
import 'package:physio_connect/utils/view_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/bookings_model.dart';
import '../model/create_razorpay_order_model.dart';
import '../model/area_model.dart';
import '../model/city_state_model.dart';
import '../model/refund_response_model.dart';
import '../model/session_type_model.dart';
import '../model/user_model_supabase.dart';
import '../model/verify_razorpay_payment_order_model.dart';
import '../route/route_module.dart';
import '../utils/database_schema.dart';
import '../utils/secure_storage/notification_service.dart';

class SupabaseController {
  static SupabaseController get to => Get.find();
  final notificationService = NotificationService();
  final SupabaseClient supabaseClient = Supabase.instance.client;

  Future<BookingsModel?> getBookingById(String bookingId) async {
    final response = await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .select('*')
        .eq(DatabaseSchema.bookingsId, bookingId);
    var bookingList = BookingsModel.fromJsonList(response);
    return bookingList.firstOrNull;
  }

  Future<List<BookingsModel>> getUpComingBookings(
    int userId,
    bool isDoctor,
  ) async {
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final userColumn = isDoctor
        ? DatabaseSchema.bookingsDoctorId
        : DatabaseSchema.bookingsUserId;
    final response = await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .select('*')
        .eq(userColumn, userId)
        .gte(DatabaseSchema.bookingsDate, today)
        .order(DatabaseSchema.bookingsId, ascending: true);
    var bookingList = BookingsModel.fromJsonList(response);
    return bookingList;
  }

  Future<List<BookingsModel>> getBookingsByBulkAppointmentId(
    int userId,
    String bulkAppointmentId,
  ) async {
    if (userId <= 0 || bulkAppointmentId.trim().isEmpty) {
      throw ArgumentError('A valid user and bulk appointment ID are required.');
    }
    final response = await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .select('*')
        .eq(DatabaseSchema.bookingsUserId, userId)
        .eq(DatabaseSchema.bookingsBulkAppointmentId, bulkAppointmentId)
        .eq(DatabaseSchema.bookingsIsBulkAppointment, true)
        .order(DatabaseSchema.bookingsDate, ascending: true);
    return BookingsModel.fromJsonList(response);
  }

  Future<List<BookingsModel>> getFilteredBookings(
    int userId,
    DateTime from,
    DateTime to,
    bool isDoctor,
  ) async {
    final String fromDate = from.toIso8601String().split('T')[0];
    final String toDate = to.toIso8601String().split('T')[0];
    var response;
    if (isDoctor) {
      final doctor = await getDoctorByUserId(userId);
      final doctorTableId = doctor?.userId ?? 0;
      if (doctorTableId <= 0) {
        return [];
      }
      response = await supabaseClient
          .from(DatabaseSchema.bookingsTable)
          .select('*')
          .eq(DatabaseSchema.bookingsDoctorId, doctorTableId)
          .gte(DatabaseSchema.bookingsDate, fromDate)
          .lte(DatabaseSchema.bookingsDate, toDate)
          .order(DatabaseSchema.bookingsId, ascending: false);
    } else {
      response = await supabaseClient
          .from(DatabaseSchema.bookingsTable)
          .select('*')
          .eq(DatabaseSchema.bookingsUserId, userId)
          .gte(DatabaseSchema.bookingsDate, fromDate)
          .lte(DatabaseSchema.bookingsDate, toDate)
          .order(DatabaseSchema.bookingsId, ascending: false);
    }
    var bookingList = BookingsModel.fromJsonList(response);
    return bookingList;
  }

  Future<void> updateFirebaseToken(int userId, String firebaseToken) async {
    if (userId > 0 && firebaseToken.isNotEmpty) {
      await supabaseClient
          .from(DatabaseSchema.usersTable)
          .update({DatabaseSchema.userFirebaseToken: firebaseToken})
          .eq(DatabaseSchema.usersId, userId)
          .select();
    }
  }

  Future<void> updateDoctorNote(
    int bookingID,
    BookingsModel? updatedBooking,
  ) async {
    if (bookingID > 0 && updatedBooking != null) {
      await supabaseClient
          .from(DatabaseSchema.bookingsTable)
          .update({
            DatabaseSchema.bookingsDoctorNotes: updatedBooking.doctorNotes,
          })
          .eq(DatabaseSchema.bookingsId, bookingID)
          .select();
    }
  }

  Future<void> updateBookingStatus(
    int bookingID,
    BookingsModel? updatedBooking,
  ) async {
    if (bookingID > 0 && updatedBooking != null) {
      await supabaseClient
          .from(DatabaseSchema.bookingsTable)
          .update({DatabaseSchema.bookingsStatus: updatedBooking.bookingStatus})
          .eq(DatabaseSchema.bookingsId, bookingID)
          .select();
    }
  }

  Future<void> updateBookingDate(int bookingID, String bookingDate) async {
    if (bookingID > 0 && bookingDate.isNotEmpty) {
      await supabaseClient
          .from(DatabaseSchema.bookingsTable)
          .update({DatabaseSchema.bookingsDate: bookingDate})
          .eq(DatabaseSchema.bookingsId, bookingID)
          .select();
    }
  }

  // Get Master Data
  Future<List<SessionTypeModel>> getSessionTypeMaster({
    List<int>? sessionTypeIds,
  }) async {
    var query = supabaseClient
        .from(DatabaseSchema.sessionTypeTable)
        .select('*')
        .eq(DatabaseSchema.sessionTypeIsActive, true);
    if (sessionTypeIds != null && sessionTypeIds.isNotEmpty) {
      query = query.inFilter(DatabaseSchema.sessionTypeId, sessionTypeIds);
    }
    final response = await query.order(
      DatabaseSchema.sessionTypeOrderBy,
      ascending: true,
    );
    var bookingList = SessionTypeModel.fromJsonList(response);
    return bookingList;
  }

  Future<List<CityStateModel>> getCityState() async {
    final response = await supabaseClient
        .from(DatabaseSchema.cityStateTable)
        .select('*')
        .eq(DatabaseSchema.cityStateIsActive, true);
    // .order(DatabaseSchema.serviceStatesOrderBy, ascending: true);
    return CityStateModel.fromJsonList(response);
  }

  // Future<List<ServiceCityModel>> getCityStateWiseArea(String cityStateId) async {
  //   final stateResponse = await getServiceStates();
  //   final statesById = {for (final state in stateResponse) state.id: state};
  //
  //   final response = await supabaseClient
  //       .from(DatabaseSchema.areaTable)
  //       .select('*')
  //       .eq(DatabaseSchema.areaCityStateId, cityStateId)
  //       .eq(DatabaseSchema.areaIsActive, true);
  //       .order(DatabaseSchema.serviceCitiesOrderBy, ascending: true);
  //
  //   final cities = ServiceCityModel.fromJsonList(response);
  //   for (final city in cities) {
  //     final state = statesById[city.stateId];
  //     city.stateName = state?.cityStateName ?? '';
  //   }
  //   return cities;
  // }

  Future<List<AreaModel>> getServiceAreas(int cityId) async {
    final response = await supabaseClient
        .from(DatabaseSchema.areaTable)
        .select('*')
        .eq(DatabaseSchema.areaCityStateId, cityId)
        .eq(DatabaseSchema.serviceAreasIsActive, true)
        .order(DatabaseSchema.areaOrderBy, ascending: false);
    return AreaModel.fromJsonList(response);
  }

  /// Batch-fetch doctors by primary keys (used for area list doctor cards).
  Future<List<DoctorModel>> getDoctorsByIds(List<int> doctorIds) async {
    final ids = doctorIds.where((id) => id > 0).toSet().toList();
    if (ids.isEmpty) return <DoctorModel>[];
    final response = await supabaseClient
        .from(DatabaseSchema.doctorTable)
        .select('*')
        .inFilter(DatabaseSchema.doctorId, ids)
        .eq('isActive', true);
    return DoctorModel.fromJsonList(response);
  }

  Future<List<DoctorModel>> getDoctorsForArea(int areaId) async {
    final areaDoctorLinks = await supabaseClient
        .from(DatabaseSchema.doctorServiceAreasTable)
        .select('*')
        .eq(DatabaseSchema.doctorServiceAreasServiceAreaId, areaId)
        .eq(DatabaseSchema.doctorServiceAreasIsActive, true);

    if (areaDoctorLinks.isEmpty) {
      return <DoctorModel>[];
    }

    final doctorIds = areaDoctorLinks
        .map(
          (link) =>
              int.tryParse(
                link[DatabaseSchema.doctorServiceAreasDoctorId].toString(),
              ) ??
              0,
        )
        .where((id) => id > 0)
        .toList();

    if (doctorIds.isEmpty) {
      return <DoctorModel>[];
    }

    return getDoctorsByIds(doctorIds);
  }

  Future<List<TimeSlotModel>> getTimeSlotsMaster(
    DateTime bookingDate,
    int doctorUserId, {
    List<int>? timeSlotIds,
  }) async {
    final String formattedDate = bookingDate.toIso8601String().split('T')[0];
    var query = supabaseClient
        .from(DatabaseSchema.timeSlotTable)
        .select('*')
        .eq(DatabaseSchema.timeSlotIsActive, true);
    if (timeSlotIds != null && timeSlotIds.isNotEmpty) {
      query = query.inFilter(DatabaseSchema.timeSlotId, timeSlotIds);
    }
    final response = await query.order(
      DatabaseSchema.timeSlotOrderBy,
      ascending: true,
    );
    var timeSlotList = TimeSlotModel.fromJsonList(response);

    final bookingsResponse = await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .select(
          'timeSlotId,${DatabaseSchema.bookingsPaymentStatus},${DatabaseSchema.bookingsCreatedAt},${DatabaseSchema.bookingsStatus}',
        )
        .eq(DatabaseSchema.bookingsDoctorId, doctorUserId)
        .eq(DatabaseSchema.bookingsDate, formattedDate);

    final bookedTimeslotList = <dynamic>[];
    for (final row in bookingsResponse) {
      final payment =
          (row[DatabaseSchema.bookingsPaymentStatus] as String? ?? '')
              .toLowerCase();
      final status =
          (row[DatabaseSchema.bookingsStatus] as String? ?? '').toLowerCase();
      if (status == 'cancelled' ||
          status == 'canceled' ||
          status == 'refunded') {
        continue;
      }
      if ((payment == 'paid') || (payment == 'pending')) {
        bookedTimeslotList.add(row['timeSlotId']);
        continue;
      }
    }
    for (var timeSlot in timeSlotList) {
      if (bookedTimeslotList.contains(timeSlot.id)) {
        timeSlot.isBooked = true;
      }
    }

    return timeSlotList;
  }

  /// Active master time slots (no booking occupancy filter).
  Future<List<TimeSlotModel>> getActiveTimeSlots() async {
    final response = await supabaseClient
        .from(DatabaseSchema.timeSlotTable)
        .select('*')
        .eq(DatabaseSchema.timeSlotIsActive, true)
        .order(DatabaseSchema.timeSlotOrderBy, ascending: true);
    return TimeSlotModel.fromJsonList(response);
  }

  /// Persists comma-separated time slot ids on the doctor row (e.g. "1,2,5").
  Future<void> updateDoctorTimeSlotIds(
    int doctorTableId,
    String timeSlotIdsCsv,
  ) async {
    if (doctorTableId <= 0) return;
    await supabaseClient
        .from(DatabaseSchema.doctorTable)
        .update({DatabaseSchema.doctorTimeSlotId: timeSlotIdsCsv})
        .eq(DatabaseSchema.doctorId, doctorTableId);
  }

  Future<int> createNewBooking(
    BookingsModel bookingsModel,
    int notificationUserId,
  ) async {
    var request = bookingsModel.toJson();
    request.remove('id');
    var response = await Supabase.instance.client
        .from(DatabaseSchema.bookingsTable)
        .upsert([request])
        .select();
    var newId = response[0]['id'];
    // Get.back(result: true); // dismiss progress bar
    Get.showSuccessSnackbar('Your booking has been placed successfully.');
    // Get.toNamed(AppPage.bookingConfirmation);
    return newId;
  }

  Future<List<int>> createNewBookings(List<BookingsModel> bookings) async {
    if (bookings.isEmpty) {
      throw ArgumentError('At least one booking is required.');
    }
    final request = bookings.map((booking) {
      final json = booking.toJson()..remove('id');
      return json;
    }).toList();
    try {
      final response = await supabaseClient
          .from(DatabaseSchema.bookingsTable)
          .insert(request)
          .select(DatabaseSchema.bookingsId);
      return response
          .map<int>((row) => (row[DatabaseSchema.bookingsId] as num).toInt())
          .toList();
    } on Exception catch (e) {
      print('Error creating bookings: $e');
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(
    int bookingID,
    String? bookingStatus,
    String? paymentStatus,
    String? bookingsPaymentId,
    String? bookingsOrderId,
    String? bookingsSignature,
  ) async {
    if (bookingID > 0) {
      await supabaseClient
          .from(DatabaseSchema.bookingsTable)
          .update({
            DatabaseSchema.bookingsStatus: bookingStatus,
            DatabaseSchema.bookingsPaymentStatus: paymentStatus,
            DatabaseSchema.bookingsPaymentId: bookingsPaymentId,
            DatabaseSchema.bookingsOrderId: bookingsOrderId,
            DatabaseSchema.bookingsSignature: bookingsSignature,
          })
          .eq(DatabaseSchema.bookingsId, bookingID)
          .select();
    }
  }

  Future<CreateRazorPayOrderModel?> callCreateRazorPayOrderSBEdgeFunction(
    int bookingId,
    int userId,
  ) async {
    final response = await Supabase.instance.client.functions.invoke(
      'create-razorpay-order',
      body: {'bookingId': bookingId, 'userId': userId},
    );
    final orderModel = CreateRazorPayOrderModel.fromJson(response.data);
    if (orderModel.hasOrder) {
      print('orderId: ${orderModel.orderId}');
      print('amount: ${orderModel.amount}');
      print('keyId: ${orderModel.keyId}');
    }

    if (orderModel.isExistingOrder) {
      print('Existing order returned');
    }
    return orderModel;
  }

  Future<CreateRazorPayOrderModel?> callCreateRazorPayOrderForBookings({
    required List<int> bookingIds,
    required int userId,
    required bool isBulkAppointment,
    String? bulkAppointmentId,
  }) async {
    try {
      if (bookingIds.isEmpty) {
        throw ArgumentError('At least one booking ID is required.');
      }
      final response = await Supabase.instance.client.functions.invoke(
        'create-razorpay-order',
        body: {
          'bookingIds': bookingIds,
          'userId': userId,
          'isBulkAppointment': isBulkAppointment,
          'bulkAppointmentId': bulkAppointmentId,
        },
      );
      return CreateRazorPayOrderModel.fromJson(response.data);
    } on Exception catch (e) {
      print('Error creating RazorPay order for bookings: $e');
      return null;
    }
  }

  Future<VerifyPaymentResponseModel?> callVerifyRazorPayPaymentForBookings({
    required List<int> bookingIds,
    required int userId,
    required String? razorpayOrderId,
    required String? razorpayPaymentId,
    required String? razorpaySignature,
    String? failureReason,
    int? failureCode,
    String? failureCause,
  }) async {
    final reason = failureReason?.trim();
    final isFailure = reason != null && reason.isNotEmpty;
    try {
      if (bookingIds.isEmpty) {
        throw ArgumentError('At least one booking ID is required.');
      }
      final body = <String, dynamic>{
        'bookingIds': bookingIds,
        'userId': userId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      };
      if (isFailure) {
        body['paymentFailure'] = {
          'code': failureCode,
          'message': reason,
          'reason': failureCause,
        };
      }

      final response = await Supabase.instance.client.functions.invoke(
        'verify-razorpay-payment',
        body: body,
      );
      final data = response.data;
      if (data is! Map) {
        return VerifyPaymentResponseModel(
          success: false,
          error: 'Payment verification returned an invalid response',
        );
      }
      final model = VerifyPaymentResponseModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      if (!isFailure && model.success) {
        await _clearPaymentFailureReason(bookingIds);
      }
      return model;
    } on FunctionException catch (e) {
      print(
        'Error verifying RazorPay payment for bookings: ${e.details ?? e.reasonPhrase}',
      );
      return VerifyPaymentResponseModel(
        success: false,
        error: isFailure ? reason : _functionErrorMessage(e),
      );
    } on Exception catch (e) {
      print('Error verifying RazorPay payment for bookings: $e');
      return VerifyPaymentResponseModel(
        success: false,
        error: isFailure ? reason : e.toString(),
      );
    }
  }

  String _functionErrorMessage(FunctionException e) {
    final details = e.details;
    if (details is Map) {
      final error = details['error'] ?? details['message'];
      if (error != null && error.toString().trim().isNotEmpty) {
        return error.toString();
      }
    }
    return e.reasonPhrase ?? 'Payment verification failed';
  }

  Future<void> deleteUnpaidDraftBookings(List<int> bookingIds) async {
    if (bookingIds.isEmpty) return;
    await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .delete()
        .inFilter(DatabaseSchema.bookingsId, bookingIds)
        .neq(DatabaseSchema.bookingsPaymentStatus, PaymentStatus.paid.name)
        .neq(DatabaseSchema.bookingsPaymentStatus, PaymentStatus.refunded.name)
        .neq(DatabaseSchema.bookingsStatus, BookingStatus.confirmed.name)
        .neq(DatabaseSchema.bookingsStatus, BookingStatus.completed.name)
        .neq(DatabaseSchema.bookingsStatus, BookingStatus.refunded.name);
  }

  Future<void> _clearPaymentFailureReason(List<int> bookingIds) async {
    if (bookingIds.isEmpty) return;
    try {
      await supabaseClient
          .from(DatabaseSchema.bookingsTable)
          .update({DatabaseSchema.bookingsPaymentFailureReason: null})
          .inFilter(DatabaseSchema.bookingsId, bookingIds);
    } catch (e) {
      print('Unable to clear payment failure reason: $e');
    }
  }

  Future<RefundResponseModel> callInitiateRefundEdgeFunction({
    required String bookingId,
    required String doctorId,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'initiate-refund',
        body: {'bookingId': bookingId, 'doctorId': doctorId},
      );

      // This handles the 200 OK success response
      return RefundResponseModel.fromJson(response.data);
    } on FunctionException catch (e) {
      // Supabase throws this for 400, 403, 404, 500 status codes.
      // e.details contains the JSON body we sent from the Deno script.
      if (e.details != null && e.details is Map<String, dynamic>) {
        return RefundResponseModel.fromJson(e.details as Map<String, dynamic>);
      }

      return RefundResponseModel(
        success: false,
        errorMessage: e.reasonPhrase ?? 'A server error occurred.',
      );
    } catch (e) {
      // This catches network drops, timeout issues, or parsing errors
      return RefundResponseModel(
        success: false,
        errorMessage: 'An unexpected network error occurred.',
      );
    }
  }

  Future<DoctorModel?> getDoctorById(int doctorId) async {
    final response = await supabaseClient
        .from(DatabaseSchema.doctorTable)
        .select('*')
        .eq(DatabaseSchema.doctorId, doctorId)
        .limit(1);
    if (response.isNotEmpty) {
      var doctor = DoctorModel.fromJson(response.first);
      doctor?.saveToSecureStorage();
      return doctor;
    } else {
      return null;
    }
  }

  Future<DoctorModel?> getDoctorByUserId(int userId) async {
    if (userId <= 0) return null;
    final response = await supabaseClient
        .from(DatabaseSchema.doctorTable)
        .select('*')
        .eq(DatabaseSchema.doctorUserId, userId)
        .limit(1);
    if (response.isNotEmpty) {
      final doctor = DoctorModel.fromJson(response.first);
      await doctor.saveToSecureStorage();
      return doctor;
    }
    return null;
  }

  Future<UserModelSupabase?> getUserById(int userId) async {
    if (userId <= 0) return null;
    final response = await supabaseClient
        .from(DatabaseSchema.usersTable)
        .select('*')
        .eq(DatabaseSchema.usersId, userId)
        .limit(1);
    if (response.isEmpty) return null;
    return UserModelSupabase.fromJson(response.first);
  }

  Future<void> updateUserName(int userId, String name) async {
    if (userId <= 0 || name.trim().isEmpty) return;
    await supabaseClient
        .from(DatabaseSchema.usersTable)
        .update({DatabaseSchema.userName: name.trim()})
        .eq(DatabaseSchema.usersId, userId);
  }

  Future<void> submitBookingRating(
    int bookingId, {
    required int rating,
    String? comment,
  }) async {
    if (bookingId <= 0 || rating < 1 || rating > 5) return;
    await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .update({
          DatabaseSchema.bookingsRating: rating,
          DatabaseSchema.bookingsRatingComment: comment ?? '',
        })
        .eq(DatabaseSchema.bookingsId, bookingId);
  }

  /// [doctorUserId] must be `doctor.userId` (users.id). Bookings.doctorId
  /// stores the linked user id, not the doctor table primary key.
  Future<Map<String, dynamic>> getDoctorEarningsSummary(
    int doctorUserId,
  ) async {
    if (doctorUserId <= 0) {
      return {
        'todayCount': 0,
        'pendingCount': 0,
        'weekEarnings': 0.0,
        'settledCount': 0,
        'upcomingCount': 0,
        'completedCount': 0,
        'cancelledNoShowCount': 0,
        'totalCount': 0,
      };
    }
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().split('T')[0];

    final response = await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .select(
          '${DatabaseSchema.bookingsDate},'
          '${DatabaseSchema.bookingsStatus},'
          '${DatabaseSchema.bookingsPaymentStatus},'
          '${DatabaseSchema.bookingsPrice},'
          '${DatabaseSchema.bookingsDoctorAmount},'
          '${DatabaseSchema.bookingsTransferStatus}',
        )
        .eq(DatabaseSchema.bookingsDoctorId, doctorUserId);

    final bookings = response;
    String normalizedStatus(Map<String, dynamic> booking) {
      return (booking[DatabaseSchema.bookingsStatus] as String? ?? '')
          .toLowerCase()
          .replaceAll(RegExp(r'[-_\s]'), '');
    }

    final weekBookings = bookings
        .where(
          (booking) =>
              (booking[DatabaseSchema.bookingsDate] as String? ?? '').compareTo(
                weekStartStr,
              ) >=
              0,
        )
        .toList();
    final todayCount = weekBookings
        .where(
          (booking) => (booking[DatabaseSchema.bookingsDate] as String? ?? '')
              .startsWith(today),
        )
        .length;
    final pendingCount = weekBookings.where((booking) {
      final status = normalizedStatus(booking);
      return status == 'confirmed' || status == 'pending';
    }).length;
    final weekEarnings = weekBookings
        .where(
          (booking) =>
              (booking[DatabaseSchema.bookingsPaymentStatus] as String? ?? '')
                  .toLowerCase() ==
              'paid',
        )
        .fold<double>(0, (sum, booking) {
          final doctorAmount = booking[DatabaseSchema.bookingsDoctorAmount];
          final price = booking[DatabaseSchema.bookingsPrice];
          final amount = doctorAmount is num
              ? doctorAmount.toDouble()
              : (price is num ? price.toDouble() * 0.85 : 0.0);
          return sum + amount;
        });
    final settledCount = weekBookings.where((booking) {
      final transferStatus =
          (booking[DatabaseSchema.bookingsTransferStatus] as String? ?? '')
              .toLowerCase();
      return transferStatus == 'processed' || transferStatus == 'settled';
    }).length;
    final upcomingCount = bookings.where((booking) {
      final status = normalizedStatus(booking);
      return status == 'pending' || status == 'confirmed';
    }).length;
    final completedCount = bookings
        .where((booking) => normalizedStatus(booking) == 'completed')
        .length;
    final cancelledNoShowCount = bookings.where((booking) {
      final status = normalizedStatus(booking);
      return status == 'cancelled' ||
          status == 'canceled' ||
          status == 'noshow';
    }).length;

    return {
      'todayCount': todayCount,
      'pendingCount': pendingCount,
      'weekEarnings': weekEarnings,
      'settledCount': settledCount,
      'upcomingCount': upcomingCount,
      'completedCount': completedCount,
      'cancelledNoShowCount': cancelledNoShowCount,
      'totalCount': bookings.length,
    };
  }

  Future<bool> sentNotification(
    int userIdOfDoctor,
    String title,
    String messageBody,
  ) async {
    if (userIdOfDoctor <= 0) return false;
    try {
      var response = await supabaseClient
          .from(DatabaseSchema.usersTable)
          .select(DatabaseSchema.userFirebaseToken)
          .eq(DatabaseSchema.usersId, userIdOfDoctor);
      var firebaseTokenList = response.map((e) => e['firebaseToken']).toList();
      for (final firebaseToken in firebaseTokenList) {
        await notificationService.sendPushNotification(
          firebaseToken,
          title,
          messageBody,
        );
      }
      return true;
    } catch (e) {
      print('Error in send notification: $e');
      return false;
    }
  }
}
