// lib/features/auth/controllers/auth_controller.dart

import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_snackbar_widget.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/models/employee_model.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/models/register_model.dart';
import 'package:sixvalley_vendor_app/data/model/response/base/api_response.dart';
import 'package:sixvalley_vendor_app/data/model/response/response_model.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/services/auth_service_interface.dart';
import 'package:sixvalley_vendor_app/features/auth/enums/from_page.dart';
import 'package:sixvalley_vendor_app/features/auth/screens/otp_verification_screen.dart';
import 'package:sixvalley_vendor_app/features/auth/widgets/reset_password_widget.dart';
import 'package:sixvalley_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:sixvalley_vendor_app/features/splash/domain/models/config_model.dart';
import 'package:sixvalley_vendor_app/helper/api_checker.dart';
import 'package:sixvalley_vendor_app/helper/image_size_checker.dart';
import 'package:sixvalley_vendor_app/localization/app_localization.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/main.dart';
import 'package:sixvalley_vendor_app/localization/controllers/localization_controller.dart';

class AuthController with ChangeNotifier {
  final AuthServiceInterface authServiceInterface;
  AuthController({required this.authServiceInterface});

  // ── Loading states ────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isEmployeeLoading = false;
  bool get isEmployeeLoading => _isEmployeeLoading;

  // ── Employee session state ────────────────────────────────────────────────
  EmployeeModel? _employeeModel;
  EmployeeModel? get employeeModel => _employeeModel;

  bool get isEmployee => authServiceInterface.getIsEmployee();

  /// Check if the employee has a specific module permission.
  /// Always returns true for vendor owners (non-employee sessions).
  bool employeeHasAccess(String module) =>
      authServiceInterface.employeeHasAccess(module);

  // ── Existing state fields (unchanged) ────────────────────────────────────
  final String _loginErrorMessage = '';
  String get loginErrorMessage => _loginErrorMessage;
  XFile? _sellerProfileImage;
  XFile? _shopLogo;
  XFile? _shopBanner;
  XFile? secondaryBanner;
  XFile? offerBanner;
  XFile? get sellerProfileImage => _sellerProfileImage;
  XFile? get shopLogo => _shopLogo;
  XFile? get shopBanner => _shopBanner;
  bool? _isTermsAndCondition = false;
  bool? get isTermsAndCondition => _isTermsAndCondition;
  bool _isActiveRememberMe = false;
  bool get isActiveRememberMe => _isActiveRememberMe;
  int _selectionTabIndex = 1;
  int get selectionTabIndex => _selectionTabIndex;
  String _verificationCode = '';
  String get verificationCode => _verificationCode;
  bool _isEnableVerificationCode = false;
  bool get isEnableVerificationCode => _isEnableVerificationCode;
  String? _verificationMsg = '';
  String? get verificationMessage => _verificationMsg;
  final String _email = '';
  final String _phone = '';
  String get email => _email;
  String get phone => _phone;
  bool _isPhoneNumberVerificationButtonLoading = false;
  bool get isPhoneNumberVerificationButtonLoading =>
      _isPhoneNumberVerificationButtonLoading;
  String? _countryDialCode = '+880';
  String? get countryDialCode => _countryDialCode;
  bool _resendButtonLoading = false;
  bool get resendButtonLoading => _resendButtonLoading;
  String? _verificationID = '';
  String? get verificationID => _verificationID;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController shopNameController = TextEditingController();
  TextEditingController shopAddressController = TextEditingController();
  TextEditingController tinNumberController = TextEditingController();

  FocusNode firstNameNode = FocusNode();
  FocusNode lastNameNode = FocusNode();
  FocusNode emailNode = FocusNode();
  FocusNode phoneNode = FocusNode();
  FocusNode passwordNode = FocusNode();
  FocusNode confirmPasswordNode = FocusNode();
  FocusNode shopNameNode = FocusNode();
  FocusNode shopAddressNode = FocusNode();

  bool _lengthCheck = false;
  bool _numberCheck = false;
  bool _uppercaseCheck = false;
  bool _lowercaseCheck = false;
  bool _spatialCheck = false;
  bool _showPassView = false;

  bool get lengthCheck => _lengthCheck;
  bool get numberCheck => _numberCheck;
  bool get uppercaseCheck => _uppercaseCheck;
  bool get lowercaseCheck => _lowercaseCheck;
  bool get spatialCheck => _spatialCheck;
  bool get showPassView => _showPassView;

  bool _isUnAuthorize = false;
  bool get isUnAuthorize => _isUnAuthorize;

