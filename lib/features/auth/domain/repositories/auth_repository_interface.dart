// lib/features/auth/domain/repositories/auth_repository_interface.dart

import 'package:image_picker/image_picker.dart';
import 'package:sixvalley_vendor_app/data/model/response/base/api_response.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/models/register_model.dart';
import 'package:sixvalley_vendor_app/interface/repository_interface.dart';

abstract class AuthRepositoryInterface implements RepositoryInterface {
  // ── Vendor (seller) ───────────────────────────────────────────────────────
  Future<ApiResponse> login({String? emailAddress, String? password});
  Future<ApiResponse> setLanguageCode(String languageCode);
  Future<ApiResponse> forgotPassword(String identity);
  Future<ApiResponse> resetPassword(String identity, String otp,
      String password, String confirmPassword, String? token);
  Future<ApiResponse> verifyOtp(String identity, String otp);
  Future<ApiResponse> updateToken();
  Future<void> saveUserToken(String token);
  String getUserToken();
  bool isLoggedIn();
  Future<bool> clearSharedData();
  Future<void> saveUserCredentials(String number, String password);
  String getUserEmail();
  String getUserPassword();
  Future<bool> clearUserNumberAndPassword();
  Future<ApiResponse> registration(
      XFile? profileImage,
      XFile? shopLogo,
      XFile? shopBanner,
      XFile? secondaryBanner,
      RegisterModel registerModel,
      XFile? tinCertificate);
  Future<ApiResponse> firebaseAuthTokenStore(String userInput, String token);
  Future<ApiResponse> firebaseAuthVerify(
      {required String phoneNumber,
      required String session,
      required String otp,
      required bool isForgetPassword});
  Future<ApiResponse> checkVendorExistPhone({required String phoneNumber});

  // ── Employee / staff (NEW) ────────────────────────────────────────────────
  /// POST /api/v3/seller/auth/vendor-employee/login
  /// Returns { token } on success.
  Future<ApiResponse> employeeLogin(
      {required String email, required String password});

  /// GET /api/v3/seller/employee/profile
  /// Returns full profile + module_access map.
  Future<ApiResponse> getEmployeeProfile();

  /// Persist whether the current session is an employee session.
  Future<void> saveIsEmployee(bool isEmployee);
  bool getIsEmployee();

  /// Persist the module_access JSON so the app can read permissions
  /// offline (e.g. after app restart) without a new API call.
  Future<void> saveEmployeeModules(String modulesJson);
  String getEmployeeModules();
}
