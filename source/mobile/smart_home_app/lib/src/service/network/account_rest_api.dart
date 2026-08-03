import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';
import 'package:retrofit/retrofit.dart';
import 'package:smart_home_app/src/model/response/base_response.dart';

part 'account_rest_api.g.dart';

@RestApi()
abstract class AccountRestAPI {
  factory AccountRestAPI(Dio dio, {required String baseUrl}) = _AccountRestAPI;

  @POST("/login/token")
  Future<BaseResponse> login(@Body() Map<String, dynamic> body);
  @GET("/api/Accounts")
  Future<BaseResponse> getProfile(@Queries() Map<String, dynamic> queries);
  @GET("/api/Accounts/{id}")
  Future<BaseResponse> getProfileByID(
      @Path() String id, @Queries() Map<String, dynamic> queries);
  @PUT("/api/Accounts/{id}")
  Future<BaseResponse> updateAccount(
      @Path() String id, @Body() Map<String, dynamic> body);
  @POST("/api/Accounts")
  Future<BaseResponse> createAccount(@Body() Map<String, dynamic> body);
  @POST("/api/Accounts/forgot/{id}")
  Future<BaseResponse> forgotPassword(@Path() String id);
  @POST("/api/Accounts/reset/{id}")
  Future<BaseResponse> resetPassword(
      @Path() String id, @Body() Map<String, dynamic> body);
  @POST("/api/Accounts/verifyOTP/{id}")
  Future<BaseResponse> verifyOTP(
      @Path() String id, @Queries() Map<String, dynamic> queries);
}
