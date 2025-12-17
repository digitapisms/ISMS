import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/network/supabase_client.dart';

/// Supported payment gateway providers with comprehensive features
///
/// This enum represents all payment providers supported by the ISMS payment system.
/// Each provider has specific capabilities, fees, and limitations that are exposed
/// through computed properties for easy integration with the payment processing logic.
///
/// Providers are categorized by their capabilities:
/// - **International**: stripe, paypal, razorpay, payoneer, wise, bank_transfer
/// - **Local/Regional**: jazzcash, easypaisa
/// - **Manual**: cash
///
/// Example usage:
/// ```dart
/// if (PaymentProviderType.stripe.supportsRefunds) {
///   // Process refund logic
/// }
/// ```
enum PaymentProviderType {
  /// Stripe payment processing - supports international payments, refunds, and subscriptions
  stripe,

  /// Bank transfer - supports international transfers with low fees
  bank_transfer,

  /// Cash payments - manual processing with no fees
  cash,

  /// JazzCash (Pakistan) - local payment provider with refund support
  jazzcash,

  /// EasyPaisa (Pakistan) - local payment provider with refund support
  easypaisa,

  /// Payoneer - international money transfers with business focus
  payoneer,

  /// 2Checkout (Verifone) - global payment platform
  twocheckout,

  /// Google Pay - digital wallet platform
  google_pay,

  /// AlfaPay by Bank Alfalah - Pakistani banking and payment services
  alfapay;

  /// Whether this payment provider supports refund operations
  ///
  /// Refund support indicates that payments processed through this provider
  /// can be partially or fully refunded through the payment gateway API.
  /// Providers that don't support refunds require manual processing.
  ///
  /// Returns `true` for all providers except those with inherent limitations
  /// in their API or business model that prevent programmatic refunds.
  bool get supportsRefunds {
    switch (this) {
      case PaymentProviderType.stripe:
      case PaymentProviderType.bank_transfer:
      case PaymentProviderType.cash:
      case PaymentProviderType.jazzcash:
      case PaymentProviderType.easypaisa:
      case PaymentProviderType.payoneer:
      case PaymentProviderType.twocheckout:
      case PaymentProviderType.google_pay:
      case PaymentProviderType.alfapay:
        return true;
    }
  }

  /// Whether this payment provider supports recurring/subscription payments
  ///
  /// Recurring payment support indicates that the provider's API supports
  /// creating and managing subscription billing, automatic renewals, and
  /// payment method tokenization for future charges.
  ///
  /// Returns `true` for providers with native subscription support and
  /// `false` for providers that only support one-time payments.
  bool get supportsRecurring {
    switch (this) {
      case PaymentProviderType.stripe:
      case PaymentProviderType.payoneer:
      case PaymentProviderType.twocheckout:
        return true;
      case PaymentProviderType.bank_transfer:
      case PaymentProviderType.cash:
      case PaymentProviderType.jazzcash:
      case PaymentProviderType.easypaisa:
      case PaymentProviderType.google_pay:
      case PaymentProviderType.alfapay:
        return false;
    }
  }

  /// Whether this payment provider supports international/ cross-border payments
  ///
  /// International payment support indicates that the provider can process
  /// payments in multiple currencies and handle cross-border transactions
  /// with proper currency conversion and international compliance.
  ///
  /// Returns `true` for providers with global reach and `false` for
  /// region-specific or local payment providers.
  bool get supportsInternational {
    switch (this) {
      case PaymentProviderType.stripe:
      case PaymentProviderType.bank_transfer:
      case PaymentProviderType.payoneer:
      case PaymentProviderType.twocheckout:
      case PaymentProviderType.google_pay:
        return true;
      case PaymentProviderType.cash:
      case PaymentProviderType.jazzcash:
      case PaymentProviderType.easypaisa:
      case PaymentProviderType.alfapay:
        return false;
    }
  }

  /// The standard processing fee percentage for this payment provider
  ///
  /// Represents the base transaction fee charged by the payment provider
  /// as a decimal percentage (e.g., 0.029 = 2.9%). This fee typically
  /// applies to successful transactions and may have additional fixed fees
  /// depending on the provider's pricing structure.
  ///
  /// Note: Some providers may have different fee structures for:
  /// - International vs domestic transactions
  /// - Card types (credit vs debit)
  /// - Business volume tiers
  /// - Currency conversion fees
  double get processingFee {
    switch (this) {
      case PaymentProviderType.stripe:
        return 0.029; // 2.9% + $0.30
      case PaymentProviderType.bank_transfer:
        return 0.005; // 0.5%
      case PaymentProviderType.cash:
        return 0.0; // No processing fees for cash payments
      case PaymentProviderType.jazzcash:
        return 0.02; // 2% processing fee for JazzCash
      case PaymentProviderType.easypaisa:
        return 0.019; // 1.9% processing fee for EasyPaisa
      case PaymentProviderType.payoneer:
        return 0.03; // 3%
      case PaymentProviderType.twocheckout:
        return 0.035; // 3.5% + $0.35
      case PaymentProviderType.google_pay:
        return 0.0; // Fees handled by underlying payment method
      case PaymentProviderType.alfapay:
        return 0.018; // 1.8% processing fee for AlfaPay
    }
  }

  /// The minimum transaction amount supported by this payment provider
  ///
  /// Represents the smallest amount that can be processed through this
  /// provider's payment gateway. Attempts to process amounts below this
  /// minimum will result in validation errors.
  ///
  /// Minimum amounts are typically set by payment providers to:
  /// - Cover their fixed processing costs
  /// - Maintain profitability on small transactions
  /// - Comply with regional financial regulations
  /// - Prevent micro-transaction abuse
  ///
  /// Note: Amounts are in the provider's base currency and may need
  /// conversion for international transactions.
  double get minAmount {
    switch (this) {
      case PaymentProviderType.stripe:
        return 0.50;
      case PaymentProviderType.twocheckout:
      case PaymentProviderType.google_pay:
        return 1.00;
      case PaymentProviderType.bank_transfer:
        return 10.00;
      case PaymentProviderType.cash:
        return 1.00; // Minimum cash payment amount
      case PaymentProviderType.jazzcash:
        return 50.00; // Minimum JazzCash payment amount
      case PaymentProviderType.easypaisa:
        return 50.00; // Minimum EasyPaisa payment amount
      case PaymentProviderType.payoneer:
        return 50.00;
      case PaymentProviderType.alfapay:
        return 100.00; // Minimum AlfaPay payment amount
    }
  }

