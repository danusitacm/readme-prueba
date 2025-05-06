import 'base_response.dart';

class JokoTokenResponse extends JokoBaseResponse {
  final String secret;
  final int expiration;

  JokoTokenResponse({
    required String errorCode,
    required String message,
    required bool success,
    required this.secret,
    required this.expiration,
  }) : super(errorCode: errorCode, message: message, success: success);

  factory JokoTokenResponse.fromJson(Map<String, dynamic> json) {
    return JokoTokenResponse(
      errorCode: json['errorCode'] ?? '',
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      secret: json['secret'] ?? '',
      expiration: json['expiration'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'secret': secret,
      'expiration': expiration,
    });
    return baseJson;
  }
}