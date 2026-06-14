// lib/features/auth/domain/services/auth_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_snackbar_widget.dart';
import 'package:sixvalley_vendor_app/data/model/response/base/api_response.dart';
import 'package:sixvalley_vendor_app/data/model/response/base/error_response.dart';
import 'package:sixvalley_vendor_app/data/model/response/response_model.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/models/register_model.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/services/auth_service_interface.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/main.dart';

class AuthService implements AuthServiceInterface {
  final AuthRepositoryInterface authRepoInterface;
  AuthService({required this.authRepoInterface});

  // ── Vendor login ──────────────────────────────────────────────────────────

  @override
  Future<dynamic> login({String? emailAddress, String? password}) async {
    ApiResponse apiResponse = await authRepoInterface.login(
        emailAddress: emailAddress, password: password);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      final token = apiResponse.response!.data['token'];
      await saveUserToken(token);
      // Mark as a regular vendor session (not employee)
      await authRepoInterface.saveIsEmployee(false);
      await authRepoInterface.saveEmployeeModules('{}');
    } else if (apiResponse.error == 'pending') {
      showCustomSnackBarWidget(
          getTranslated('your_account_is_in_review_process', Get.context!),
          Get.context!,
          sanckBarType: SnackBarType.error);
    } else if (apiResponse.error == 'unauthorized') {
      showCustomSnackBarWidget(
          getTranslated('invalid_credential', Get.context!), Get.context!,
          sanckBarType: SnackBarType.error);
    } else {
      showCustomSnackBarWidget(
          getTranslated('account_not_verified_yet', Get.context!), Get.context!,
          sanckBarType: SnackBarType.error);
    }
    return apiResponse;
  }

  // ── Employee login (NEW) ──────────────────────────────────────────────────

  @override
  Future<dynamic> employeeLogin(
      {required String email, required String password}) async {
    ApiResponse apiResponse =
        await authRepoInterface.employeeLogin(email: email, password: password);

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      final token = apiResponse.response!.data['token'];
      // Save token exactly like vendor — the same Dio headers are used for all requests
      await saveUserToken(token);
      // Mark this as an employee session so the app knows to fetch employee profile
      await authRepoInterface.saveIsEmployee(true);
    } else {
      String errorMsg = _extractError(apiResponse);
      showCustomSnackBarWidget(errorMsg, Get.context!,
          sanckBarType: SnackBarType.error);
    }
    return apiResponse;
  }

  /// After employee login, fetch their profile to get module_access.
  /// Saves the modules to SharedPreferences so they survive app restarts.
  @override
  Future<dynamic> fetchAndSaveEmployeeProfile() async {
    ApiResponse apiResponse = await authRepoInterface.getEmployeeProfile();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      final data = apiResponse.response!.data;
      final moduleAccess = data['module_access'];
      if (moduleAccess != null) {
        await authRepoInterface.saveEmployeeModules(jsonEncode(moduleAccess));
      }
      return apiResponse;
    }
    return apiResponse;
  }

  @override
  bool getIsEmployee() => authRepoInterface.getIsEmployee();

  /// Used when the /employee/profile API call fails after a successful
  /// login. Without this, module_access stays '{}' and employeeHasAccess()
  /// returns false for EVERY module — locking the employee out of
  /// everything including the dashboard itself.
  ///
  /// This grants a conservative fallback (dashboard + pos_management,
  /// the two most commonly needed for day-to-day staff operations) so
  /// the app remains usable while the profile-fetch issue is diagnosed.
  @override
  Future<void> saveEmployeeModulesFallback() async {
    await authRepoInterface.saveEmployeeModules(jsonEncode({
      'dashboard': true,
      'order_management': true,
      'pos_management': true,
      'product_management': false,
      'promotion_management': false,
      'coupon_management': false,
      'delivery_man': false,
      'shop_settings': false,
      'chat': false,
    }));
  }

  /// Returns the saved module_access map as Map<String, bool>.
  /// Falls back to all-false if nothing is saved.
  @override
  Map<String, bool> getEmployeeModules() {
    try {
      final raw = authRepoInterface.getEmployeeModules();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value == true));
    } catch (_) {
      return {};
    }
  }

  /// Quick permission check — used throughout the app to show/hide features.
  @override
  bool employeeHasAccess(String module) {
    if (!getIsEmployee()) return true; // vendor owners have full access
    return getEmployeeModules()[module] == true;
  }

  // ── Shared preference helpers ─────────────────────────────────────────────

  @override
  Future<void> saveUserToken(String token) =>
      authRepoInterface.saveUserToken(token);

  @override
  String getUserToken() => authRepoInterface.getUserToken();

  @override
  bool isLoggedIn() => authRepoInterface.isLoggedIn();

  @override
  Future<dynamic> clearSharedData() => authRepoInterface.clearSharedData();

  @override
  Future<dynamic> saveUserNumberAndPassword(String number, String password) =>
      authRepoInterface.saveUserCredentials(number, password);

  @override
  String getUserEmail() => authRepoInterface.getUserEmail();

  @override
  String getUserPassword() => authRepoInterface.getUserPassword();

  @override
  Future<dynamic> clearUserNumberAndPassword() =>
      authRepoInterface.clearUserNumberAndPassword();

  // ── Other existing methods (unchanged) ────────────────────────────────────

  @override
  Future<dynamic> forgotPassword(String identity) async {
    ApiResponse apiResponse = await authRepoInterface.forgotPassword(identity);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      return ResponseModel(true, apiResponse.response!.data['message']);
    }
    return ResponseModel(false, _extractError(apiResponse));
  }

  @override
  Future<dynamic> resetPassword(String identity, String otp, String password,
      String confirmPassword, String? token) async {
    ApiResponse apiResponse = await authRepoInterface.resetPassword(
        identity, otp, password, confirmPassword, token);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      return ResponseModel(true, apiResponse.response!.data['message']);
    }
    return ResponseModel(false, _extractError(apiResponse));
  }

  @override
  Future<dynamic> verifyOtp(String identity, String otp) async {
    ApiResponse apiResponse = await authRepoInterface.verifyOtp(identity, otp);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      return ResponseModel(true, apiResponse.response!.data['message']);
    }
    return ResponseModel(false, _extractError(apiResponse));
  }

  @override
  Future<dynamic> updateToken() async {
    ApiResponse apiResponse = await authRepoInterface.updateToken();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      return apiResponse;
    }
  }

  @override
  Future<dynamic> setLanguageCode(String languageCode) =>
      authRepoInterface.setLanguageCode(languageCode);

  @override
  Future<dynamic> registration(
          XFile? profileImage,
          XFile? shopLogo,
          XFile? shopBanner,
          XFile? secondaryBanner,
          RegisterModel registerModel,
          XFile? tinCertificate) =>
      authRepoInterface.registration(profileImage, shopLogo, shopBanner,
          secondaryBanner, registerModel, tinCertificate);

  @override
  Future<dynamic> firebaseAuthTokenStore(
          {required String userInput, required String token}) =>
      authRepoInterface.firebaseAuthTokenStore(userInput, token);

  @override
  Future<dynamic> firebaseAuthVerify(
          {required String phoneNumber,
          required String session,
          required String otp,
          required bool isForgetPassword}) =>
      authRepoInterface.firebaseAuthVerify(
          phoneNumber: phoneNumber,
          session: session,
          otp: otp,
          isForgetPassword: isForgetPassword);

  @override
  Future<dynamic> checkVendorExistPhone({required String phoneNumber}) =>
      authRepoInterface.checkVendorExistPhone(phoneNumber: phoneNumber);

  // ── Private helpers ───────────────────────────────────────────────────────

  String _extractError(ApiResponse apiResponse) {
    if (apiResponse.error is String) return apiResponse.error.toString();
    try {
      ErrorResponse errorResponse = apiResponse.error;
      return errorResponse.errors![0].message ?? 'Unknown error';
    } catch (_) {
      return 'Unknown error';
    }
  }
}
