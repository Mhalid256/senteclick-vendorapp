// lib/features/auth/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/auth/screens/employee_login_screen.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/images.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';
import 'package:sixvalley_vendor_app/features/auth/screens/login_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToVendorTab() {
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthController>(context, listen: false).isActiveRememberMe;

    return Scaffold(
      // resizeToAvoidBottomInset keeps the layout stable when the keyboard
      // opens on either tab — prevents the "second logo pushes content down"
      // overflow that happened when EmployeeLoginScreen had its own header.
      resizeToAvoidBottomInset: true,
      body: Consumer<AuthController>(
        builder: (context, auth, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Single shared logo + app name (NOT duplicated per tab) ──
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height / 18,
                      bottom: 24,
                      left: Dimensions.paddingSizeDefault,
                      right: Dimensions.paddingSizeDefault),
                  child: Column(children: [
                    Hero(
                      tag: 'logo',
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: Dimensions.paddingSizeExtraLarge),
                        child: Image.asset(Images.logo, width: 70),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          getTranslated('seller', context)!,
                          style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeExtraLargeTwenty,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text(
                          getTranslated('app', context)!,
                          style: robotoMedium.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeExtraLargeTwenty),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),

              // ── Tab bar: Vendor | Staff ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).primaryColor,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Theme.of(context).hintColor,
                    labelStyle: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault),
                    unselectedLabelStyle: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.storefront_outlined, size: 18),
                            const SizedBox(width: 6),
                            Text(getTranslated('vendor', context) ?? 'Vendor'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.badge_outlined, size: 18),
                            const SizedBox(width: 6),
                            Text(getTranslated('staff', context) ?? 'Staff'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge),

              // ── Tab content fills remaining space, each tab scrolls
              //    independently ───────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: Vendor login (existing, unchanged)
                    const LoginScreen(),

                    // Tab 1: Staff login — no internal logo, switch link
                    // animates the TabController back to Vendor instead
                    // of using Navigator.pop (which caused a black screen
                    // since AuthScreen is the root route).
                    EmployeeLoginScreen(onSwitchToVendor: _switchToVendorTab),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
