import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../api.dart' as api;
import '../services/session.dart';

class PayPalService {
  // PayPal Client ID (same as website - sandbox)
  static const String PAYPAL_CLIENT_ID = 'AYJvR4a3Wr32N3bfYSsX1Am18FQhyXVhndhQUT2nmJ4I9GLmcL2kG5wIyt16IQ6EmP4xLj_SZtcdiaXF';

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
      // First, check if the property owner has a PayPal email set
      String? ownerPayPalEmail;
      try {
        final ownerPayPal = await api.getPropertyOwnerPayPalId(propertyId);
        ownerPayPalEmail = ownerPayPal['payPalId'] as String?;

        if (ownerPayPalEmail == null || ownerPayPalEmail.isEmpty || ownerPayPalEmail == 'null') {
          throw Exception(
            'PayPal payment unavailable: The property owner has not set up their PayPal email. '
            'Please contact the property owner to add their PayPal email in their profile settings.'
          );
      }
        print('PayPal Service: Owner PayPal email verified: ${ownerPayPalEmail.isNotEmpty ? "Set" : "Not set"}');
      } catch (e) {
        // If the error is about missing PayPal email, rethrow it
        if (e.toString().contains('PayPal payment unavailable') || 
            e.toString().contains('not set up their PayPal')) {
          rethrow;
        }
        // If API endpoint fails, log but continue - backend will validate
        print('PayPal Service: Warning - Could not verify owner PayPal email: $e');
        print('PayPal Service: Continuing with order creation - backend will validate');
      }

      // Show WebView with PayPal SDK (client-side, like website)
      if (!context.mounted) return null;
      
