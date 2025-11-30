import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../api.dart' as api;
import '../services/session.dart';

class PayPalService {
  // Get PayPal Client ID from backend (or use environment variable)
  static Future<String?> getPayPalClientId() async {
    try {
      // You can store this in your backend config or environment
      // For now, we'll get it from the backend if available
      // Otherwise, use a default sandbox client ID
      return 'YOUR_PAYPAL_CLIENT_ID'; // Replace with actual client ID or fetch from backend
    } catch (e) {
      print('Error getting PayPal Client ID: $e');
      return null;
    }
  }

  // Show PayPal payment dialog
  static Future<Map<String, dynamic>?> showPayPalPayment({
    required BuildContext context,
    required int reservationId,
    required int propertyId,
    required double amount,
    required String currency,
    required String propertyName,
    required String checkIn,
    required String checkOut,
  }) async {
    try {
      // Create PayPal order via backend
      final orderData = await api.createPayPalOrder(
        reservationId: reservationId,
        propertyId: propertyId,
        amount: amount,
        currency: currency,
      );

      if (orderData['orderId'] == null && orderData['id'] == null) {
        throw Exception('Failed to create PayPal order: No order ID returned. Backend may not be configured for PayPal.');
      }

      final orderId = orderData['orderId'] as String? ?? orderData['id'] as String? ?? '';
      final approvalUrl = orderData['approvalUrl'] as String? ?? 
                         orderData['approval_url'] as String? ??
                         orderData['links']?[0]?['href'] as String? ??
                         '';

      if (approvalUrl.isEmpty) {
        throw Exception('Failed to get PayPal approval URL. Backend may not be configured for PayPal.');
      }

      // Show WebView for PayPal checkout
      if (!context.mounted) return null;
      
      return await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _PayPalPaymentDialog(
          orderId: orderId,
          reservationId: reservationId,
          propertyId: propertyId,
          amount: amount,
          currency: currency,
          propertyName: propertyName,
          checkIn: checkIn,
          checkOut: checkOut,
          approvalUrl: approvalUrl,
        ),
      );
    } catch (error) {
      print('PayPal payment error: $error');
      rethrow;
    }
  }
}

class _PayPalPaymentDialog extends StatefulWidget {
  final String orderId;
  final int reservationId;
  final int propertyId;
  final double amount;
  final String currency;
  final String propertyName;
  final String checkIn;
  final String checkOut;
  final String approvalUrl;

  const _PayPalPaymentDialog({
    required this.orderId,
    required this.reservationId,
    required this.propertyId,
    required this.amount,
    required this.currency,
    required this.propertyName,
    required this.checkIn,
    required this.checkOut,
    required this.approvalUrl,
  });

  @override
  State<_PayPalPaymentDialog> createState() => _PayPalPaymentDialogState();
}

class _PayPalPaymentDialogState extends State<_PayPalPaymentDialog> {
  InAppWebViewController? webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _paymentCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0077B6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PayPal Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_paymentCompleted)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                ],
              ),
            ),
            // Payment Details
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF8F9FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.propertyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check-in: ${widget.checkIn}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  Text(
                    'Check-out: ${widget.checkOut}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF0077B6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _isLoading = true;
                              });
                              webViewController?.reload();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        InAppWebView(
                          initialUrlRequest: URLRequest(
                            url: WebUri(widget.approvalUrl),
                          ),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            domStorageEnabled: true,
                            useShouldOverrideUrlLoading: true,
                            useOnLoadResource: true,
                          ),
                          onWebViewCreated: (controller) {
                            webViewController = controller;
                          },
                          onLoadStart: (controller, url) {
                            setState(() {
                              _isLoading = true;
                            });
                            _handleUrlChange(url.toString());
                          },
                          onLoadStop: (controller, url) async {
                            setState(() {
                              _isLoading = false;
                            });
                            _handleUrlChange(url.toString());
                          },
                          onReceivedError: (controller, request, error) {
                            setState(() {
                              _isLoading = false;
                              _errorMessage = 'Error loading PayPal: ${error.description}';
                            });
                          },
                          shouldOverrideUrlLoading: (controller, navigationAction) async {
                            final url = navigationAction.request.url.toString();
                            _handleUrlChange(url);
                            return NavigationActionPolicy.ALLOW;
                          },
                        ),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUrlChange(String url) {
    print('PayPal URL changed: $url');

    // Check for success/cancel URLs
    if (url.contains('payment/return') || url.contains('payment/cancel') || 
        url.contains('checkoutnow') || url.contains('execute-payment')) {
      // Extract token/PayerID from URL if present
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      final payerId = uri.queryParameters['PayerID'];
      
      if (token != null || payerId != null) {
        // Payment approved, capture the order
        _captureOrder();
      } else if (url.contains('cancel') || url.contains('payment/cancel')) {
        // Payment cancelled
        if (mounted) {
          Navigator.pop(context, {'status': 'cancelled'});
        }
      }
    }
    
    // Also check for PayPal success patterns
    if (url.contains('execute-payment') || url.contains('payment/execute')) {
      _captureOrder();
    }
  }

  Future<void> _captureOrder() async {
    try {
      setState(() {
        _isLoading = true;
        _paymentCompleted = true;
      });

      // Capture the PayPal order
      final result = await api.capturePayPalOrder(
        orderId: widget.orderId,
        reservationId: widget.reservationId,
      );

      // Update reservation status to Paid
      await api.updateReservationStatus(widget.reservationId, 'Paid');

      // Send payment success notification
      await api.paymentSuccess(widget.reservationId);

      if (mounted) {
        Navigator.pop(context, {
          'status': 'success',
          'orderId': result['orderId'],
          'transactionId': result['transactionId'],
        });
      }
    } catch (error) {
      print('Error capturing PayPal order: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Payment failed: ${error.toString()}';
        _paymentCompleted = false;
      });
    }
  }
}

