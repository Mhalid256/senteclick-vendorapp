// lib/features/auth/screens/employee_login_screen.dart
// Logo/header removed — AuthScreen already shows the shared logo above the tabs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_button_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_snackbar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/textfeild/custom_text_feild_widget.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixvalley_vendor_app/helper/email_checker.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/main.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/images.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';

class EmployeeLoginScreen extends StatefulWidget {
  /// Optional callback to switch the parent TabController back to the
  /// Vendor tab (index 0). If null, the "Are you a vendor?" link is hidden.
  final VoidCallback? onSwitchToVendor;

  const EmployeeLoginScreen({super.key, this.onSwitchToVendor});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit(AuthController auth) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      showCustomSnackBarWidget(
          getTranslated('enter_email_address', context), context,
          sanckBarType: SnackBarType.warning);
      return;
    }
    if (EmailChecker.isNotValid(email)) {
      showCustomSnackBarWidget(
          getTranslated('enter_valid_email', context), context,
          sanckBarType: SnackBarType.warning);
      return;
    }
    if (password.isEmpty) {
      showCustomSnackBarWidget(
          getTranslated('enter_password', context), context,
          sanckBarType: SnackBarType.warning);
      return;
    }
    if (password.length < 6) {
      showCustomSnackBarWidget(
          getTranslated('password_should_be', context), context,
          sanckBarType: SnackBarType.warning);
      return;
    }

    final response = await auth.employeeLogin(
      context,
      email: email,
      password: password,
    );

    if (response.response?.statusCode == 200 && mounted) {
      // Use pushAndRemoveUntil with rootNavigator so this replaces the
      // ENTIRE navigation stack (including AuthScreen and its TabBarView).
      Navigator.of(Get.context!, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault),
                  child: Text(
                    getTranslated('staff_login', context) ?? 'Staff Login',
                    style: titilliumBold.copyWith(
                        fontSize: Dimensions.fontSizeOverlarge,
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall),
                  child: Text(
                    getTranslated('login_with_your_staff_account', context) ??
                        'Login with your staff account credentials',
                    style: titilliumRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).hintColor),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Form(
                  key: _formKey,
                  child: Column(children: [
                    // Email
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeLarge,
                          vertical: Dimensions.paddingSizeSmall),
                      child: CustomTextFieldWidget(
                        border: true,
                        prefixIconImage: Images.emailIcon,
                        hintText: getTranslated('enter_email_address', context),
                        focusNode: _emailFocus,
                        nextNode: _passwordFocus,
                        textInputType: TextInputType.emailAddress,
                        controller: _emailController,
                      ),
                    ),

                    // Password
                    Container(
                      margin: const EdgeInsets.only(
                          left: Dimensions.paddingSizeLarge,
                          right: Dimensions.paddingSizeLarge,
                          bottom: Dimensions.paddingSizeDefault),
                      child: CustomTextFieldWidget(
                        border: true,
                        isPassword: true,
                        prefixIconImage: Images.lock,
                        hintText: getTranslated('password_hint', context),
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.done,
                        controller: _passwordController,
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeButton),

                    // Login button
                    auth.isEmployeeLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 70),
                            child: CustomButtonWidget(
                              borderRadius: 100,
                              backgroundColor: Theme.of(context).primaryColor,
                              btnTxt: getTranslated('login', context),
                              onTap: () => _submit(auth),
                            ),
                          ),

                    // Switch back to vendor tab (NOT Navigator.pop — that
                    // caused the black screen because there was nothing
                    // beneath AuthScreen in the navigation stack).
                    if (widget.onSwitchToVendor != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeDefault),
                        child: InkWell(
                          onTap: widget.onSwitchToVendor,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  getTranslated('are_you_a_vendor', context) ??
                                      'Are you a vendor?',
                                  style: robotoRegular.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color),
                                ),
                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),
                                Text(
                                  getTranslated('vendor_login', context) ??
                                      'Vendor Login',
                                  style: robotoTitleRegular.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      decoration: TextDecoration.underline),
                                ),
                              ]),
                        ),
                      ),

                    const SizedBox(height: Dimensions.paddingSizeBottomSpace),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