      return await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _PayPalPaymentDialog(
          reservationId: reservationId,
          propertyId: propertyId,
          amount: amount,
          currency: currency,
          propertyName: propertyName,
          checkIn: checkIn,
          checkOut: checkOut,
          ownerPayPalEmail: ownerPayPalEmail ?? '',
        ),
      );
    } catch (error) {
      print('PayPal payment error: $error');
      rethrow;
    }
  }

  // Generate HTML page with PayPal SDK (similar to website)
  static String _generatePayPalHTML({
    required double amount,
    required String currency,
    required String propertyName,
    required String reservationId,
    required String ownerPayPalEmail,
  }) {
    // Calculate tax (10% like website)
    const taxRate = 0.10;
    final itemTotal = amount * (1 - taxRate);
    final taxTotal = amount * taxRate;

    // Escape strings for JavaScript
    String escapeJS(String str) {
      return str
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll("'", "\\'")
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r');
    }

    final escapedPropertyName = escapeJS(propertyName);
    final escapedReservationId = escapeJS(reservationId);
    final escapedOwnerEmail = escapeJS(ownerPayPalEmail);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script>
    // Set proper origin for postMessage
    if (window.location.protocol === 'about:' || window.location.href === 'about:blank') {
      // This will be fixed by baseUrl, but just in case
      console.log('WebView origin detected, baseUrl should fix this');
    }
    
    // Suppress PayPal SDK warnings for WebView (non-critical)
    window.addEventListener('error', function(e) {
      if (e.message && (
        e.message.includes('Global messaging not needed') ||
        e.message.includes('postMessage')
      )) {
        // Only suppress if it's a known WebView issue
        console.warn('PayPal SDK WebView warning:', e.message);
        // Don't prevent default - let it try to work
      }
    }, true);
    
    // Catch unhandled promise rejections
    window.addEventListener('unhandledrejection', function(e) {
      if (e.reason && e.reason.message && (
        e.reason.message.includes('Global messaging not needed') ||
        e.reason.message.includes('postMessage')
      )) {
        console.warn('PayPal SDK promise rejection (may be non-critical):', e.reason.message);
        // Don't prevent - let PayPal SDK handle it
      }
    });
  </script>
  <script src="https://www.paypal.com/sdk/js?client-id=$PAYPAL_CLIENT_ID&currency=$currency&intent=capture&components=buttons&disable-funding=credit,card" 
          onerror="console.error('Failed to load PayPal SDK script'); document.getElementById('error-message').innerHTML='<div class=\\'error\\'>Failed to load PayPal SDK. Please check your internet connection.</div>';"></script>
  <style>
    body {
      margin: 0;
      padding: 20px;
      font-family: Arial, sans-serif;
      background: #f5f5f5;
    }
    .payment-container {
      max-width: 500px;
      margin: 0 auto;
      background: white;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .payment-details {
      margin-bottom: 20px;
      padding: 15px;
      background: #f8f9fa;
      border-radius: 4px;
    }
    .payment-details h3 {
      margin: 0 0 10px 0;
      color: #333;
    }
    .payment-details p {
      margin: 5px 0;
      color: #666;
    }
    .amount {
      font-size: 24px;
      font-weight: bold;
      color: #0070ba;
      margin: 10px 0;
    }
    #paypal-button-container {
      margin-top: 20px;
    }
    .error {
      color: red;
      padding: 10px;
      background: #ffe6e6;
      border-radius: 4px;
      margin-bottom: 20px;
    }
  </style>
</head>
<body>
  <div class="payment-container">
    <div class="payment-details">
      <h3>$escapedPropertyName</h3>
      <p>Reservation ID: #$escapedReservationId</p>
      <div class="amount">$currency ${amount.toStringAsFixed(2)}</div>
    </div>
    <div id="loading-message" style="padding: 20px; text-align: center; color: #666;">
      Loading PayPal...
    </div>
    <div id="paypal-button-container"></div>
    <div id="error-message"></div>
  </div>

  <script>
    console.log('=== PayPal Payment Page Loaded ===');
    console.log('Page URL:', window.location.href);
    console.log('Document ready state:', document.readyState);
    
    let orderId = null;
    let paypalLoaded = false;
    
    // Test function to verify JavaScript is working
    function testJavaScript() {
      console.log('JavaScript is working!');
      const container = document.getElementById('paypal-button-container');
      if (container) {
        console.log('Button container found');
      } else {
        console.error('Button container NOT found!');
      }
      return true;
    }
    
    // Run test immediately
    testJavaScript();

    // Wait for PayPal SDK to load
    function initPayPal() {
      if (typeof paypal === 'undefined' || typeof paypal.Buttons === 'undefined') {
        console.error('PayPal SDK not loaded or Buttons not available');
        document.getElementById('error-message').innerHTML = 
          '<div class="error">PayPal SDK failed to load. Please check your internet connection.</div>';
        return;
      }

      console.log('PayPal SDK loaded, initializing buttons...');
      paypalLoaded = true;
      
      // Hide loading message
      const loadingMsg = document.getElementById('loading-message');
      if (loadingMsg) {
        loadingMsg.style.display = 'none';
      }

      try {
        paypal.Buttons({
      style: {
        layout: "vertical",
        color: "blue",
        shape: "rect",
        label: "pay",
        height: 50
      },
      createOrder: function(data, actions) {
        console.log('PayPal createOrder called');
        try {
          return actions.order.create({
            purchase_units: [{
            amount: {
              currency_code: "$currency",
              value: "${amount.toStringAsFixed(2)}",
              breakdown: {
                item_total: {
                  currency_code: "$currency",
                  value: "${itemTotal.toStringAsFixed(2)}"
                },
                tax_total: {
                  currency_code: "$currency",
                  value: "${taxTotal.toStringAsFixed(2)}"
                }
              }
            },
            description: "Reservation for $escapedPropertyName",
            reference_id: "reservation-$escapedReservationId",
            payee: {
              email_address: "$escapedOwnerEmail"
            },
            items: [{
              name: "Reservation #$escapedReservationId",
              description: "Stay at $escapedPropertyName",
              unit_amount: {
                currency_code: "$currency",
                value: "${itemTotal.toStringAsFixed(2)}"
              },
              quantity: "1",
              category: "DIGITAL_GOODS"
            }]
          }],
            application_context: {
              shipping_preference: "NO_SHIPPING"
            }
          });
        } catch (err) {
          console.error('Error in createOrder:', err);
          throw err;
        }
      },
      onApprove: function(data, actions) {
        console.log('Payment approved, orderId:', data.orderID);
        orderId = data.orderID;
        
        try {
          // Add timeout wrapper for capture promise (30 seconds max)
          const capturePromise = actions.order.capture();
          const timeoutPromise = new Promise(function(resolve, reject) {
            setTimeout(function() {
              reject(new Error('Payment capture timed out after 30 seconds. Please check your internet connection.'));
            }, 30000);
          });
          
          return Promise.race([capturePromise, timeoutPromise]).then(function(details) {
            console.log('Payment captured successfully:', details);
            
            try {
              // Extract payment details safely
              const paymentData = {
                orderId: details.id || orderId,
                status: 'success',
                payerId: details.payer ? details.payer.payer_id : null,
                transactionId: details.purchase_units && 
                               details.purchase_units[0] && 
                               details.purchase_units[0].payments && 
                               details.purchase_units[0].payments.captures && 
                               details.purchase_units[0].payments.captures[0] ? 
                               details.purchase_units[0].payments.captures[0].id : null
              };
              
              console.log('Sending payment success to Flutter:', paymentData);
              
              // Send success message to Flutter
              callFlutterHandler('paymentSuccess', paymentData);
            } catch (handlerErr) {
              console.error('Error calling Flutter handler:', handlerErr);
              // Try fallback URL scheme
              try {
                window.location.href = 'paypal://success?orderId=' + (details.id || orderId) + '&status=success';
              } catch (urlErr) {
                console.error('Fallback URL also failed:', urlErr);
                document.getElementById('error-message').innerHTML = 
                  '<div class="error">Payment completed but failed to notify app. Please contact support.</div>';
              }
            }
          }).catch(function(err) {
            console.error('Payment capture error:', err);
            const errorMsg = err.message || err.toString() || 'Unknown error';
            document.getElementById('error-message').innerHTML = 
              '<div class="error">Payment capture failed: ' + errorMsg + '</div>';
            
            // Notify Flutter of the error
            try {
              callFlutterHandler('paymentError', { error: errorMsg });
            } catch (handlerErr) {
              console.error('Error notifying Flutter of payment error:', handlerErr);
            }
          });
        } catch (err) {
          console.error('Error in onApprove:', err);
          const errorMsg = err.message || err.toString() || 'Unknown error';
          document.getElementById('error-message').innerHTML = 
            '<div class="error">Payment approval error: ' + errorMsg + '</div>';
          
          try {
            callFlutterHandler('paymentError', { error: errorMsg });
          } catch (handlerErr) {
            console.error('Error notifying Flutter:', handlerErr);
          }
        }
      },
      onError: function(err) {
        console.error('PayPal error:', err);
        document.getElementById('error-message').innerHTML = 
          '<div class="error">Payment error: ' + err.message + '</div>';
        // Send error to Flutter
        callFlutterHandler('paymentError', { error: err.message });
      },
      onCancel: function(data) {
        console.log('Payment cancelled');
        // Send cancel message to Flutter
        callFlutterHandler('paymentCancel', {});
      }
        }).render('#paypal-button-container').then(function() {
          console.log('PayPal buttons rendered successfully');
          const loadingMsg = document.getElementById('loading-message');
          if (loadingMsg) {
            loadingMsg.style.display = 'none';
          }
        }).catch(function(err) {
          console.error('Error rendering PayPal buttons:', err);
          const loadingMsg = document.getElementById('loading-message');
          if (loadingMsg) {
            loadingMsg.style.display = 'none';
          }
          // Only show error if it's not the "Global messaging" warning
          if (!err.message || !err.message.includes('Global messaging not needed')) {
            document.getElementById('error-message').innerHTML = 
              '<div class="error">Failed to load PayPal buttons: ' + err.message + '</div>';
          }
        });
      } catch (err) {
        console.error('Exception initializing PayPal buttons:', err);
        const loadingMsg = document.getElementById('loading-message');
        if (loadingMsg) {
          loadingMsg.style.display = 'none';
        }
        if (!err.message || !err.message.includes('Global messaging not needed')) {
          document.getElementById('error-message').innerHTML = 
            '<div class="error">Failed to initialize PayPal: ' + err.message + '</div>';
        }
      }
    }

    // Wait for PayPal SDK to load
    function checkPayPalSDK() {
      console.log('Checking for PayPal SDK...');
      console.log('typeof paypal:', typeof paypal);
      
      if (typeof paypal !== 'undefined' && typeof paypal.Buttons !== 'undefined') {
        console.log('PayPal SDK found, initializing...');
        initPayPal();
      } else {
        console.log('PayPal SDK not ready yet, waiting...');
        setTimeout(checkPayPalSDK, 500);
      }
    }

    // Start checking when page loads
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', function() {
        console.log('DOM loaded, checking PayPal SDK...');
        checkPayPalSDK();
        // Timeout after 10 seconds
        setTimeout(function() {
          if (!paypalLoaded) {
            console.error('PayPal SDK failed to load after 10 seconds');
            const loadingMsg = document.getElementById('loading-message');
            if (loadingMsg) {
              loadingMsg.style.display = 'none';
            }
            document.getElementById('error-message').innerHTML = 
              '<div class="error">PayPal SDK failed to load. Please check your internet connection and try again.</div>';
          }
        }, 10000);
      });
    } else {
      // DOM already loaded
      console.log('DOM already loaded, checking PayPal SDK...');
      checkPayPalSDK();
      setTimeout(function() {
        if (!paypalLoaded) {
          console.error('PayPal SDK failed to load');
          const loadingMsg = document.getElementById('loading-message');
          if (loadingMsg) {
            loadingMsg.style.display = 'none';
          }
          document.getElementById('error-message').innerHTML = 
            '<div class="error">PayPal SDK failed to load. Please refresh.</div>';
        }
      }, 10000);
    }

    // Helper function to call Flutter handler
    // Uses URL scheme to avoid CSP/eval issues with PayPal's security policy
    function callFlutterHandler(handlerName, data) {
      console.log('Calling Flutter handler:', handlerName, data);
      
      // Check if we're on PayPal's domain (strict CSP)
      const isPayPalDomain = window.location.hostname.includes('paypal.com') || 
                            window.location.hostname.includes('paypalobjects.com');
      
      // Always use URL scheme when on PayPal's domain to avoid CSP issues
      // Also use URL scheme as primary method since it's safer and doesn't use eval
      try {
        if (handlerName === 'paymentSuccess') {
          const orderId = data && data.orderId ? data.orderId : '';
          const payerId = data && data.payerId ? data.payerId : '';
          const transactionId = data && data.transactionId ? data.transactionId : '';
          const url = 'paypal://success?orderId=' + encodeURIComponent(orderId) + 
                     '&status=success' +
                     (payerId ? '&payerId=' + encodeURIComponent(payerId) : '') +
                     (transactionId ? '&transactionId=' + encodeURIComponent(transactionId) : '');
          window.location.href = url;
          console.log('Using URL scheme for payment success');
          return true;
        } else if (handlerName === 'paymentCancel') {
          window.location.href = 'paypal://cancel';
          console.log('Using URL scheme for payment cancel');
          return true;
        } else if (handlerName === 'paymentError') {
          const errorMsg = data && data.error ? encodeURIComponent(data.error) : 'Unknown error';
          window.location.href = 'paypal://error?error=' + errorMsg;
          console.log('Using URL scheme for payment error');
          return true;
        }
      } catch (urlErr) {
        console.error('URL scheme failed:', urlErr);
        // Try JavaScript handler as last resort (only if not on PayPal domain)
        if (!isPayPalDomain) {
          try {
            if (typeof window.flutter_inappwebview !== 'undefined' && 
                typeof window.flutter_inappwebview.callHandler === 'function') {
              window.flutter_inappwebview.callHandler(handlerName, data);
              console.log('Using JavaScript handler as fallback');
              return true;
            }
          } catch (callErr) {
            console.error('JavaScript handler also failed:', callErr);
          }
        }
        return false;
      }
      
      return false;
    }
  </script>
