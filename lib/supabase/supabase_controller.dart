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

  Future<List<BookingsModel>> getUpComingBookings(int userId) async {
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final response = await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .select('*')
        .eq(DatabaseSchema.bookingsUserId, userId)
        .gte(DatabaseSchema.bookingsDate, today)
        .order(DatabaseSchema.bookingsId, ascending: true);
    var bookingList = BookingsModel.fromJsonList(response);
    return bookingList;
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
      response = await supabaseClient
          .from(DatabaseSchema.bookingsTable)
          .select('*')
          // .eq(DatabaseSchema.bookingsDoctorId, userId)
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
        .eq(DatabaseSchema.serviceAreasIsActive, true);
    // .order(DatabaseSchema.serviceAreasOrderBy, ascending: true);
    return AreaModel.fromJsonList(response);
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

    final response = await supabaseClient
        .from(DatabaseSchema.doctorTable)
        .select('*')
        .inFilter(DatabaseSchema.doctorId, doctorIds)
        .eq('isActive', true);

    return DoctorModel.fromJsonList(response);
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
        .select('timeSlotId')
        .eq(DatabaseSchema.bookingsDoctorId, doctorUserId)
        .eq(DatabaseSchema.bookingsDate, formattedDate);

    var bookedTimeslotList = bookingsResponse
        .map((e) => e['timeSlotId'])
        .toList();
    for (var timeSlot in timeSlotList) {
      if (bookedTimeslotList.contains(timeSlot.id)) {
        timeSlot.isBooked = true;
      }
    }

    return timeSlotList;
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

  Future<VerifyPaymentResponseModel?> callVerifyRazorPayPaymentSBEdgeFunction({
    required String?
    bookingId, // Use int if your app uses int, but your JSON showed String "92"
    required String?
    userId, // Use int if your app uses int, but your JSON showed String "5"
    required String? razorpayOrderId,
    required String? razorpayPaymentId,
    required String? razorpaySignature,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'verify-razorpay-payment',
        body: {
          'bookingId': bookingId,
          'userId': userId,
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );

      final verifyModel = VerifyPaymentResponseModel.fromJson(response.data);

      if (verifyModel.success) {
        print('Payment Verified! Message: ${verifyModel.message}');

        if (verifyModel.transferId != null) {
          print('Transfer ID: ${verifyModel.transferId}');
          print('Transfer Status: ${verifyModel.transferStatus}');
        }

        if (verifyModel.alreadyPaid) {
          print('Note: This booking was already marked as paid previously.');
        }
      } else {
        print('Verification returned false. Error: ${verifyModel.error}');
      }

      return verifyModel;
    } on FunctionException catch (e) {
      // Supabase throws this if the Edge Function returns a 400 or 500 error
      print('Edge Function Error: ${e.reasonPhrase}');
      print('Error Details: ${e.details}');
      return VerifyPaymentResponseModel(success: false, error: e.reasonPhrase);
    } catch (e) {
      // Catches network or parsing errors
      print('Unexpected Error verifying payment: $e');
      return VerifyPaymentResponseModel(success: false, error: e.toString());
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

  Future<void> sentNotification(
    int userIdOfDoctor,
    String title,
    String messageBody,
  ) async {
    print("${userIdOfDoctor}");
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
    } catch (e) {
      print('Error in send notification: $e');
    }
  }
}
