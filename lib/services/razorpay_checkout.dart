import 'dart:convert';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../model/create_razorpay_order_model.dart';

class RazorpayFailureDetails {
  final int? code;
  final String message;
  final String? reason;
  final String? orderId;
  final String? paymentId;

  const RazorpayFailureDetails({
    required this.message,
    this.code,
    this.reason,
    this.orderId,
    this.paymentId,
  });

  bool get cancelledByUser {
    final reasonText = (reason ?? '').toLowerCase();
    final messageText = message.toLowerCase();
    return reasonText.contains('cancel') || messageText.contains('cancel');
  }

  String get title => cancelledByUser ? 'Payment cancelled' : 'Payment failed';

  factory RazorpayFailureDetails.fromResponse(PaymentFailureResponse response) {
    final body = _asMap(response.error) ?? _asMap(response.message);
    final nested = _asMap(body?['error']);
    final error = nested ?? body;
    final metadata = _asMap(error?['metadata']);
    final description = _text(error?['description']);
    final reason = _text(error?['reason']) ?? _text(error?['code']);
    final message = description ??
        _text(response.message) ??
        'Payment could not be completed';

    return RazorpayFailureDetails(
      code: response.code,
      message: message,
      reason: reason,
      orderId: _text(metadata?['order_id']),
      paymentId: _text(metadata?['payment_id']),
    );
  }

  static Map<dynamic, dynamic>? _asMap(dynamic value) {
    if (value is Map) return value;
    if (value is String && value.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return decoded;
      } catch (_) {}
    }
    return null;
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}

class RazorpayCheckout {
  RazorpayCheckout({
    required void Function(PaymentSuccessResponse response) onSuccess,
    required void Function(RazorpayFailureDetails failure) onError,
    void Function(ExternalWalletResponse response)? onExternalWallet,
  }) : _onSuccess = onSuccess,
       _onError = onError,
       _onExternalWallet = onExternalWallet {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _forwardError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _forwardWallet);
  }

  late final Razorpay _razorpay;
  final void Function(PaymentSuccessResponse response) _onSuccess;
  final void Function(RazorpayFailureDetails failure) _onError;
  final void Function(ExternalWalletResponse response)? _onExternalWallet;

  void _forwardError(PaymentFailureResponse response) {
    _onError(RazorpayFailureDetails.fromResponse(response));
  }

  void _forwardWallet(ExternalWalletResponse response) {
    _onExternalWallet?.call(response);
  }

  void open({
    required CreateRazorPayOrderModel order,
    required String description,
    required String contact,
  }) {
    _razorpay.open({
      'key': order.keyId,
      'amount': order.amount,
      'order_id': order.orderId,
      'currency': order.currency,
      'name': 'PhysioConnect',
      'description': description,
      'prefill': {'contact': contact},
      'method': {
        'netbanking': false,
        'wallet': true,
        'upi': true,
        'paylater': false,
        'emi': false,
        'card': true,
      },
      'config': {
        'display': {
          'hide': [
            {'method': 'netbanking'},
            {'method': 'paylater'},
            {'method': 'emi'},
          ],
        },
      },
    });
  }

  void dispose() => _razorpay.clear();
}