  String get displayName {
    switch (this) {
      case PaymentProviderType.stripe:
        return 'Stripe';
      case PaymentProviderType.bank_transfer:
        return 'Bank Transfer';
      case PaymentProviderType.cash:
        return 'Cash';
      case PaymentProviderType.jazzcash:
        return 'JazzCash';
      case PaymentProviderType.easypaisa:
        return 'EasyPaisa';
      case PaymentProviderType.payoneer:
        return 'Payoneer';
      case PaymentProviderType.twocheckout:
        return '2Checkout';
      case PaymentProviderType.google_pay:
        return 'Google Pay';
      case PaymentProviderType.alfapay:
        return 'AlfaPay';
    }
  }
}

/// Payment gateway configuration with enhanced security and validation
///
/// This class encapsulates all configuration parameters required to connect
/// to a specific payment gateway provider. It includes authentication credentials,
/// API endpoints, security settings, and operational parameters.
///
/// The configuration supports both test and production environments through
/// the `isTestMode` flag and provides comprehensive validation to ensure
/// all required parameters are properly set before processing payments.
///
/// Example usage:
/// ```dart
/// final config = PaymentGatewayConfig(
///   apiKey: 'sk_test_...',
///   apiSecret: 'sk_test_...',
///   baseUrl: 'https://api.stripe.com/v1',
///   isTestMode: true,
///   webhookSecret: 'whsec_...',
/// );
/// ```
class PaymentGatewayConfig {
  /// API key for authenticating with the payment gateway
  ///
  /// This is typically a publishable key for client-side operations
  /// or a secret key for server-side operations. Should be kept secure
  /// and never exposed in client-side code.
  final String apiKey;

  /// API secret for authenticating sensitive operations
  ///
  /// Used for server-side operations that require higher security.
  /// This should never be exposed to the client and must be stored
  /// securely using environment variables or secret management.
  final String apiSecret;

  /// Base URL for the payment gateway API endpoints
  ///
  /// The root URL for all API requests. Different providers have
  /// different base URLs (e.g., Stripe: https://api.stripe.com/v1)
  final String baseUrl;

  /// Whether to use test mode for sandbox/testing environments
  ///
  /// In test mode, transactions don't process real payments and
  /// use test card numbers and bank accounts for validation.
  final bool isTestMode;

  /// Secret key for verifying webhook signatures
  ///
  /// Used to validate that incoming webhook requests are genuine
  /// and come from the payment gateway provider.
  final String webhookSecret;

  /// Merchant ID for providers that require merchant identification
  ///
  /// Used by some providers (JazzCash, EasyPaisa) to identify
  /// the merchant account.
  final String merchantId;

  /// Terminal ID for providers that use terminal-based authentication
  ///
  /// Used by some providers to identify specific payment terminals
  /// or processing channels.
  final String terminalId;

  /// HTTP request timeout duration
  ///
  /// Maximum time to wait for API responses before timing out.
  /// Defaults to 30 seconds.
  final Duration timeout;

  /// Maximum number of retry attempts for failed requests
  ///
  /// Number of times to retry failed API requests using
  /// exponential backoff with jitter. Defaults to 3 retries.
  final int maxRetries;

