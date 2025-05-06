import 'base_response.dart';

class JokoTokenInfoResponse extends JokoBaseResponse {
  final String audiencie;
  final int expiresIn;
  final String userId;

  JokoTokenInfoResponse({
    required String errorCode,
    required String message,
    required bool success,
    required this.audiencie,
    required this.expiresIn,
    required this.userId,
  }) : super(errorCode: errorCode, message: message, success: success);

  factory JokoTokenInfoResponse.fromJson(Map<String, dynamic> json) {
    return JokoTokenInfoResponse(
      errorCode: json['errorCode'] ?? '',
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      audiencie: json['audiencie'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
      userId: json['userId'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'audiencie': audiencie,
      'expiresIn': expiresIn,
      'userId': userId,
    });
    return baseJson;
  }
}