</body>
</html>
''';
  }
}

class _PayPalPaymentDialog extends StatefulWidget {
  final int reservationId;
  final int propertyId;
  final double amount;
  final String currency;
  final String propertyName;
  final String checkIn;
  final String checkOut;
  final String ownerPayPalEmail;

  const _PayPalPaymentDialog({
    required this.reservationId,
    required this.propertyId,
    required this.amount,
    required this.currency,
    required this.propertyName,
    required this.checkIn,
    required this.checkOut,
    required this.ownerPayPalEmail,
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
                          initialData: InAppWebViewInitialData(
                            data: PayPalService._generatePayPalHTML(
                              amount: widget.amount,
                              currency: widget.currency,
                              propertyName: widget.propertyName,
                              reservationId: widget.reservationId.toString(),
                              ownerPayPalEmail: widget.ownerPayPalEmail,
                            ),
                            mimeType: 'text/html',
                            encoding: 'utf-8',
                            baseUrl: WebUri('https://www.paypal.com'),
                          ),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            domStorageEnabled: true,
                            useShouldOverrideUrlLoading: true,
                            useOnLoadResource: true,
                            allowsInlineMediaPlayback: true,
                            mediaPlaybackRequiresUserGesture: false,
                            thirdPartyCookiesEnabled: true,
                            mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                            allowsBackForwardNavigationGestures: false,
                            supportZoom: false,
                          ),
                          onWebViewCreated: (controller) {
                            webViewController = controller;
                            print('PayPal WebView created');
                            
                            // Register JavaScript handlers immediately
                            controller.addJavaScriptHandler(
                              handlerName: 'paymentSuccess',
                              callback: (args) {
                                print('Payment success handler called: $args');
                                if (args.isNotEmpty) {
                                  final data = args[0];
                                  if (data is Map) {
                                    _handlePaymentSuccess(data as Map<String, dynamic>);
                                  } else {
                                    _handlePaymentSuccess({'status': 'success', 'orderId': data.toString()});
                                  }
                                } else {
                                  _handlePaymentSuccess({'status': 'success'});
                                }
                              },
                            );
                            controller.addJavaScriptHandler(
                              handlerName: 'paymentError',
                              callback: (args) {
                                print('Payment error handler called: $args');
                                if (args.isNotEmpty) {
                                  final data = args[0];
                                  if (data is Map) {
                                    _handlePaymentError(data as Map<String, dynamic>);
                                  } else {
                                    _handlePaymentError({'error': data.toString()});
                                  }
                                } else {
                                  _handlePaymentError({'error': 'Unknown error'});
                                }
                              },
                            );
                            controller.addJavaScriptHandler(
                              handlerName: 'paymentCancel',
                              callback: (args) {
                                print('Payment cancel handler called');
                                _handlePaymentCancel();
                              },
                            );
                            print('JavaScript handlers registered');
                          },
                          onLoadStart: (controller, url) {
                            setState(() {
                              _isLoading = true;
                            });
                            print('PayPal WebView loading: $url');
                          },
                          onLoadStop: (controller, url) async {
                            setState(() {
                              _isLoading = false;
                            });
                            print('PayPal WebView loaded: $url');
                            
                            // Only check URL - don't execute JavaScript on PayPal's pages (CSP restrictions)
                            _handleUrlChange(url.toString());
                          },
                          onConsoleMessage: (controller, consoleMessage) {
                            final level = consoleMessage.messageLevel.toString();
                            final message = consoleMessage.message;
                            
                            // Suppress expected errors from PayPal's pages (non-critical)
                            if (message.contains('Content Security Policy') || 
                                message.contains('unsafe-eval') ||
                                message.contains('CSP directive') ||
                                message.contains('CORS policy') ||
                                message.contains('Access-Control-Allow-Origin') ||
                                message.contains('XMLHttpRequest') && message.contains('blocked by CORS')) {
                              // These are expected on PayPal's payment pages - don't show as errors
                              print('PayPal Console [INFO]: Expected warning (CSP/CORS): ${message.substring(0, message.length > 100 ? 100 : message.length)}...');
                              return;
                            }
                            
                            print('PayPal Console [$level]: $message');
                            
                            if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
                              // Only show non-expected errors
                              if (!message.contains('Content Security Policy') && 
                                  !message.contains('unsafe-eval') &&
                                  !message.contains('CSP directive') &&
                                  !message.contains('CORS policy') &&
                                  !message.contains('Access-Control-Allow-Origin')) {
                                print('⚠️ PayPal JavaScript Error: $message');
                                if (mounted) {
                                  setState(() {
                                    if (_errorMessage == null) {
                                      _errorMessage = 'JavaScript Error: $message';
                                    }
                                  });
                                }
                              }
                            }
                          },
                          onReceivedError: (controller, request, error) {
                            setState(() {
                              _isLoading = false;
                              _errorMessage = 'Error loading PayPal: ${error.description}';
                            });
                          },
                          shouldOverrideUrlLoading: (controller, navigationAction) async {
                            final url = navigationAction.request.url.toString();
                            print('PayPal URL navigation: $url');
                            
                            // Handle PayPal success/cancel URLs (custom scheme)
                            if (url.startsWith('paypal://')) {
                              if (url.contains('success')) {
                                final uri = Uri.parse(url);
                                final orderId = uri.queryParameters['orderId'];
                                print('Payment success detected via URL: $orderId');
                                _handlePaymentSuccess({'orderId': orderId ?? 'unknown', 'status': 'success'});
                                return NavigationActionPolicy.CANCEL;
                              } else if (url.contains('cancel')) {
                                print('Payment cancel detected via URL');
                                _handlePaymentCancel();
                                return NavigationActionPolicy.CANCEL;
                              } else if (url.contains('error')) {
                                final uri = Uri.parse(url);
                                final error = uri.queryParameters['error'] ?? 'Unknown error';
                                print('Payment error detected via URL: $error');
                                _handlePaymentError({'error': error});
                                return NavigationActionPolicy.CANCEL;
                              }
                            }
                            
                            // Detect PayPal payment completion via URL patterns
                            // PayPal redirects after successful payment
                            if (url.contains('paypal.com')) {
                              final uri = Uri.parse(url);
                              // Check for success indicators in URL
                              if (uri.queryParameters.containsKey('token') || 
                                  uri.queryParameters.containsKey('PayerID') ||
                                  url.contains('/checkout/') ||
                                  url.contains('/success') ||
                                  url.contains('paymentId=')) {
                                print('PayPal payment completion detected via URL: $url');
                                // Extract order ID from URL if available
                                final token = uri.queryParameters['token'] ?? 
                                            uri.queryParameters['paymentId'] ?? 
                                            uri.queryParameters['PayerID'];
                                if (token != null) {
                                  // Wait a moment for payment to fully process, then notify
                                  Future.delayed(const Duration(seconds: 2), () {
                                    _handlePaymentSuccess({
                                      'orderId': token,
                                      'status': 'success',
                                      'payerId': uri.queryParameters['PayerID']
                                    });
                                  });
                                }
                              }
                            }
                            
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
    // URL changes are handled via JavaScript handlers now
  }

  void _handlePaymentSuccess(Map<String, dynamic> data) async {
    try {
      setState(() {
        _isLoading = true;
        _paymentCompleted = true;
      });

      print('PayPal payment successful: $data');
      print('Updating reservation status to Paid...');

      // Update reservation status to Paid with timeout
      try {
        await api.updateReservationStatus(widget.reservationId, 'Paid')
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                print('Warning: updateReservationStatus timed out after 15 seconds');
                throw TimeoutException('Update reservation status timed out');
              },
            );
        print('Reservation status updated successfully');
      } catch (updateError) {
        print('Error updating reservation status (non-critical): $updateError');
        // Continue even if this fails - payment was already captured by PayPal
      }

      // Send payment success notification with timeout
      try {
        print('Sending payment success notification...');
        await api.paymentSuccess(widget.reservationId)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                print('Warning: paymentSuccess timed out after 15 seconds');
                throw TimeoutException('Payment success notification timed out');
              },
            );
        print('Payment success notification sent');
      } catch (notificationError) {
        print('Error sending payment success notification (non-critical): $notificationError');
        // Continue even if this fails - payment was already captured by PayPal
      }

      if (mounted) {
        print('Closing payment dialog with success status');
        Navigator.pop(context, {
          'status': 'success',
          'orderId': data['orderId'] ?? data['transactionId'],
          'transactionId': data['transactionId'] ?? data['orderId'],
        });
      }
    } catch (error) {
      print('Error processing payment success: $error');
      // Even if backend calls fail, payment was captured by PayPal
      // So we should still close the dialog
      if (mounted) {
        Navigator.pop(context, {
          'status': 'success',
          'orderId': data['orderId'] ?? data['transactionId'],
          'transactionId': data['transactionId'] ?? data['orderId'],
          'warning': 'Payment successful but backend update may have failed. Please check your reservation status.',
        });
      }
    }
  }

  void _handlePaymentError(Map<String, dynamic> data) {
    print('PayPal payment error: $data');
      setState(() {
        _isLoading = false;
      _errorMessage = 'Payment error: ${data['error'] ?? 'Unknown error'}';
        _paymentCompleted = false;
      });
  }

  void _handlePaymentCancel() {
    print('PayPal payment cancelled');
    if (mounted) {
      Navigator.pop(context, {'status': 'cancelled'});
    }
  }
}

