import 'dart:convert';

import 'package:flutter_sanity_client/src/exception.dart';
import 'package:flutter_sanity_client/src/http_client.dart';
import 'package:http/http.dart' as http;

class SanityClient {
  SanityClient({
    required this.projectId,
    required this.dataset,
    this.token,
    this.apiVersion = 'v2023-05-03',
    this.useCdn = true,
    http.BaseClient? client,
  }) {
    _client = client ?? HttpClient(token);
  }

  /// HttpClient used to make requests
  late final http.BaseClient _client;

  /// The project ID of the Sanity.io project.
  final String projectId;

  /// The dataset of the Sanity.io project.
  final String dataset;

  /// Use the Sanity CDN to fetch data.
  final bool useCdn;

  /// The bearer token of the project to use for authentication.
  /// If not set, the client will not send the token in the header.
  final String? token;

  /// Client's version
  final String apiVersion;

  /// Builds a [Uri] for a sanity endpoint.
  Uri _buildUri(String query, {Map<String, dynamic>? params}) {
    final Map<String, dynamic> queryParameters = <String, dynamic>{
      'query': query,
      if (params != null) ...params,
    };
    return Uri(
      scheme: 'https',
      host: '$projectId.${useCdn ? 'apicdn' : 'api'}.sanity.io',
      path: '/$apiVersion/data/query/$dataset',
      queryParameters: queryParameters,
    );
  }

  /// Builds a [Uri] for a sanity endpoint.
  Uri _buildDownloadUri(String name) {
    return Uri(
      scheme: 'https',
      host: 'cdn.sanity.io',
      path: '/files/$projectId/$dataset/$name',
    );
  }

  /// Handles the response from the Sanity API.
  ///
  /// Throws a [BadRequestException], [UnauthorizedException], [FetchDataException]
  /// in case the request did not succeed
  T _returnResponse<T>(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return _decodeResponse<T>(response.body);
      case 400:
        throw BadRequestException(response.body);
      case 401:
      case 403:
        throw UnauthorizedException(response.body);
      case 500:
      default:
        throw FetchDataException(
          'Error occured while communication with server with status code: ${response.statusCode}',
        );
    }
  }

  /// Decodes the Sanity response
  ///
  /// Throws a [FetchDataException] in case decoding the response fails.
  T _decodeResponse<T>(String responseBody) {
    try {
      final responseJson = jsonDecode(responseBody);
      return responseJson['result'] as T;
    } catch (exception) {
      throw FetchDataException('Error occured while decoding response');
    }
  }

  /// Fetches the query from the Sanity API.
  ///
  /// Throws a [SanityException] in case  request fails.
  Future<T> fetch<T extends dynamic>(String query, {Map<String, dynamic>? params}) async {
    final Uri uri = _buildUri(query, params: params);
    final http.Response response = await _client.get(uri);
    return _returnResponse(response);
  }

  String _normalizeFileName(String ref) {
    final List<String> splitList = ref.split('-');

    return '${splitList[1]}.${splitList[2]}';
  }

  /// download file from the Sanity API.
  ///
  /// [ref] - raw file name from Sanity (file-7e79aad1cfd65cfb551dc4749eea79678384ffef-zip)
  ///
  Future<http.Response> download(String ref) async {
    final Uri uri = _buildDownloadUri(_normalizeFileName(ref));

    return await _client.get(uri);
  }
}