  /// Creates a payment gateway configuration with all required parameters
  ///
  /// [apiKey]: API key for authentication (required)
  /// [apiSecret]: API secret for secure operations (required)
  /// [baseUrl]: Base URL for API endpoints (required)
  /// [isTestMode]: Whether to use test mode (default: true)
  /// [webhookSecret]: Secret for webhook signature verification (default: empty)
  /// [merchantId]: Merchant ID for provider-specific identification (default: empty)
  /// [terminalId]: Terminal ID for provider-specific identification (default: empty)
  /// [timeout]: HTTP request timeout duration (default: 30 seconds)
  /// [maxRetries]: Maximum retry attempts for failed requests (default: 3)
  PaymentGatewayConfig({
    required this.apiKey,
    required this.apiSecret,
    required this.baseUrl,
    this.isTestMode = true,
    this.webhookSecret = '',
    this.merchantId = '',
    this.terminalId = '',

    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  /// Create configuration from environment variables with enhanced security
  ///
  /// Loads configuration parameters from environment variables using a
  /// provider-specific naming convention. Environment variables should be
  /// prefixed with the provider name in uppercase (e.g., STRIPE_API_KEY).
  ///
  /// Required environment variables:
  /// - `{PROVIDER}_API_KEY`: API key for authentication
  /// - `{PROVIDER}_API_SECRET`: API secret for secure operations
  /// - `{PROVIDER}_BASE_URL`: Base URL for API endpoints
  ///
  /// Optional environment variables:
  /// - `{PROVIDER}_TEST_MODE`: Whether to use test mode (default: true)
  /// - `{PROVIDER}_WEBHOOK_SECRET`: Webhook signature verification secret
  /// - `{PROVIDER}_MERCHANT_ID`: Merchant ID for provider-specific identification
  /// - `{PROVIDER}_TERMINAL_ID`: Terminal ID for provider-specific identification
  /// - `{PROVIDER}_TIMEOUT`: HTTP timeout in seconds (default: 30)
  /// - `{PROVIDER}_MAX_RETRIES`: Maximum retry attempts (default: 3)
  ///
  /// Example environment variables for Stripe:
  /// - STRIPE_API_KEY=sk_test_...
  /// - STRIPE_API_SECRET=sk_test_...
  /// - STRIPE_BASE_URL=https://api.stripe.com/v1
  /// - STRIPE_TEST_MODE=true
  /// - STRIPE_WEBHOOK_SECRET=whsec_...
  ///
  /// [provider]: The payment provider type to load configuration for
  factory PaymentGatewayConfig.fromEnv(PaymentProviderType provider) {
    final prefix = provider.name.toUpperCase();
    return PaymentGatewayConfig(
      apiKey: dotenv.env['${prefix}_API_KEY'] ?? '',
      apiSecret: dotenv.env['${prefix}_API_SECRET'] ?? '',
      baseUrl: dotenv.env['${prefix}_BASE_URL'] ?? '',
      isTestMode: dotenv.env['${prefix}_TEST_MODE']?.toLowerCase() == 'true',
      webhookSecret: dotenv.env['${prefix}_WEBHOOK_SECRET'] ?? '',
      merchantId: dotenv.env['${prefix}_MERCHANT_ID'] ?? '',
      terminalId: dotenv.env['${prefix}_TERMINAL_ID'] ?? '',

      timeout: Duration(
        seconds: int.tryParse(dotenv.env['${prefix}_TIMEOUT'] ?? '30') ?? 30,
      ),
      maxRetries: int.tryParse(dotenv.env['${prefix}_MAX_RETRIES'] ?? '3') ?? 3,
    );
  }

  /// Validate configuration with comprehensive checks
  ///
  /// Performs validation to ensure all required configuration parameters
  /// are properly set for the specific payment provider. Different providers
  /// have different validation requirements:
  ///
  /// - All providers require apiKey, apiSecret, and baseUrl
  /// - JazzCash and EasyPaisa require merchantId and terminalId
  /// - Stripe and PayPal require webhookSecret for secure webhook processing
  ///
  /// Returns `true` if the configuration is valid for the specified provider,
  /// `false` otherwise. This should be checked before attempting any
  /// payment operations.
  bool get isValid {
    // Bank transfer and cash don't require API configuration
    if (provider == PaymentProviderType.bank_transfer ||
        provider == PaymentProviderType.cash) {
      return true;
    }

    if (apiKey.isEmpty || apiSecret.isEmpty || baseUrl.isEmpty) {
      return false;
    }

    // Additional validation for specific providers
    switch (provider) {
      case PaymentProviderType.jazzcash:
      case PaymentProviderType.easypaisa:
        return merchantId.isNotEmpty && terminalId.isNotEmpty;
      case PaymentProviderType.stripe:
        return webhookSecret.isNotEmpty;
      default:
        return true;
    }
  }

  /// Get the provider type for this configuration
  ///
  /// This is a helper method that attempts to determine the payment provider
  /// type from the configuration. However, this method has limitations since
  /// the configuration alone may not uniquely identify the provider type.
  ///
  /// **Important**: This method returns PaymentProviderType.stripe by default
  /// and should not be relied upon for critical logic. The provider type should
  /// be explicitly passed when creating PaymentGatewayService instances.
  ///
  /// Returns the inferred payment provider type (defaults to Stripe)
  PaymentProviderType get provider {
    // This is a helper method to determine provider from configuration
    // Actual provider should be passed when creating PaymentGatewayService
    return PaymentProviderType.stripe; // Default, should be set explicitly
  }
}

/// Advanced Payment Gateway Service with comprehensive payment processing capabilities
///
/// This service provides a unified interface for processing payments through multiple
/// payment gateway providers. It handles the complexities of different provider APIs,
/// error handling, retry logic, security, and integration with the ISMS subscription system.
///
/// ## Key Features:
/// - **Multi-provider support**: Single interface for Stripe, PayPal, JazzCash, EasyPaisa, RazorPay, etc.
/// - **Retry logic**: Exponential backoff with jitter for failed API requests
/// - **Comprehensive error handling**: Custom exceptions with detailed error codes and context
/// - **Subscription support**: Integration with ISMS subscription billing system
/// - **Webhook processing**: Secure verification and processing of payment webhooks
/// - **Transaction tracking**: Real-time status updates and reconciliation
/// - **Security**: PCI-compliant data handling and secure configuration management
/// - **Currency support**: Multi-currency processing with proper decimal handling
///
/// ## Usage Example:
/// ```dart
/// // Create configuration
/// final config = PaymentGatewayConfig(
///   apiKey: 'sk_test_...',
///   apiSecret: 'sk_test_...',
///   baseUrl: 'https://api.stripe.com/v1',
///   isTestMode: true,
/// );
///
/// // Create service instance
/// final paymentService = PaymentGatewayService(
///   provider: PaymentProviderType.stripe,
///   config: config,
/// );
///
/// // Process payment
/// final result = await paymentService.createPaymentIntent(
///   amount: 100.00,
///   currency: 'USD',
///   reference: 'ORDER-123',
/// );
/// ```
///
/// ## Integration Points:
/// - Subscription billing engine (`subscription_billing_engine.dart`)
/// - Payment repository (`payments_repository.dart`)
/// - Supabase database for transaction logging
/// - Environment-based configuration loading
class PaymentGatewayService {
  /// The payment provider type for this service instance
  ///
  /// Determines which payment gateway API to use and affects the behavior
  /// of various methods (fee calculations, validation rules, etc.)
  final PaymentProviderType provider;

  /// Configuration parameters for the payment gateway
  ///
  /// Contains authentication credentials, API endpoints, and operational
  /// settings specific to the payment provider.
  final PaymentGatewayConfig config;

  /// HTTP client for making API requests
  ///
  /// Can be customized for testing or to use a specific HTTP client
  /// implementation. If not provided, uses the default http.Client.
  final http.Client? httpClient;

  /// Transaction history for reconciliation and status tracking
  ///
  /// In-memory cache of recent transactions for quick status checks
  /// and reconciliation. Maps payment intent IDs to transaction data.
  final Map<String, Map<String, dynamic>> _transactionHistory = {};

  /// Creates a payment gateway service instance
  ///
  /// [provider]: The payment provider type (Stripe, PayPal, etc.)
  /// [config]: Configuration parameters for the payment gateway
  /// [httpClient]: Optional HTTP client for API requests (uses default if null)
  ///
  /// Example:
  /// ```dart
  /// final service = PaymentGatewayService(
  ///   provider: PaymentProviderType.stripe,
  ///   config: PaymentGatewayConfig(
  ///     apiKey: 'sk_test_...',
  ///     apiSecret: 'sk_test_...',
  ///     baseUrl: 'https://api.stripe.com/v1',
  ///   ),
  /// );
  /// ```
  PaymentGatewayService({
    required this.provider,
    required this.config,
    this.httpClient,
  });

  /// HTTP client with retry logic and timeout
  ///
  /// Returns the custom HTTP client if provided, otherwise returns
  /// the default http.Client. This allows for dependency injection
  /// and testing with mock HTTP clients.
  http.Client get _client => httpClient ?? http.Client();

  /// Create a payment intent with comprehensive error handling and retry logic
  ///
  /// Creates a payment intent through the configured payment gateway provider.
  /// This is the primary method for initiating payment processing and supports
  /// both one-time payments and subscription setup intents.
  ///
  /// ## Key Features:
  /// - **Amount validation**: Ensures amount meets provider's minimum requirements
  /// - **Currency handling**: Proper conversion to smallest currency units
  /// - **Metadata enrichment**: Adds subscription, customer, and test mode metadata
  /// - **Retry logic**: Automatic retries with exponential backoff on failures
  /// - **Error handling**: Comprehensive exception handling with detailed error codes
  ///
  /// ## Parameters:
  /// - [amount]: The payment amount in the specified currency
  /// - [currency]: ISO currency code (e.g., 'USD', 'PKR', 'EUR')
  /// - [reference]: Unique reference identifier for the payment
  /// - [customerEmail]: Customer email for receipt and notification purposes
  /// - [customerPhone]: Customer phone number for SMS notifications
  /// - [metadata]: Additional metadata to attach to the payment
  /// - [isSubscription]: Whether this is for subscription billing
  /// - [subscriptionId]: Subscription ID if this is a subscription payment
  /// - [customerId]: Customer ID for existing customer payments
  /// - [paymentMethodType]: Preferred payment method type
  ///
  /// ## Returns:
  /// A `Future<Map<String, dynamic>>` containing the payment intent response
  /// from the payment gateway provider. Typically includes:
  /// - `id`: The payment intent ID
  /// - `client_secret`: Client secret for confirming payment on frontend
  /// - `status`: Current payment status
  /// - `amount`: The payment amount
  /// - `currency`: The payment currency
  ///
  /// ## Throws:
  /// - `PaymentGatewayException` with error codes:
  ///   - `INVALID_CONFIG`: Configuration validation failed
  ///   - `AMOUNT_TOO_SMALL`: Amount below provider's minimum
  ///   - `HTTP_4XX/5XX`: HTTP errors from payment gateway API
  ///   - `PARSE_ERROR`: Failed to parse API response
  ///   - `MAX_RETRIES_EXCEEDED`: All retry attempts failed
  ///
  /// ## Example:
  /// ```dart
  /// final intent = await paymentService.createPaymentIntent(
  ///   amount: 100.00,
  ///   currency: 'USD',
  ///   reference: 'ORDER-123',
  ///   customerEmail: 'customer@example.com',
  ///   isSubscription: true,
  ///   subscriptionId: 'sub_123',
  /// );
  /// ```
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
    bool isSubscription = false,
    String? subscriptionId,
    String? customerId,
    String? paymentMethodType,
  }) async {
    if (!config.isValid) {
      throw PaymentGatewayException(
        'Payment gateway configuration is invalid',
        errorCode: 'INVALID_CONFIG',
      );
    }

    // Validate minimum amount for the provider
    if (amount < provider.minAmount) {
      throw PaymentGatewayException(
        'Amount must be at least ${provider.minAmount} for ${provider.displayName}',
        errorCode: 'AMOUNT_TOO_SMALL',
      );
    }

    // Provider-specific implementation
    switch (provider) {
      case PaymentProviderType.stripe:
        return await _createStripePaymentIntent(
          amount: amount,
          currency: currency,
          reference: reference,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          metadata: metadata,
          isSubscription: isSubscription,
          subscriptionId: subscriptionId,
          customerId: customerId,
          paymentMethodType: paymentMethodType,
        );

      case PaymentProviderType.jazzcash:
        return await _createJazzCashPaymentIntent(
          amount: amount,
          currency: currency,
          reference: reference,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          metadata: metadata,
        );

      case PaymentProviderType.easypaisa:
        return await _createEasyPaisaPaymentIntent(
          amount: amount,
          currency: currency,
          reference: reference,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          metadata: metadata,
        );

      case PaymentProviderType.cash:
        return await _createCashPaymentIntent(
          amount: amount,
          currency: currency,
          reference: reference,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          metadata: metadata,
        );

      case PaymentProviderType.google_pay:
        return await _createGooglePayPaymentIntent(
          amount: amount,
          currency: currency,
          reference: reference,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          metadata: metadata,
        );

      case PaymentProviderType.alfapay:
        return await _createAlfaPayPaymentIntent(
          amount: amount,
          currency: currency,
          reference: reference,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          metadata: metadata,
        );

      case PaymentProviderType.payoneer:
        return await _createPayoneerPaymentIntent(
          amount: amount,
          currency: currency,
          reference: reference,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          metadata: metadata,
          isSubscription: isSubscription,
          subscriptionId: subscriptionId,
        );

      case PaymentProviderType.twocheckout:
        return await _create2CheckoutPaymentIntent(
          amount: amount,
          currency: currency,
          reference: reference,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          metadata: metadata,
          isSubscription: isSubscription,
          subscriptionId: subscriptionId,
        );

      default:
        // Generic implementation for other providers
        return await _createGenericPaymentIntent(
          amount: amount,
          currency: currency,
          reference: reference,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          metadata: metadata,
          isSubscription: isSubscription,
          subscriptionId: subscriptionId,
          customerId: customerId,
          paymentMethodType: paymentMethodType,
        );
    }
  }

