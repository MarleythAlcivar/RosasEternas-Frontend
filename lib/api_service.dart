import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiHealth {
  const ApiHealth({required this.service, required this.message});

  final String service;
  final String message;

  factory ApiHealth.fromJson(Map<String, dynamic> json) => ApiHealth(
    service: json['service'] as String? ?? 'API Rosas Eternas',
    message: json['message'] as String? ?? 'Respuesta recibida',
  );
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<ApiHealth> health() async {
    final response = await _client
        .get(
          ApiConfig.endpoint('/api/health'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw StateError('La API respondió HTTP ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
      throw const FormatException(
        'La respuesta de la API no tiene el formato esperado.',
      );
    }
    return ApiHealth.fromJson(decoded);
  }

  Future<void> sendDeliveryCapability({
    required String orderId,
    required Map<String, dynamic> context,
  }) async {
    // The image stays on the device. Only minimum delivery metadata is sent.
    final safeContext = <String, dynamic>{
      'locationState': context['locationState'],
      'cameraState': context['cameraState'],
      'locationLabel': context['locationLabel'],
      'photoAttached': context['photoPath'] != null,
      'updatedAt': context['updatedAt'],
    };
    final response = await _client
        .post(
          ApiConfig.endpoint('/api/capability-events'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'orderId': orderId, 'context': safeContext}),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 202) {
      throw StateError('No se pudo registrar el contexto de entrega.');
    }
  }
}
