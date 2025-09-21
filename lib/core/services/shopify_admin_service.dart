import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

/// ShopifyAdminService handles Admin API requests for metafields and file uploads
class ShopifyAdminService {
  final String
  shopUrl; // e.g., "https://your-shop.myshopify.com/admin/api/2025-01/graphql.json"
  final String adminAccessToken;

  ShopifyAdminService({required this.shopUrl, required this.adminAccessToken});

  /// Headers required for Admin API requests
  Map<String, String> get _headers => {
    'X-Shopify-Access-Token': adminAccessToken,
    'Content-Type': 'application/json',
  };

  /// Upload file to Shopify and get file reference
  Future<String?> uploadFile({
    required File file,
    required String filename,
  }) async {
    try {
      print('📤 Starting file upload process...');
      print('📄 File: ${file.path}');
      print('📏 File size: ${await file.length()} bytes');

      // Step 1: Create staged upload
      const stagedUploadMutation = '''
mutation stagedUploadsCreate(\$input: [StagedUploadInput!]!) {
  stagedUploadsCreate(input: \$input) {
    stagedTargets {
      url
      resourceUrl
      parameters {
        name
        value
      }
    }
    userErrors {
      field
      message
    }
  }
}
''';

      final variables = {
        'input': [
          {
            'resource': 'FILE',
            'filename': filename,
            'mimeType': 'image/jpeg',
            'httpMethod': 'POST',
          },
        ],
      };

      print('🚀 Sending stagedUploadsCreate mutation...');
      print('Variables: $variables');

      final stagedResponse = await http.post(
        Uri.parse(shopUrl),
        headers: _headers,
        body: jsonEncode({
          'query': stagedUploadMutation,
          'variables': variables,
        }),
      );

      print('📡 Staged Upload Response Status: ${stagedResponse.statusCode}');
      print('📥 Staged Upload Response Body: ${stagedResponse.body}');

      if (stagedResponse.statusCode != 200) {
        throw Exception(
          'Failed to create staged upload: ${stagedResponse.body}',
        );
      }

      final stagedData = jsonDecode(stagedResponse.body);

      // Check for GraphQL errors
      if (stagedData['errors'] != null) {
        throw Exception('GraphQL errors: ${stagedData['errors']}');
      }

      // Check for user errors
      final userErrors =
          stagedData['data']?['stagedUploadsCreate']?['userErrors'];
      if (userErrors != null && userErrors.isNotEmpty) {
        throw Exception('User errors: $userErrors');
      }

      final stagedTargets =
          stagedData['data']?['stagedUploadsCreate']?['stagedTargets'];
      if (stagedTargets == null || stagedTargets.isEmpty) {
        throw Exception('No staged targets received');
      }

      final stagedTarget = stagedTargets[0];
      final uploadUrl = stagedTarget['url'];
      final resourceUrl = stagedTarget['resourceUrl'];
      final parameters = stagedTarget['parameters'] as List;

      print('✅ Staged upload created successfully');
      print('🔗 Upload URL: $uploadUrl');
      print('📍 Resource URL: $resourceUrl');

      // Step 2: Upload file to staged URL
      print('📤 Uploading file to staged URL...');
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add parameters from staged upload
      for (final param in parameters) {
        request.fields[param['name']] = param['value'];
        print('📝 Adding field: ${param['name']} = ${param['value']}');
      }

      // Add the file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      print('📎 File added to request');

      final uploadResponse = await request.send();
      print('📡 File Upload Response Status: ${uploadResponse.statusCode}');

      if (uploadResponse.statusCode == 201 ||
          uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 204) {
        print('✅ File uploaded successfully');
        return resourceUrl;
      } else {
        final responseBody = await uploadResponse.stream.bytesToString();
        print('❌ Upload failed: $responseBody');
        throw Exception('Failed to upload file: ${uploadResponse.statusCode}');
      }
    } catch (e) {
      print('💥 Error uploading file: $e');
      return null;
    }
  }

