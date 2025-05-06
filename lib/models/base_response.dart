class JokoBaseResponse {
  final String errorCode;
  final String message;
  final bool success;

  JokoBaseResponse({
    this.errorCode = '',
    this.message = '',
    required this.success,
  });

  factory JokoBaseResponse.fromJson(Map<String, dynamic> json) {
    return JokoBaseResponse(
      errorCode: json['errorCode'] ?? '',
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'errorCode': errorCode,
      'message': message,
      'success': success,
    };
  }
}