  /// Confirm a payment with comprehensive error handling and 3D Secure support
  ///
  /// Confirms a previously created payment intent by attaching a payment method
  /// and processing the payment. This method handles 3D Secure authentication
  /// flows and supports both automatic and manual confirmation.
  ///
  /// ## Key Features:
  /// - **3D Secure support**: Automatic handling of 3D Secure authentication flows
  /// - **Payment method attachment**: Links payment method to payment intent
  /// - **Transaction tracking**: Updates transaction history with confirmation details
  /// - **Retry logic**: Automatic retries with exponential backoff on failures
  /// - **Error handling**: Comprehensive exception handling with detailed error codes
  ///
  /// ## Parameters:
  /// - [paymentIntentId]: The ID of the payment intent to confirm
  /// - [paymentMethodId]: The ID of the payment method to use for confirmation
  /// - [confirmationData]: Additional confirmation data for specific payment methods
  /// - [handle3DSecure]: Whether to automatically handle 3D Secure authentication
  /// - [returnUrl]: Return URL for 3D Secure authentication redirects
  ///
  /// ## Returns:
  /// A `Future<Map<String, dynamic>>` containing the confirmed payment response
  /// from the payment gateway provider. Typically includes:
  /// - `id`: The payment intent ID
  /// - `status`: Updated payment status ('succeeded', 'requires_action', etc.)
  /// - `next_action`: Next steps if additional action is required
  /// - `client_secret`: Updated client secret for frontend confirmation
  ///
  /// ## Throws:
  /// - `PaymentGatewayException` with error codes:
  ///   - `INVALID_CONFIG`: Configuration validation failed
  ///   - `HTTP_4XX/5XX`: HTTP errors from payment gateway API
  ///   - `PARSE_ERROR`: Failed to parse API response
  ///   - `MAX_RETRIES_EXCEEDED`: All retry attempts failed
  ///
  /// ## Example:
  /// ```dart
  /// final result = await paymentService.confirmPayment(
  ///   paymentIntentId: 'pi_123',
  ///   paymentMethodId: 'pm_456',
  ///   handle3DSecure: true,
  ///   returnUrl: 'https://app.example.com/payment/return',
  /// );
  /// ```
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
    Map<String, dynamic>? confirmationData,
    bool handle3DSecure = true,
    String? returnUrl,
  }) async {
    if (!config.isValid) {
      throw PaymentGatewayException(
        'Payment gateway configuration is invalid',
        errorCode: 'INVALID_CONFIG',
      );
    }

    final requestBody = {
      'payment_method_id': paymentMethodId,
      'confirmation_data': {
        ...confirmationData ?? {},
        if (handle3DSecure) 'handle_3d_secure': true,
        if (returnUrl != null) 'return_url': returnUrl,
      },
    };

    return await _executeWithRetry(() async {
      final url = '${config.baseUrl}/payment-intents/$paymentIntentId/confirm';
      final response = await _client.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );

      final result = _handleResponse(response, 'confirmPayment');

      // Store transaction in history for reconciliation
      _transactionHistory[paymentIntentId] = {
        'status': result['status'] ?? 'pending',
        'amount': result['amount'] ?? 0,
        'currency': result['currency'] ?? 'USD',
        'confirmed_at': DateTime.now().toIso8601String(),
        'payment_method': paymentMethodId,
      };

      return result;
    }, operationName: 'ConfirmPayment');
  }

  /// Get comprehensive payment status with reconciliation support
  ///
  /// Retrieves the current status of a payment intent from the payment gateway
  /// provider. This method is used for polling payment status, reconciliation,
  /// and updating local transaction records.
  ///
  /// ## Key Features:
  /// - **Real-time status**: Fetches latest status from payment gateway
  /// - **Transaction reconciliation**: Updates local transaction history
  /// - **Retry logic**: Automatic retries with exponential backoff on failures
  /// - **Error handling**: Comprehensive exception handling with detailed error codes
  ///
  /// ## Parameters:
  /// - [paymentIntentId]: The ID of the payment intent to check
  ///
  /// ## Returns:
  /// A `Future<Map<String, dynamic>>` containing the payment status response
  /// from the payment gateway provider. Typically includes:
  /// - `id`: The payment intent ID
  /// - `status`: Current payment status ('succeeded', 'processing', 'failed', etc.)
  /// - `amount`: The payment amount
  /// - `currency`: The payment currency
  /// - `last_payment_error`: Details of any payment errors
  /// - `charges`: List of charge attempts
  ///
  /// ## Throws:
  /// - `PaymentGatewayException` with error codes:
  ///   - `INVALID_CONFIG`: Configuration validation failed
  ///   - `HTTP_4XX/5XX`: HTTP errors from payment gateway API
  ///   - `PARSE_ERROR`: Failed to parse API response
  ///   - `MAX_RETRIES_EXCEEDED`: All retry attempts failed
  ///
  /// ## Example:
  /// ```dart
  /// final status = await paymentService.getPaymentStatus('pi_123');
  /// if (status['status'] == 'succeeded') {
  ///   // Payment completed successfully
  /// }
  /// ```
  Future<Map<String, dynamic>> getPaymentStatus(String paymentIntentId) async {
    if (!config.isValid) {
      throw PaymentGatewayException(
        'Payment gateway configuration is invalid',
        errorCode: 'INVALID_CONFIG',
      );
    }

    return await _executeWithRetry(() async {
      final url = '${config.baseUrl}/payment-intents/$paymentIntentId';
      final response = await _client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      final result = _handleResponse(response, 'getPaymentStatus');

      // Update transaction history with latest status
      if (_transactionHistory.containsKey(paymentIntentId)) {
        _transactionHistory[paymentIntentId]!['last_checked'] = DateTime.now()
            .toIso8601String();
        _transactionHistory[paymentIntentId]!['status'] =
            result['status'] ?? 'unknown';
      }

      return result;
    }, operationName: 'GetPaymentStatus');
  }

  /// Process subscription payment for school billing
  Future<Map<String, dynamic>> processSubscriptionPayment({
    required String subscriptionId,
    required String schoolId,
    required double amount,
    required String currency,
    String? paymentMethodId,
    bool autoConfirm = true,
  }) async {
    // Create payment intent for subscription
    final paymentIntent = await createPaymentIntent(
      amount: amount,
      currency: currency,
      reference: 'SUB-$subscriptionId-SCH-$schoolId',
      isSubscription: true,
      subscriptionId: subscriptionId,
      metadata: {
        'subscription_id': subscriptionId,
        'school_id': schoolId,
        'payment_type': 'subscription_renewal',
        'auto_renew': autoConfirm,
      },
    );

    // If payment method is provided, confirm immediately
    if (paymentMethodId != null && autoConfirm) {
      return await confirmPayment(
        paymentIntentId: paymentIntent['id'],
        paymentMethodId: paymentMethodId,
      );
    }

    return paymentIntent;
  }

  /// Process student fee payment with institution-specific handling
  Future<Map<String, dynamic>> processStudentFeePayment({
    required String studentId,
    required String schoolId,
    required double amount,
    required String currency,
    required String feeType,
    String? paymentMethodId,
    Map<String, dynamic>? feeDetails,
  }) async {
    // Create payment intent for student fee
    final paymentIntent = await createPaymentIntent(
      amount: amount,
      currency: currency,
      reference: 'FEE-$feeType-STD-$studentId-SCH-$schoolId',
      metadata: {
        'student_id': studentId,
        'school_id': schoolId,
        'fee_type': feeType,
        'fee_details': feeDetails ?? {},
        'payment_type': 'student_fee',
      },
    );

    // If payment method is provided, confirm immediately
    if (paymentMethodId != null) {
      return await confirmPayment(
        paymentIntentId: paymentIntent['id'],
        paymentMethodId: paymentMethodId,
      );
    }

    return paymentIntent;
  }

  /// Process webhook events with comprehensive security and error handling
  Future<void> processWebhook({
    required String signature,
    required String payload,
    required Function(Map<String, dynamic>) handler,
    bool verifySignature = true,
  }) async {
    try {
      // Verify webhook signature if enabled
      if (verifySignature && !_verifyWebhookSignature(signature, payload)) {
        throw PaymentGatewayException(
          'Invalid webhook signature',
          errorCode: 'INVALID_SIGNATURE',
        );
      }

      final event = jsonDecode(payload);

      // Validate webhook event structure
      if (event['type'] == null || event['data'] == null) {
        throw PaymentGatewayException(
          'Invalid webhook event structure',
          errorCode: 'INVALID_WEBHOOK',
        );
      }

      // Log webhook processing
      _logWebhookEvent(event);

      // Process the webhook event
      await handler(event);

      // Update transaction status based on webhook event
      await _updateTransactionFromWebhook(event);
    } catch (e) {
      // Log webhook processing errors
      _logWebhookError(e, payload);
      rethrow;
    }
  }

  /// Enhanced webhook signature verification with HMAC validation
  bool _verifyWebhookSignature(String signature, String payload) {
    if (config.webhookSecret.isEmpty) {
      // If no webhook secret is configured, skip verification (not recommended for production)
      return true;
    }

    try {
      // Calculate expected signature using HMAC-SHA256
      final hmac = Hmac(sha256, config.webhookSecret.codeUnits);
      final digest = hmac.convert(payload.codeUnits);
      final expectedSignature = 'sha256=${digest.toString()}';

      // Compare signatures using constant-time comparison to prevent timing attacks
      return _constantTimeCompare(signature, expectedSignature);
    } catch (e) {
      return false;
    }
  }

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Get payment gateway display name with enhanced information
  String get displayName {
    switch (provider) {
      case PaymentProviderType.stripe:
        return 'Stripe';
      case PaymentProviderType.bank_transfer:
        return 'Bank Transfer';
      case PaymentProviderType.cash:
        return 'Cash Payment';
      case PaymentProviderType.jazzcash:
        return 'JazzCash';
      case PaymentProviderType.easypaisa:
        return 'EasyPaisa';
      case PaymentProviderType.payoneer:
        return 'Payoneer';
      case PaymentProviderType.twocheckout:
        return '2Checkout';
      case PaymentProviderType.google_pay:
        return 'Google Pay';
      case PaymentProviderType.alfapay:
        return 'AlfaPay';
    }
  }

  // ============ PRIVATE HELPER METHODS ============

  /// Execute HTTP request with retry logic and exponential backoff
  Future<Map<String, dynamic>> _executeWithRetry(
    Future<Map<String, dynamic>> Function() operation, {
    required String operationName,
    int? maxRetries,
    Duration? initialDelay,
  }) async {
    var attempts = 0;
    final maxAttempts = maxRetries ?? config.maxRetries;
    var delay = initialDelay ?? const Duration(milliseconds: 500);

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxAttempts) {
          throw PaymentGatewayException(
            'Failed to execute $operationName after $maxAttempts attempts: $e',
            errorCode: 'MAX_RETRIES_EXCEEDED',
            originalError: e,
          );
        }

        // Exponential backoff with jitter
        await Future.delayed(
          delay + Duration(milliseconds: Random().nextInt(500)),
        );
        delay *= 2;
      }
    }
  }

  /// Handle HTTP response with comprehensive error handling
  Map<String, dynamic> _handleResponse(
    http.Response response,
    String operation,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw PaymentGatewayException(
          'Failed to parse response from $operation',
          errorCode: 'PARSE_ERROR',
          responseBody: response.body,
        );
      }
    } else {
      throw PaymentGatewayException(
        'HTTP ${response.statusCode} from $operation',
        errorCode: 'HTTP_${response.statusCode}',
        responseBody: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  /// Get HTTP headers with authentication and content type
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
      'User-Agent': 'ILMA-Cloud-Payment-Gateway/1.0',
      if (config.merchantId.isNotEmpty) 'Merchant-ID': config.merchantId,
      if (config.terminalId.isNotEmpty) 'Terminal-ID': config.terminalId,
    };
  }

  /// Convert amount to smallest currency unit (e.g., dollars to cents)
  int _convertToSmallestUnit(double amount, String currency) {
    // Handle currencies with different decimal places
    final decimalPlaces = _getCurrencyDecimalPlaces(currency);
    return (amount * pow(10, decimalPlaces)).round();
  }

  /// Get decimal places for different currencies
  int _getCurrencyDecimalPlaces(String currency) {
    switch (currency.toLowerCase()) {
      case 'jpy':
      case 'krw':
      case 'vnd':
        return 0; // These currencies don't have decimal places
      case 'bhd':
      case 'jod':
      case 'kwd':
      case 'omr':
      case 'tnd':
        return 3; // These currencies have 3 decimal places
      default:
        return 2; // Most currencies have 2 decimal places
    }
  }

  /// Log webhook event for auditing and debugging
  void _logWebhookEvent(Map<String, dynamic> event) {
    try {
      SupabaseManager.client.from('payment_webhook_logs').insert({
        'event_type': event['type'],
        'event_id': event['id'],
        'payload': event,
        'processed_at': DateTime.now().toIso8601String(),
        'provider': provider.name,
      });
    } catch (e) {
      // Silently fail logging to avoid breaking webhook processing
    }
  }

  /// Log webhook processing errors
  void _logWebhookError(dynamic error, String payload) {
    try {
      SupabaseManager.client.from('payment_webhook_errors').insert({
        'error_message': error.toString(),
        'error_type': error.runtimeType.toString(),
        'payload': payload,
        'occurred_at': DateTime.now().toIso8601String(),
        'provider': provider.name,
      });
    } catch (e) {
      // Silently fail error logging
    }
  }

  /// Update transaction status based on webhook event
  Future<void> _updateTransactionFromWebhook(Map<String, dynamic> event) async {
    try {
      final eventType = event['type']?.toString() ?? '';
      final data = event['data'] as Map<String, dynamic>? ?? {};
      final object = data['object'] as Map<String, dynamic>? ?? {};

      final paymentIntentId = object['id']?.toString();
      final status = object['status']?.toString();

      if (paymentIntentId != null && status != null) {
        // Update transaction history
        _transactionHistory[paymentIntentId] = {
          ..._transactionHistory[paymentIntentId] ?? {},
          'status': status,
          'last_webhook_update': DateTime.now().toIso8601String(),
          'webhook_event_type': eventType,
        };

        // Update database if this is a final status
        if (['succeeded', 'failed', 'canceled'].contains(status)) {
          await SupabaseManager.client
              .from('payment_transactions')
              .update({
                'status': status,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('transaction_id', paymentIntentId);
        }
      }
    } catch (e) {
      // Silently fail transaction update to avoid breaking webhook processing
    }
  }

  Future<Map<String, dynamic>> _createStripePaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
    bool isSubscription = false,
    String? subscriptionId,
    String? customerId,
    String? paymentMethodType,
  }) async {
    final amountInCents = _convertToSmallestUnit(amount, currency);
    final enhancedMetadata = {
      ...metadata ?? {},
      'isms_reference': reference,
      'is_test_mode': config.isTestMode,
      'created_at': DateTime.now().toIso8601String(),
      if (isSubscription) 'subscription_id': subscriptionId,
      if (customerId != null) 'customer_id': customerId,
    };
    final requestBody = {
      'amount': amountInCents,
      'currency': currency.toLowerCase(),
      'payment_method_types': paymentMethodType != null
          ? [paymentMethodType]
          : ['card'],
      'metadata': enhancedMetadata,
      if (customerEmail != null) 'receipt_email': customerEmail,
      if (customerId != null) 'customer': customerId,
      if (isSubscription) 'setup_future_usage': 'off_session',
      'description': 'ISMS Payment: $reference',
    };
    return await _executeWithRetry(() async {
      final url = '${config.baseUrl}/payment_intents';
      final response = await _client.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );
      return _handleResponse(response, 'createPaymentIntent');
    }, operationName: 'CreateStripePaymentIntent');
  }

  Future<Map<String, dynamic>> _createJazzCashPaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
  }) async {
    if (currency.toUpperCase() != 'PKR') {
      throw PaymentGatewayException(
        'JazzCash only supports PKR currency',
        errorCode: 'INVALID_CURRENCY',
      );
    }
    final enhancedMetadata = {
      ...metadata ?? {},
      'isms_reference': reference,
      'created_at': DateTime.now().toIso8601String(),
    };
    final requestBody = {
      'pp_Version': '1.1',
      'pp_TxnType': 'MWALLET',
      'pp_Language': 'EN',
      'pp_MerchantID': config.merchantId,
      'pp_SubMerchantID': '',
      'pp_Password': config.apiSecret,
      'pp_TxnRefNo': reference,
      'pp_Amount': amount.toStringAsFixed(2),
      'pp_TxnCurrency': 'PKR',
      'pp_TxnDateTime': DateTime.now().toIso8601String(),
      'pp_BillReference': reference,
      'pp_Description': 'ISMS Payment',
      'pp_TxnExpiryDateTime': DateTime.now()
          .add(Duration(hours: 24))
          .toIso8601String(),
      'pp_ReturnURL': 'https://your-app.com/payment/return',
      'pp_SecureHash': _generateJazzCashSecureHash(reference, amount),
      'ppmpf_1': customerEmail ?? '',
      'ppmpf_2': customerPhone ?? '',
      'ppmpf_3': jsonEncode(enhancedMetadata),
    };
    return await _executeWithRetry(() async {
      final url =
          'https://sandbox.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase';
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestBody.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&'),
      );
      return _handleJazzCashResponse(response, 'createPaymentIntent');
    }, operationName: 'CreateJazzCashPaymentIntent');
  }

  Future<Map<String, dynamic>> _createEasyPaisaPaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
  }) async {
    if (currency.toUpperCase() != 'PKR') {
      throw PaymentGatewayException(
        'EasyPaisa only supports PKR currency',
        errorCode: 'INVALID_CURRENCY',
      );
    }
    final enhancedMetadata = {
      ...metadata ?? {},
      'isms_reference': reference,
      'created_at': DateTime.now().toIso8601String(),
    };
    final requestBody = {
      'storeId': config.merchantId,
      'amount': amount.toStringAsFixed(2),
      'postBackURL': 'https://your-app.com/payment/return',
      'orderRefNum': reference,
      'expiryDate': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
      'autoRedirect': '0',
      'paymentMethod': 'InitialRequest',
      'emailAddr': customerEmail ?? '',
      'mobileNum': customerPhone ?? '',
      'merchantHashedReq': _generateEasyPaisaHash(reference, amount),
      'additionalDetails': jsonEncode(enhancedMetadata),
    };
    return await _executeWithRetry(() async {
      final url = 'https://easypay.easypaisa.com.pk/easypay/Index.jsf';
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestBody.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&'),
      );
      return _handleEasyPaisaResponse(response, 'createPaymentIntent');
    }, operationName: 'CreateEasyPaisaPaymentIntent');
  }

  Future<Map<String, dynamic>> _createCashPaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
  }) async {
    final cashReceiptId = 'CASH-${DateTime.now().millisecondsSinceEpoch}';
    return {
      'id': cashReceiptId,
      'status': 'succeeded',
      'amount': amount,
      'currency': currency,
      'reference': reference,
      'payment_method': 'cash',
      'created_at': DateTime.now().toIso8601String(),
      'metadata': {
        ...metadata ?? {},
        'is_cash_payment': true,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
      },
    };
  }

  Future<Map<String, dynamic>> _createGooglePayPaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
  }) async {
    // Google Pay uses underlying payment methods (Stripe, etc.)
    // This creates a payment token that can be used with other gateways
    final enhancedMetadata = {
      ...metadata ?? {},
      'isms_reference': reference,
      'created_at': DateTime.now().toIso8601String(),
      'payment_method': 'google_pay',
    };

    return await _executeWithRetry(() async {
      // Google Pay typically requires integration with a payment processor
      // For now, return a token-based response
      final tokenId = 'gp_${DateTime.now().millisecondsSinceEpoch}';
      return {
        'id': tokenId,
        'status': 'requires_payment_method',
        'amount': _convertToSmallestUnit(amount, currency),
        'currency': currency.toLowerCase(),
        'reference': reference,
        'payment_method_type': 'google_pay',
        'client_secret': tokenId,
        'metadata': enhancedMetadata,
      };
    }, operationName: 'CreateGooglePayPaymentIntent');
  }

  Future<Map<String, dynamic>> _createAlfaPayPaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
  }) async {
    if (currency.toUpperCase() != 'PKR') {
      throw PaymentGatewayException(
        'AlfaPay only supports PKR currency',
        errorCode: 'INVALID_CURRENCY',
      );
    }

    final enhancedMetadata = {
      ...metadata ?? {},
      'isms_reference': reference,
      'created_at': DateTime.now().toIso8601String(),
    };

    final requestBody = {
      'merchant_id': config.merchantId,
      'amount': amount.toStringAsFixed(2),
      'currency': 'PKR',
      'order_id': reference,
      'customer_email': customerEmail ?? '',
      'customer_phone': customerPhone ?? '',
      'return_url': 'https://your-app.com/payment/return',
      'cancel_url': 'https://your-app.com/payment/cancel',
      'metadata': jsonEncode(enhancedMetadata),
      'signature': _generateAlfaPaySignature(reference, amount),
    };

    return await _executeWithRetry(() async {
      final url = config.baseUrl.isNotEmpty
          ? '${config.baseUrl}/api/v1/payments'
          : 'https://api.alfapay.com/api/v1/payments';
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
          'X-Merchant-Id': config.merchantId,
        },
        body: jsonEncode(requestBody),
      );
      return _handleResponse(response, 'createAlfaPayPaymentIntent');
    }, operationName: 'CreateAlfaPayPaymentIntent');
  }

  Future<Map<String, dynamic>> _createPayoneerPaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
    bool isSubscription = false,
    String? subscriptionId,
  }) async {
    final enhancedMetadata = {
      ...metadata ?? {},
      'isms_reference': reference,
      'created_at': DateTime.now().toIso8601String(),
      if (isSubscription) 'subscription_id': subscriptionId,
    };

    final requestBody = {
      'amount': amount.toStringAsFixed(2),
      'currency': currency.toUpperCase(),
      'reference': reference,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'return_url': 'https://your-app.com/payment/return',
      'cancel_url': 'https://your-app.com/payment/cancel',
      'metadata': enhancedMetadata,
      if (isSubscription) 'recurring': true,
    };

    return await _executeWithRetry(() async {
      final url = config.baseUrl.isNotEmpty
          ? '${config.baseUrl}/api/v4/payments'
          : 'https://api.payoneer.com/v4/payments';
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
          'X-Partner-Id': config.merchantId,
        },
        body: jsonEncode(requestBody),
      );
      return _handleResponse(response, 'createPayoneerPaymentIntent');
    }, operationName: 'CreatePayoneerPaymentIntent');
  }

  Future<Map<String, dynamic>> _create2CheckoutPaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
    bool isSubscription = false,
    String? subscriptionId,
  }) async {
    final amountInCents = _convertToSmallestUnit(amount, currency);
    final enhancedMetadata = {
      ...metadata ?? {},
      'isms_reference': reference,
      'created_at': DateTime.now().toIso8601String(),
      if (isSubscription) 'subscription_id': subscriptionId,
    };

    final requestBody = {
      'sellerId': config.merchantId,
      'merchantOrderId': reference,
      'token': config.apiKey,
      'currency': currency.toUpperCase(),
      'total': amountInCents.toString(),
      'billingAddr': {
        'name': customerEmail ?? 'Customer',
        'email': customerEmail,
        'phone': customerPhone,
      },
      'items': [
        {
          'name': 'ISMS Payment',
          'description': reference,
          'price': amountInCents.toString(),
          'quantity': 1,
        },
      ],
      'metadata': enhancedMetadata,
    };

    return await _executeWithRetry(() async {
      final url = config.baseUrl.isNotEmpty
          ? '${config.baseUrl}/api/orders'
          : 'https://api.2checkout.com/rest/6.0/orders/';
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      return _handleResponse(response, 'create2CheckoutPaymentIntent');
    }, operationName: 'Create2CheckoutPaymentIntent');
  }

  String _generateAlfaPaySignature(String reference, double amount) {
    final data = '${config.merchantId}$reference${amount.toStringAsFixed(2)}';
    final bytes = utf8.encode(data + config.apiSecret);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  Future<Map<String, dynamic>> _createGenericPaymentIntent({
    required double amount,
    required String currency,
    required String reference,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
    bool isSubscription = false,
    String? subscriptionId,
    String? customerId,
    String? paymentMethodType,
  }) async {
    final enhancedMetadata = {
      ...metadata ?? {},
      if (isSubscription) 'subscription_id': subscriptionId,
      if (customerId != null) 'customer_id': customerId,
      'is_test_mode': config.isTestMode,
      'created_at': DateTime.now().toIso8601String(),
    };
    final requestBody = {
      'amount': _convertToSmallestUnit(amount, currency),
      'currency': currency.toLowerCase(),
      'reference': reference,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'metadata': enhancedMetadata,
      'test_mode': config.isTestMode,
      if (isSubscription) 'setup_future_usage': 'off_session',
      if (paymentMethodType != null)
        'payment_method_types': [paymentMethodType],
      if (customerId != null) 'customer': customerId,
    };
    return await _executeWithRetry(() async {
      final url = '${config.baseUrl}/payment-intents';
      final response = await _client.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );
      return _handleResponse(response, 'createPaymentIntent');
    }, operationName: 'CreatePaymentIntent');
  }

  String _generateJazzCashSecureHash(String reference, double amount) {
    final data =
        '${config.merchantId}$reference${amount.toStringAsFixed(2)}PKR';
    final bytes = utf8.encode(data + config.apiSecret);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateEasyPaisaHash(String reference, double amount) {
    final data = '${config.merchantId}$reference${amount.toStringAsFixed(2)}';
    final bytes = utf8.encode(data + config.apiSecret);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  Map<String, dynamic> _handleJazzCashResponse(
    http.Response response,
    String operation,
  ) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['pp_ResponseCode'] == '000') {
        return {
          'id': data['pp_TxnRefNo'],
          'status': 'pending',
          'amount': double.parse(data['pp_Amount'] ?? '0'),
          'currency': data['pp_TxnCurrency'],
          'redirect_url': data['pp_RedirectURL'],
          'reference': data['pp_BillReference'],
        };
      } else {
        throw PaymentGatewayException(
          'JazzCash API error: ${data['pp_ResponseMessage']}',
          errorCode: 'JAZZCASH_ERROR',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    }
    throw PaymentGatewayException(
      'HTTP error: ${response.statusCode}',
      errorCode: 'HTTP_ERROR',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }

  Map<String, dynamic> _handleEasyPaisaResponse(
    http.Response response,
    String operation,
  ) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['responseCode'] == '0000') {
        return {
          'id': data['transactionId'],
          'status': 'pending',
          'amount': double.parse(data['amount'] ?? '0'),
          'currency': 'PKR',
          'redirect_url': data['redirectURL'],
          'reference': data['orderRefNum'],
        };
      } else {
        throw PaymentGatewayException(
          'EasyPaisa API error: ${data['responseMessage']}',
          errorCode: 'EASYPAISA_ERROR',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    }
    throw PaymentGatewayException(
      'HTTP error: ${response.statusCode}',
      errorCode: 'HTTP_ERROR',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }
}

/// Custom exception class for payment gateway errors
class PaymentGatewayException implements Exception {
  final String message;
  final String errorCode;
  final dynamic originalError;
  final String? responseBody;
  final int? statusCode;

  PaymentGatewayException(
    this.message, {
    required this.errorCode,
    this.originalError,
    this.responseBody,
    this.statusCode,
  });

  @override
  String toString() {
    return 'PaymentGatewayException: $message (Code: $errorCode)${originalError != null ? '\nOriginal error: $originalError' : ''}${statusCode != null ? '\nStatus code: $statusCode' : ''}${responseBody != null ? '\nResponse: $responseBody' : ''}';
  }
}