  // =========================================================================
  // Vendor login (unchanged)
  // =========================================================================

  Future<ApiResponse> login(BuildContext context,
      {String? emailAddress, String? password}) async {
    _isLoading = true;
    notifyListeners();
    ApiResponse apiResponse = await authServiceInterface.login(
        emailAddress: emailAddress, password: password);
    _isLoading = false;
    notifyListeners();
    if (apiResponse.response?.statusCode == 200) {
      await Provider.of<AuthController>(Get.context!, listen: false)
          .updateToken(Get.context!);
      setCurrentLanguage(
          Provider.of<LocalizationController>(Get.context!, listen: false)
                  .getCurrentLanguage() ??
              'en');
      setUnAuthorize(false);
      notifyListeners();
    }
    return apiResponse;
  }

  // =========================================================================
  // Employee / staff login (NEW)
  // =========================================================================

  /// Called from EmployeeLoginScreen when the staff member taps Login.
  ///
  /// Flow:
  ///   1. POST /api/v3/seller/auth/vendor-employee/login → token
  ///   2. Save token (same DioClient headers as vendor)
  ///   3. GET  /api/v3/seller/employee/profile → module_access
  ///   4. Save module_access to SharedPreferences
  ///   5. Return the profile API response so the screen can navigate
  Future<ApiResponse> employeeLogin(BuildContext context,
      {required String email, required String password}) async {
    _isEmployeeLoading = true;
    notifyListeners();

    // Step 1 + 2: login and save token
    ApiResponse loginResponse = await authServiceInterface.employeeLogin(
        email: email, password: password);

    if (kDebugMode) {
      debugPrint(
          '[EMPLOYEE LOGIN] status=${loginResponse.response?.statusCode} '
          'data=${loginResponse.response?.data} error=${loginResponse.error}');
    }

    if (loginResponse.response?.statusCode == 200) {
      // Step 3 + 4: fetch profile and persist module_access.
      // This MUST complete (success or failure) before we return —
      // otherwise _buildNavItems runs against an empty module map.
      ApiResponse profileResponse =
          await authServiceInterface.fetchAndSaveEmployeeProfile();

      if (kDebugMode) {
        debugPrint(
            '[EMPLOYEE PROFILE] status=${profileResponse.response?.statusCode} '
            'data=${profileResponse.response?.data} error=${profileResponse.error}');
        debugPrint(
            '[EMPLOYEE MODULES SAVED] ${authServiceInterface.getEmployeeModules()}');
      }

      if (profileResponse.response?.statusCode == 200) {
        _employeeModel = EmployeeModel.fromJson(profileResponse.response!.data);
      } else {
        // Profile fetch failed — module_access stays empty, which means
        // employeeHasAccess() returns false for everything. Give the
        // employee at least dashboard access as a safe fallback so the
        // app isn't completely unusable, and surface the error.
        if (kDebugMode) {
          debugPrint(
              '[EMPLOYEE PROFILE FAILED] Falling back to dashboard-only access.');
        }
        await authServiceInterface
            .saveEmployeeModulesFallback(); // see auth_service.dart
      }

      // Update FCM token just like vendor login
      await updateToken(Get.context!);
      setUnAuthorize(false);

      _isEmployeeLoading = false;
      notifyListeners();

      // Return the LOGIN response (200) regardless of profile outcome —
      // the employee should still reach the dashboard even if module
      // fetching had issues. The dashboard will just show fewer tabs.
      return loginResponse;
    }

    _isEmployeeLoading = false;
    notifyListeners();
    return loginResponse;
  }

  /// Load cached employee profile from SharedPreferences (used on app restart).
  void loadCachedEmployeeModules() {
    if (authServiceInterface.getIsEmployee()) {
      // Modules are already in SharedPreferences via getEmployeeModules()
      // The EmployeeModel is not cached between restarts — we use
      // getEmployeeModules() directly for permission checks.
      notifyListeners();
    }
  }

  // =========================================================================
  // Existing methods (unchanged)
  // =========================================================================

  Future<void> setCurrentLanguage(String currentLanguage) async {
    await authServiceInterface.setLanguageCode(currentLanguage);
  }

