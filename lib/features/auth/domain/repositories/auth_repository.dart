// lib/features/auth/data/repositories/auth_repository.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixvalley_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:sixvalley_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/models/register_model.dart';
import 'package:sixvalley_vendor_app/data/model/response/base/api_response.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:sixvalley_vendor_app/utill/app_constants.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class AuthRepository implements AuthRepositoryInterface {
  final DioClient? dioClient;
  final SharedPreferences? sharedPreferences;

  AuthRepository({required this.dioClient, required this.sharedPreferences});

  // ── Vendor login ──────────────────────────────────────────────────────────

  @override
  Future<ApiResponse> login({String? emailAddress, String? password}) async {
    try {
      Response response = await dioClient!.post(
        AppConstants.loginUri,
        data: {'email': emailAddress, 'password': password},
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  // ── Employee login (NEW) ──────────────────────────────────────────────────

  @override
  Future<ApiResponse> employeeLogin(
      {required String email, required String password}) async {
    try {
      Response response = await dioClient!.post(
        AppConstants.employeeLoginUri,
        data: {'email': email, 'password': password},
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getEmployeeProfile() async {
    try {
      Response response = await dioClient!.get(AppConstants.employeeProfileUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<void> saveIsEmployee(bool isEmployee) async {
    await sharedPreferences!.setBool(AppConstants.isEmployeeKey, isEmployee);
  }

  @override
  bool getIsEmployee() {
    return sharedPreferences!.getBool(AppConstants.isEmployeeKey) ?? false;
  }

  @override
  Future<void> saveEmployeeModules(String modulesJson) async {
    await sharedPreferences!
        .setString(AppConstants.employeeModuleKey, modulesJson);
  }

  @override
  String getEmployeeModules() {
    return sharedPreferences!.getString(AppConstants.employeeModuleKey) ?? '{}';
  }

  // ── Token management ──────────────────────────────────────────────────────

  @override
  Future<void> saveUserToken(String token) async {
    dioClient!.token = token;
    dioClient!.dio!.options.headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
    await sharedPreferences!.setString(AppConstants.token, token);
  }

  @override
  String getUserToken() {
    return sharedPreferences!.getString(AppConstants.token) ?? '';
  }

  @override
  bool isLoggedIn() {
    return sharedPreferences!.containsKey(AppConstants.token);
  }

  @override
  Future<bool> clearSharedData() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(AppConstants.topic);
      await FirebaseMessaging.instance
          .unsubscribeFromTopic(AppConstants.maintenanceModeTopic);
    } catch (e) {
      if (kDebugMode) print('FCM unsubscribe error: $e');
    }
    // Clear employee flags too
    await sharedPreferences!.remove(AppConstants.isEmployeeKey);
    await sharedPreferences!.remove(AppConstants.employeeModuleKey);
    return sharedPreferences!.remove(AppConstants.token);
  }

  // ── Other existing methods (unchanged) ────────────────────────────────────

  @override
  Future<ApiResponse> setLanguageCode(String languageCode) async {
    try {
      final response = await dioClient!.post(
        AppConstants.setCurrentLanguageUri,
        data: {'current_language': languageCode, '_method': 'put'},
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> forgotPassword(String identity) async {
    try {
      Response response = await dioClient!.post(
        AppConstants.forgotPasswordUri,
        data: {'identity': identity},
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> resetPassword(String identity, String otp,
      String password, String confirmPassword, String? token) async {
    try {
      Response response = await dioClient!.post(
        AppConstants.resetPasswordUri,
        data: {
          '_method': 'put',
          'identity': identity.trim(),
          'otp': token ?? otp,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> verifyOtp(String identity, String otp) async {
    try {
      Response response = await dioClient!.post(
        AppConstants.verifyOtpUri,
        data: {'identity': identity.trim(), 'otp': otp},
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateToken() async {
    try {
      String? deviceToken = await _getDeviceToken();
      FirebaseMessaging.instance.subscribeToTopic(AppConstants.topic);
      FirebaseMessaging.instance
          .subscribeToTopic(AppConstants.maintenanceModeTopic);
      Response response = await dioClient!.post(
        AppConstants.tokenUri,
        data: {'_method': 'put', 'cm_firebase_token': deviceToken},
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<String?> _getDeviceToken() async {
    String? deviceToken = await FirebaseMessaging.instance.getToken();
    if (kDebugMode && deviceToken != null) print('Device Token: $deviceToken');
    return deviceToken;
  }

  @override
  Future<void> saveUserCredentials(String number, String password) async {
    await sharedPreferences!.setString(AppConstants.userPassword, password);
    await sharedPreferences!.setString(AppConstants.userEmail, number);
  }

  @override
  String getUserEmail() =>
      sharedPreferences!.getString(AppConstants.userEmail) ?? '';

  @override
  String getUserPassword() =>
      sharedPreferences!.getString(AppConstants.userPassword) ?? '';

  @override
  Future<bool> clearUserNumberAndPassword() async {
    await sharedPreferences!.remove(AppConstants.userPassword);
    return await sharedPreferences!.remove(AppConstants.userEmail);
  }

  @override
  Future<ApiResponse> registration(
      XFile? profileImage,
      XFile? shopLogo,
      XFile? shopBanner,
      XFile? secondaryBanner,
      RegisterModel registerModel,
      XFile? tinCertificate) async {
    http.MultipartRequest request = http.MultipartRequest('POST',
        Uri.parse('${AppConstants.baseUrl}${AppConstants.registration}'));
    Future<void> addFile(XFile? file, String field) async {
      if (file == null) return;
      Uint8List bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile(
          field, file.readAsBytes().asStream(), bytes.length,
          filename: basename(file.path)));
    }

    await addFile(profileImage, 'image');
    await addFile(shopLogo, 'logo');
    await addFile(shopBanner, 'banner');
    await addFile(secondaryBanner, 'bottom_banner');
    await addFile(tinCertificate, 'tin_certificate');
    request.fields.addAll({
      'f_name': registerModel.fName!,
      'l_name': registerModel.lName!,
      'phone': registerModel.phone!,
      'email': registerModel.email!,
      'password': registerModel.password!,
      'confirm_password': registerModel.confirmPassword!,
      'shop_name': registerModel.shopName!,
      'shop_address': registerModel.shopAddress!,
      'tax_identification_number': registerModel.businessTin!,
      'tin_expire_date': registerModel.tinExpireDate ?? '',
    });
    http.StreamedResponse response = await request.send();
    var res = await http.Response.fromStream(response);
    try {
      return ApiResponse.withSuccess(Response(
        statusCode: response.statusCode,
        requestOptions: RequestOptions(path: ''),
        statusMessage: response.reasonPhrase,
        data: res.body,
      ));
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> firebaseAuthTokenStore(
      String userInput, String token) async {
    try {
      Response response = await dioClient!.post(
          AppConstants.firebaseAuthTokenStore,
          data: {'identity': userInput, 'token': token});
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> firebaseAuthVerify(
      {required String phoneNumber,
      required String session,
      required String otp,
      required bool isForgetPassword}) async {
    try {
      Response response = await dioClient!.post(AppConstants.firebaseAuthVerify,
          data: {
            'sessionInfo': session,
            'phoneNumber': phoneNumber,
            'code': otp
          });
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> checkVendorExistPhone(
      {required String phoneNumber}) async {
    try {
      Response response = await dioClient!.post(
          AppConstants.checkVendorExistInfoPhone,
          data: {'phone': phoneNumber});
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future add(value) => throw UnimplementedError();
  @override
  Future delete(int id) => throw UnimplementedError();
  @override
  Future get(String id) => throw UnimplementedError();
  @override
  Future getList({int? offset = 1}) => throw UnimplementedError();
  @override
  Future update(Map<String, dynamic> body, int id) =>
      throw UnimplementedError();
}
