import 'dart:convert';
import 'package:http/http.dart' as http;

/// ShopifyAuthService handles signup and login using Shopify Storefront API.
class ShopifyAuthService {
  final String
  shopUrl; // e.g., "https://your-shop.myshopify.com/api/2025-01/graphql.json"
  final String storefrontAccessToken;

  ShopifyAuthService({
    required this.shopUrl,
    required this.storefrontAccessToken,
  });

  /// Headers required for Storefront API requests
  Map<String, String> get _headers => {
    'X-Shopify-Storefront-Access-Token': storefrontAccessToken,
    'Content-Type': 'application/json',
  };

  /// Customer Signup
  /// [firstName], [lastName], [email], [password] are required.
  /// [phone] (optional) customer phone number.
  /// [acceptsMarketing] (optional) subscribes the customer to email marketing.
  Future<Map<String, dynamic>> signupCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    bool acceptsMarketing = true,
  }) async {
    final phoneField = phone != null ? 'phone: "$phone"' : '';
    final query =
        """
mutation {
  customerCreate(input: {
    firstName: "$firstName"
    lastName: "$lastName"
    email: "$email"
    password: "$password"
    ${phoneField.isNotEmpty ? '$phoneField,' : ''}
    acceptsMarketing: $acceptsMarketing
  }) {
    customer {
      id
      email
      firstName
      lastName
      phone
      acceptsMarketing
    }
    customerUserErrors {
      code
      message
    }
  }
}
""";

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to signup customer: ${response.body}');
    }
  }

  /// Customer Login
  /// Returns accessToken and expiresAt
  Future<Map<String, dynamic>> loginCustomer({
    required String email,
    required String password,
  }) async {
    final query =
        """
mutation {
  customerAccessTokenCreate(input: {
    email: "$email"
    password: "$password"
  }) {
    customerAccessToken {
      accessToken
      expiresAt
    }
    customerUserErrors {
      code
      message
    }
  }
}
""";

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login customer: ${response.body}');
    }
  }

  /// Refresh Access Token
  Future<Map<String, dynamic>> refreshAccessToken({
    required String accessToken,
  }) async {
    final query =
        """
mutation {
  customerAccessTokenRenew(customerAccessToken: "$accessToken") {
    customerAccessToken {
      accessToken
      expiresAt
    }
    customerUserErrors {
      code
      message
    }
  }
}
""";

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to refresh access token: ${response.body}');
    }
  }

  /// Logout Customer
  Future<Map<String, dynamic>> logoutCustomer({
    required String accessToken,
  }) async {
    final query =
        """
mutation {
  customerAccessTokenDelete(customerAccessToken: "$accessToken") {
    deletedAccessToken
    deletedCustomerAccessTokenId
    customerUserErrors {
      code
      message
    }
  }
}
""";

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to logout customer: ${response.body}');
    }
  }

  /// Get Customer Info
  Future<Map<String, dynamic>> getCustomerInfo({
    required String accessToken,
  }) async {
    final query =
        """
query {
  customer(customerAccessToken: "$accessToken") {
    id
    email
    firstName
    lastName
    phone
    acceptsMarketing
    createdAt
    updatedAt
    defaultAddress {
      id
      address1
      address2
      city
      province
      country
      zip
    }
  }
}
""";

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get customer info: ${response.body}');
    }
  }

  /// Update Customer Phone Number
  Future<Map<String, dynamic>> customerUpdatePhone({
    required String accessToken,
    required String phone,
  }) async {
    final query =
        '''
    mutation {
      customerUpdate(customerAccessToken: "$accessToken", customer: { phone: "$phone" }) {
        customer { 
          id 
          phone 
        }
        customerUserErrors { 
          field 
          message 
        }
      }
    }
    ''';

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('customerUpdate phone failed: ${response.body}');
    }
  }

  /// Customer Password Recovery
  /// Sends a password recovery email to the customer
  Future<Map<String, dynamic>> customerRecover({required String email}) async {
    const query = r'''
      mutation customerRecover($email: String!) {
        customerRecover(email: $email) {
          customerUserErrors { field message }
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({
        'query': query,
        'variables': {'email': email},
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('customerRecover failed: ${response.body}');
    }
  }

  /// Customer Password Reset by URL
  /// Resets password using the reset URL from the recovery email
  Future<Map<String, dynamic>> customerResetByUrl({
    required String resetUrl,
    required String newPassword,
  }) async {
    const query = r'''
      mutation customerResetByUrl($resetUrl: URL!, $password: String!) {
        customerResetByUrl(resetUrl: $resetUrl, password: $password) {
          customer { id }
          customerUserErrors { field message }
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({
        'query': query,
        'variables': {'resetUrl': resetUrl, 'password': newPassword},
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('customerResetByUrl failed: ${response.body}');
    }
  }

  /// Create Customer Address
  Future<Map<String, dynamic>> customerAddressCreate({
    required String accessToken,
    required Map<String, dynamic>
    address, // {city, address1, phone, country, ...}
  }) async {
    // Build address fields dynamically
    final fields = address.entries
        .map((e) => '${e.key}: "${e.value}"')
        .join('\n      ');

    final query =
        '''
    mutation {
      customerAddressCreate(customerAccessToken: "$accessToken", address: { 
        $fields
      }) {
        customerAddress { 
          id 
          city 
          phone 
          address1 
          country 
        }
        customerUserErrors { 
          field 
          message 
        }
      }
    }
    ''';

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('customerAddressCreate failed: ${response.body}');
    }
  }
}
