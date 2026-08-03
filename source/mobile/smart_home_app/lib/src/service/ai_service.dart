import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/service/base_service.dart';

class AiMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  AiMessage({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
}

class AiService extends GetxService {
  final BaseService baseService;

  AiService({required this.baseService});

  Future<String> query(String question, String userId) async {
    try {
      final res = await baseService.dio.post(
        '/api/aiquery/query',
        data: {'question': question, 'userId': userId},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 90),  // 3 retry × ~15s + AI processing
        ),
      );

      final data = res.data;
      if (res.statusCode == 200 && data is Map) {
        return data['answer']?.toString() ?? _fallback();
      }
      return _fallback();
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          return 'Server phản hồi quá chậm. Vui lòng thử lại sau.';
        case DioExceptionType.receiveTimeout:
          return 'AI đang xử lý mất quá nhiều thời gian. Câu hỏi phức tạp — thử lại sau 10–15 giây.';
        case DioExceptionType.connectionError:
          return 'Không thể kết nối đến server. Kiểm tra lại mạng hoặc backend chưa chạy.';
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          if (status == 401) {
            return 'Phiên đăng nhập hết hạn. Vui lòng đăng xuất và đăng nhập lại.';
          }
          if (status == 404) {
            return 'Tính năng AI chưa được kích hoạt trên server.';
          }
          return 'Tính năng AI tạm thời không khả dụng (lỗi $status).';
        default:
          return _fallback();
      }
    } catch (_) {
      return _fallback();
    }
  }

  String _fallback() =>
      'Tôi chưa thể truy cập dữ liệu lúc này. '
      'Bạn có thể kiểm tra trực tiếp trong tab Usage hoặc thử lại sau.';
}
