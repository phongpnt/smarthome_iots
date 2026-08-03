import 'package:smart_home_app/src/model/data/account.dart';
import 'package:smart_home_app/src/repository/iaccount_responsitory.dart';
import 'package:smart_home_app/src/service/base_service.dart';
import 'package:smart_home_app/src/service/local_storage.dart';
import 'package:smart_home_app/src/service/network/account_rest_api.dart';

class AccountResponsitory extends IAccountResponsitory {
  final BaseService baseService;
  final LocalStorage localStorage;
  final AccountRestAPI accountRestAPI;

  AccountResponsitory({
    required this.accountRestAPI,
    required this.baseService,
    required this.localStorage,
  });

  @override
  Future<Account> getProfile() async {
    try {
      final result =
          await accountRestAPI.getProfileByID(localStorage.email, {});
      return Account.fromJson(result.json!);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> login({required String email, required String pass}) async {
    try {
      final result = await baseService.dio
          .post('/login/token', data: {"id": email, "pass": pass});
      return result.data;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateProfile() {
    throw UnimplementedError();
  }

  @override
  Future<void> createAccount() {
    throw UnimplementedError();
  }

  @override
  Future<Account> register(
      String fullname, String email, String password) async {
    try {
      final now = DateTime.now();
      final result = await accountRestAPI.createAccount({
        "userId": email,
        "passKey": password,
        "fullName": fullname,
        "createdDate": DateTime.now().toUtc().toIso8601String(),
        "email": email,
        "active": true,
        "lastLogin": DateTime.now().toUtc().toIso8601String(),
      });
      return Account.fromJson(result.json ?? {});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await baseService.dio.post('/api/Accounts/forgot/$email');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email, String password, String otp) async {
    try {
      await baseService.dio.post('/api/Accounts/reset/$email',
          data: {'otPs': otp, 'newPass': password});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> verifyOTP(String email, String otp) async {
    try {
      final result = await baseService.dio.post(
          '/api/Accounts/verifyOTP/$email',
          queryParameters: {'otp': otp});
      if (result.statusCode != 200) {
        throw Exception();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateAccount(Account account) async {
    try {
      final result = await baseService.dio
          .put('/api/Accounts/${account.userId}', data: account.toJson());
      if (result.statusCode != 200) {
        throw Exception();
      }
    } catch (e) {
      rethrow;
    }
  }
}
