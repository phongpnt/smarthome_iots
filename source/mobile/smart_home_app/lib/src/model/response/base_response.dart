class BaseResponse {
  final String? message;
  final Map<String, dynamic>? json;

  BaseResponse({this.message, this.json});

  factory BaseResponse.fromJson(Map<String, dynamic> json) => BaseResponse(
        message: json['message'] as String?,
        json: json,
      );

}