  Future<ResponseModel?> forgotPassword(
      String email, bool isNumber, ConfigModel? config,
      {FromPage? fromPage}) async {
    bool isResend = fromPage == FromPage.verification;
    ResponseModel? responseModel;
    _isLoading = true;
    if (isResend) _resendButtonLoading = true;
    notifyListeners();
    if (isNumber &&
        config?.forgotPasswordVerification == 'phone' &&
        config?.vendorForgotPasswordSmsMethod == 'firebase') {
      checkVendorExistPhone(email).then((response) {
        if (response.response?.statusCode == 200) {
          firebaseVerifyPhoneNumber(email,
              isResend: isResend, isForgetPassword: true);
        } else {
          _isLoading = false;
          if (isResend) _resendButtonLoading = false;
          notifyListeners();
          showCustomSnackBarWidget(response.error, Get.context!,
              sanckBarType: SnackBarType.error);
        }
      });
    } else {
      responseModel = await authServiceInterface.forgotPassword(email);
      _isLoading = false;
    }
    if (isResend) _resendButtonLoading = false;
    notifyListeners();
    return responseModel;
  }

  Future<void> updateToken(BuildContext context) async {
    await authServiceInterface.updateToken();
  }

  void updateTermsAndCondition(bool? value) {
    _isTermsAndCondition = value;
    notifyListeners();
  }

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    notifyListeners();
  }

  void setIndexForTabBar(int index, {bool isNotify = true}) {
    _selectionTabIndex = index;
    if (isNotify) notifyListeners();
  }

  bool isLoggedIn() => authServiceInterface.isLoggedIn();

  Future<bool> clearSharedData({bool fromUnAuthorizationError = false}) async {
    _employeeModel = null;
    Provider.of<ShopController>(Get.context!, listen: false).clearShopModel();
    return await authServiceInterface.clearSharedData();
  }

  void saveUserNumberAndPassword(String number, String password) {
    authServiceInterface.saveUserNumberAndPassword(number, password);
  }

  String getUserEmail() => authServiceInterface.getUserEmail();
  String getUserPassword() => authServiceInterface.getUserPassword();

  Future<bool> clearUserEmailAndPassword() async =>
      await authServiceInterface.clearUserNumberAndPassword();

  String getUserToken() => authServiceInterface.getUserToken();

  void updateVerificationCode(String query) {
    _isEnableVerificationCode = query.length == 6;
    _verificationCode = query;
    notifyListeners();
  }

  Future<ResponseModel> verifyOtp(String phone) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ResponseModel responseModel =
        await authServiceInterface.verifyOtp(phone, _verificationCode);
    _isPhoneNumberVerificationButtonLoading = false;
    _verificationMsg = responseModel.message;
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> resetPassword(String identity, String otp,
      String password, String confirmPassword, String? token) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ResponseModel responseModel = await authServiceInterface.resetPassword(
        identity, otp, password, confirmPassword, token);
    _isPhoneNumberVerificationButtonLoading = false;
    _verificationMsg = responseModel.message;
    notifyListeners();
    return responseModel;
  }

  void pickImage(bool isProfile, bool shopLogo, bool isRemove,
      {bool secondary = false, bool offer = false}) async {
    if (isRemove) {
      _sellerProfileImage = null;
      _shopLogo = null;
      _shopBanner = null;
      secondaryBanner = null;
    } else {
      XFile? image = await ImageValidationHelper.validateAndPickImage(
          source: ImageSource.gallery, context: Get.context!);
      if (isProfile && image != null) {
        _sellerProfileImage = image;
      } else if (shopLogo && image != null) {
        _shopLogo = image;
      } else if (secondary && image != null) {
        secondaryBanner = image;
      } else if (offer && image != null) {
        offerBanner = image;
      } else if (image != null) {
        _shopBanner = image;
      }
    }
    notifyListeners();
  }

  Future<ApiResponse> registration(BuildContext context,
      RegisterModel registerModel, XFile? tinCertificate) async {
    _isLoading = true;
    notifyListeners();
    ApiResponse response = await authServiceInterface.registration(
        _sellerProfileImage,
        _shopLogo,
        _shopBanner,
        secondaryBanner,
        registerModel,
        tinCertificate);
    if (response.response?.statusCode == 200) {
      _isLoading = false;
      firstNameController.clear();
      lastNameController.clear();
      phoneController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      shopNameController.clear();
      shopAddressController.clear();
      _sellerProfileImage = null;
      _shopLogo = null;
      _shopBanner = null;
      secondaryBanner = null;
      Provider.of<ShopController>(Get.context!, listen: false).clearShopModel();
      showCustomSnackBarWidget(
          getTranslated('you_are_successfully_registered', Get.context!),
          Get.context!,
          isError: false,
          sanckBarType: SnackBarType.success);
    } else if (response.response?.data is String &&
        jsonDecode(response.response?.data ?? '')['message'][0]['message'] !=
            null) {
      showCustomSnackBarWidget(
          '${jsonDecode(response.response?.data ?? '')['message'][0]['message']}',
          Get.context!,
          sanckBarType: SnackBarType.warning);
    } else {
      log('---->log===> ${response.response?.statusCode}/${response.error}/${response.response?.statusMessage}/${response.response?.data}');
      _isLoading = false;
      showCustomSnackBarWidget('The email has already been taken', Get.context!,
          sanckBarType: SnackBarType.warning);
    }
    _isLoading = false;
    notifyListeners();
    return response;
  }

  void setCountryDialCode(String? setValue) => _countryDialCode = setValue;

  void emptyRegistrationData({bool isUpdate = false}) {
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    shopNameController.clear();
    shopAddressController.clear();
    _sellerProfileImage = null;
    _shopLogo = null;
    _shopBanner = null;
    secondaryBanner = null;
    if (isUpdate) notifyListeners();
  }

  void validPassCheck(String pass, {bool isUpdate = true}) {
    _lengthCheck = pass.length > 7;
    _lowercaseCheck = pass.contains(RegExp(r'[a-z]'));
    _uppercaseCheck = pass.contains(RegExp(r'[A-Z]'));
    _spatialCheck = pass.contains(RegExp(r'[ .!@#$&*~^%]'));
    _numberCheck = pass.contains(RegExp(r'[\d+]'));
    if (isUpdate) notifyListeners();
  }

  void showHidePass({bool isUpdate = true}) {
    _showPassView = !_showPassView;
    if (isUpdate) notifyListeners();
  }

  bool isPasswordValid() =>
      _lengthCheck &&
      _numberCheck &&
      _lowercaseCheck &&
      _uppercaseCheck &&
      _spatialCheck &&
      _numberCheck;

  void setUnAuthorize(bool value, {bool update = false}) {
    _isUnAuthorize = value;
    if (update) notifyListeners();
  }

  Future<void> firebaseVerifyPhoneNumber(String phoneNumber,
      {bool isForgetPassword = false,
      bool isResend = false,
      String? toNavigateScreen,
      VoidCallback? onLoginSuccess}) async {
    if (!isResend) _isLoading = true;
    _resendButtonLoading = true;
    notifyListeners();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        _isPhoneNumberVerificationButtonLoading = false;
        _isLoading = false;
        notifyListeners();
        if (e.code == 'invalid-phone-number') {
          showCustomSnackBarWidget(
              getTranslated('please_submit_a_valid_phone_number', Get.context!),
              Get.context!);
        } else {
          showCustomSnackBarWidget(
              getTranslated('${e.message}'.replaceAll('_', ' ').toCapitalized(),
                  Get.context!),
              Get.context!);
        }
      },
      codeSent: (String vId, int? resendToken) async {
        _isPhoneNumberVerificationButtonLoading = false;
        _resendButtonLoading = false;
        notifyListeners();
        bool callRoute = !isResend;
        await callFirebaseStoretiken(phoneNumber, vId);
        _verificationID = vId;
        if (isResend) {
          showCustomSnackBarWidget(
              getTranslated('resend_code_successful', Get.context!),
              Get.context!,
              isError: false);
        }
        if (callRoute) {
          Navigator.push(
              Get.context!,
              MaterialPageRoute(
                  builder: (_) =>
                      VerificationScreen(phoneNumber, session: vId)));
          _isLoading = false;
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _resendButtonLoading = false;
        _isLoading = false;
      },
    );
    _resendButtonLoading = false;
    notifyListeners();
  }

  Future<void> callFirebaseStoretiken(String phoneNumber, String vID) async {
    await authServiceInterface.firebaseAuthTokenStore(
        userInput: phoneNumber, token: vID);
  }

  Future<ApiResponse> checkVendorExistPhone(String phone) async {
    notifyListeners();
    ApiResponse responseModel =
        await authServiceInterface.checkVendorExistPhone(phoneNumber: phone);
    notifyListeners();
    return responseModel;
  }

  Future<void> firebaseOtpVerification(
      {required String phoneNumber,
      required String session,
      required String otp,
      bool isForgetPassword = false}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponse apiResponse = await authServiceInterface.firebaseAuthVerify(
        session: session,
        phoneNumber: phoneNumber,
        otp: otp,
        isForgetPassword: isForgetPassword);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Navigator.pushAndRemoveUntil(
          Get.context!,
          MaterialPageRoute(
              builder: (_) => ResetPasswordWidget(
                    mobileNumber: phoneNumber,
                    otp: otp,
                    token: session,
                  )),
          (route) => false);
    } else {
      ApiChecker.checkApi(apiResponse, firebaseResponse: true);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
  }
}