  /// Create file in Shopify after upload to get GID for metafields
  /// [resourceUrl] = URL returned from uploadFile
  /// [filename] = Original filename
  /// [contentType] = File content type (IMAGE, VIDEO, etc.)
  Future<String?> createFileRecord({
    required String resourceUrl,
    required String filename,
    String contentType = 'IMAGE',
  }) async {
    try {
      const fileCreateMutation = '''
mutation fileCreate(\$files: [FileCreateInput!]!) {
  fileCreate(files: \$files) {
    files {
      id
      fileStatus
      alt
      createdAt
    }
    userErrors {
      field
      message
    }
  }
}
''';

      final variables = {
        'files': [
          {
            'originalSource': resourceUrl,
            'contentType': contentType,
            'alt': filename,
          },
        ],
      };

      final response = await http.post(
        Uri.parse(shopUrl),
        headers: _headers,
        body: jsonEncode({'query': fileCreateMutation, 'variables': variables}),
      );

      print('📡 FileCreate Response Status: ${response.statusCode}');
      print('📥 FileCreate Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check for errors
        if (responseData['errors'] != null) {
          print('❌ FileCreate GraphQL Errors: ${responseData['errors']}');
          return null;
        }

        final userErrors = responseData['data']?['fileCreate']?['userErrors'];
        if (userErrors != null && userErrors.isNotEmpty) {
          print('❌ FileCreate User Errors: $userErrors');
          return null;
        }

        final files = responseData['data']?['fileCreate']?['files'];
        if (files != null && files.isNotEmpty) {
          final fileId = files[0]['id'];
          print('✅ File created successfully with ID: $fileId');
          return fileId;
        }
      }

      return null;
    } catch (e) {
      print('Error creating file record: $e');
      return null;
    }
  }

  /// Upload file and create file record in one step
  /// Returns GID that can be used in metafields
  Future<String?> uploadAndCreateFile({
    required File file,
    required String filename,
    String contentType = 'IMAGE',
  }) async {
    try {
      // Step 1: Upload file to staged URL
      final resourceUrl = await uploadFile(file: file, filename: filename);
      if (resourceUrl == null) {
        print('❌ Failed to upload file');
        return null;
      }

      // Step 2: Create file record to get GID
      final fileId = await createFileRecord(
        resourceUrl: resourceUrl,
        filename: filename,
        contentType: contentType,
      );

      return fileId;
    } catch (e) {
      print('Error in uploadAndCreateFile: $e');
      return null;
    }
  }

  // ShopifyAdminService.dart
  Future<bool> isPhoneNumberUsed(String phoneE164) async {
    print('🔍 Checking if phone number is used: $phoneE164');

    const query = r'''
    query customersByPhone($q: String!) {
      customers(first: 1, query: $q) {
        edges { node { id phone email } }
      }
    }
  ''';

    final variables = {'q': 'phone:$phoneE164'};

    final resp = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query, 'variables': variables}),
    );

    print('📡 Phone check response status: ${resp.statusCode}');
    print('📥 Phone check response: ${resp.body}');

    if (resp.statusCode != 200) {
      throw Exception(
        'Admin customersByPhone HTTP ${resp.statusCode}: ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body);
    if (data['errors'] != null) {
      throw Exception('GraphQL errors: ${data['errors']}');
    }

    final edges = data['data']?['customers']?['edges'] as List? ?? [];
    final used = edges.isNotEmpty;
    print('📞 Phone $phoneE164 is ${used ? "USED" : "AVAILABLE"}');
    return used;
  }

  Future<bool> isEmailUsed(String email) async {
    print('🔍 Checking if email is used: $email');

    const query = r'''
    query customersByEmail($q: String!) {
      customers(first: 1, query: $q) {
        edges { node { id phone email } }
      }
    }
  ''';

    final variables = {'q': 'email:$email'};

    final resp = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query, 'variables': variables}),
    );

    print('📡 Email check response status: ${resp.statusCode}');
    print('📥 Email check response: ${resp.body}');

    if (resp.statusCode != 200) {
      throw Exception(
        'Admin customersByEmail HTTP ${resp.statusCode}: ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body);
    if (data['errors'] != null) {
      throw Exception('GraphQL errors: ${data['errors']}');
    }

    final edges = data['data']?['customers']?['edges'] as List? ?? [];
    final used = edges.isNotEmpty;
    print('📧 Email $email is ${used ? "USED" : "AVAILABLE"}');
    return used;
  }

  /// Update customer metafields using metafieldsSet
  /// [customerId] = Shopify GID of the customer (e.g., gid://shopify/Customer/123)
  /// [metafields] = list of metafield maps (namespace, key, type, value)
  Future<Map<String, dynamic>> updateCustomerMetafields({
    required String customerId,
    required List<Map<String, String>> metafields,
  }) async {
    print(
      '🔧 ShopifyAdminService: Updating customer metafields using metafieldsSet',
    );
    print('👤 Customer ID: $customerId');
    print('🔑 Admin token: ${adminAccessToken.substring(0, 10)}...');
    print('🌐 Shop URL: $shopUrl');

    final mutation = '''
      mutation metafieldsSet(\$metafields: [MetafieldsSetInput!]!) {
        metafieldsSet(metafields: \$metafields) {
          metafields { 
            id 
            namespace 
            key 
            type 
            value 
          }
          userErrors {
            field
            message
            code
          }
        }
      }''';

    final variables = {
      'metafields': metafields
          .map(
            (mf) => {
              'ownerId': customerId,
              'namespace': mf['namespace'],
              'key': mf['key'],
              'type': mf['type'],
              'value': mf['value'],
            },
          )
          .toList(),
    };

    print('🚀 Sending metafieldsSet mutation with variables:');
    print('Variables: $variables');

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': mutation, 'variables': variables}),
    );

    print('📡 HTTP Response Status: ${response.statusCode}');
    print('📥 HTTP Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Check for GraphQL errors
      if (responseData['errors'] != null) {
        print('❌ GraphQL Errors: ${responseData['errors']}');
      }

      // Check for metafieldsSet userErrors
      final userErrors = responseData['data']?['metafieldsSet']?['userErrors'];
      if (userErrors != null && userErrors.isNotEmpty) {
        print('❌ MetafieldsSet Errors: $userErrors');
      } else {
        print('✅ MetafieldsSet completed successfully');
      }

      return responseData;
    } else {
      throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Update customer basic information (name, city, etc.) - excludes email and phone
  Future<Map<String, dynamic>> updateCustomerBasicInfo({
    required String customerId,
    String? firstName,
    String? lastName,
    Map<String, String>? metafields,
  }) async {
    print('🔧 ShopifyAdminService: Updating customer basic info');
    print('👤 Customer ID: $customerId');

    final mutation = '''
      mutation customerUpdate(\$input: CustomerInput!) {
        customerUpdate(input: \$input) {
          customer {
            id
            firstName
            lastName
            metafields(first: 10) {
              edges {
                node {
                  id
                  namespace
                  key
                  value
                }
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    ''';

    final input = {
      'id': customerId,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    };

    final variables = {'input': input};

    print('📝 Update data: $input');

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': mutation, 'variables': variables}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Check for GraphQL errors
      if (responseData['errors'] != null) {
        print('❌ GraphQL Errors: ${responseData['errors']}');
        throw Exception('GraphQL Error: ${responseData['errors']}');
      }

      // Check for user errors
      final userErrors = responseData['data']?['customerUpdate']?['userErrors'];
      if (userErrors != null && userErrors.isNotEmpty) {
        print('❌ Customer Update Errors: $userErrors');
        throw Exception('Update Error: ${userErrors[0]['message']}');
      }

      print('✅ Customer basic info updated successfully');

      // If metafields are provided, update them separately
      if (metafields != null && metafields.isNotEmpty) {
        final metafieldsList = metafields.entries
            .map(
              (entry) => {
                'ownerId': customerId,
                'namespace': 'custom',
                'key': entry.key,
                'type': 'single_line_text_field',
                'value': entry.value,
              },
            )
            .toList();

        await updateCustomerMetafields(
          customerId: customerId,
          metafields: metafieldsList.cast<Map<String, String>>(),
        );
      }

      return responseData;
    } else {
      print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
      throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get customer metafields
  Future<Map<String, dynamic>?> getCustomerMetafields(String customerId) async {
    const query = '''
query getCustomerMetafields(\$customerId: ID!) {
  customer(id: \$customerId) {
    id
    metafields(first: 50) {
      edges {
        node {
          id
          namespace
          key
          value
          type
        }
      }
    }
  }
}
''';

    final variables = {'customerId': customerId};

    print('🔍 Getting customer metafields for: $customerId');

    final response = await http.post(
      Uri.parse(shopUrl),
      headers: _headers,
      body: jsonEncode({'query': query, 'variables': variables}),
    );

    print('📡 HTTP Response Status: ${response.statusCode}');
    print('📥 HTTP Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Check for GraphQL errors
      if (responseData['errors'] != null) {
        print('❌ GraphQL Errors: ${responseData['errors']}');
        return null;
      }

      final customerData = responseData['data']?['customer'];
      if (customerData != null) {
        print('✅ Customer metafields retrieved successfully');
        return customerData;
      }
    }

    print('❌ Failed to get customer metafields');
    return null;
  }

  /// Alternative method to get metafields using REST API
  Future<Map<String, dynamic>?> getCustomerMetafieldsRest(
    String customerId,
  ) async {
    try {
      // Extract numeric ID from GraphQL ID
      final numericId = customerId.split('/').last;

      print('🔍 Getting customer metafields via REST API for: $numericId');

      final response = await http.get(
        Uri.parse('$_restUrl/customers/$numericId/metafields.json'),
        headers: {
          'X-Shopify-Access-Token': adminAccessToken,
          'Content-Type': 'application/json',
        },
      );

      print('📡 REST Response Status: ${response.statusCode}');
      print('📥 REST Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final metafields = responseData['metafields'] as List<dynamic>? ?? [];

        // Convert REST format to GraphQL format for consistency
        final edges = metafields
            .map(
              (metafield) => {
                'node': {
                  'id': 'gid://shopify/Metafield/${metafield['id']}',
                  'namespace': metafield['namespace'],
                  'key': metafield['key'],
                  'value': metafield['value'],
                  'type': metafield['type'] ?? 'single_line_text_field',
                },
              },
            )
            .toList();

        return {
          'id': 'gid://shopify/Customer/$numericId',
          'metafields': {'edges': edges},
        };
      } else {
        print('❌ REST API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error in REST API call: $e');
      return null;
    }
  }

  String get _restUrl {
    // Extract shop domain from GraphQL URL
    final uri = Uri.parse(shopUrl);
    final domain = uri.host;
    return 'https://$domain/admin/api/2024-07';
  }

  /// Convert Shopify file GID to actual URL
  Future<String?> getFileUrl(String fileGid) async {
    try {
      print('🔄 Resolving file GID to URL: $fileGid');

      const query = '''
query getFile(\$id: ID!) {
  node(id: \$id) {
    ... on MediaImage {
      id
      image {
        url
        originalSrc
        transformedSrc
      }
      alt
    }
  }
}
''';

      final variables = {'id': fileGid};

      final response = await http.post(
        Uri.parse(shopUrl),
        headers: _headers,
        body: jsonEncode({'query': query, 'variables': variables}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['errors'] != null) {
          print('❌ GraphQL Errors: ${responseData['errors']}');
          return null;
        }

        final nodeData = responseData['data']?['node'];
        if (nodeData != null && nodeData['image'] != null) {
          final imageUrl =
              nodeData['image']['url'] ??
              nodeData['image']['originalSrc'] ??
              nodeData['image']['transformedSrc'];

          print('✅ File URL resolved: $imageUrl');
          return imageUrl;
        }
      }

      print('❌ Failed to resolve file GID to URL');
      return null;
    } catch (e) {
      print('❌ Error resolving file GID: $e');
      return null;
    }
  }

  /// Get customer info with tags using Admin API
  Future<Map<String, dynamic>> getCustomerInfoWithTags({
    required String customerId,
  }) async {
    try {
      print('🔍 Getting customer info with tags from Admin API...');
      print('🆔 Customer ID: $customerId');

      final query =
          '''
query {
  customer(id: "$customerId") {
    id
    email
    firstName
    lastName
    phone
    acceptsMarketing
    createdAt
    updatedAt
    tags
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
''';

      final response = await http.post(
        Uri.parse(shopUrl),
        headers: _headers,
        body: jsonEncode({'query': query}),
      );

      print('📡 Admin API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Admin API Response: $data');
        return data;
      } else {
        print('❌ Failed to get customer info: ${response.body}');
        throw Exception('Failed to get customer info: ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting customer info with tags: $e');
      throw e;
    }
  }
}
