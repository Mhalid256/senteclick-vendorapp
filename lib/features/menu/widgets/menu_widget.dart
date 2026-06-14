// lib/features/menu/widgets/menu_widget.dart
//
// Each menu item now declares the module it belongs to. _handleMenuTap
// checks employeeHasAccess() before navigating — vendor owners (non-employee)
// always pass. Employees without the module see an "Access Denied" dialog
// instead of a blank/broken screen.
//
// Module mapping used:
//   profile, settings, bank_info, terms/about/policies, logout, app-info
//     → always allowed (no module gate — basic account info & static pages)
//   my_shop                → shop_settings
//   add_product, products  → product_management
//   reviews                → product_management
//   coupons                → coupon_management
//   deliveryman             → delivery_man
//   pos                     → pos_management
//   restock, clearance_sale → product_management
//   wallet, vat_management  → dashboard  (financial overview)
//   inbox                   → chat

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/addProduct/screens/add_product_tab_view_screen.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/features/auth/widgets/employee_access_guard.dart';
import 'package:sixvalley_vendor_app/features/clearance_sale/screens/clearance_sale_screen.dart';
import 'package:sixvalley_vendor_app/features/restock/screens/restock_list_screen.dart';
import 'package:sixvalley_vendor_app/features/splash/domain/models/business_pages_model.dart';
import 'package:sixvalley_vendor_app/features/splash/domain/models/config_model.dart';
import 'package:sixvalley_vendor_app/features/vat_management/screens/vat_management_screen.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:sixvalley_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:sixvalley_vendor_app/theme/controllers/theme_controller.dart';
import 'package:sixvalley_vendor_app/utill/app_constants.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/images.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_bottom_sheet_widget.dart';
import 'package:sixvalley_vendor_app/features/chat/screens/inbox_screen.dart';
import 'package:sixvalley_vendor_app/features/coupon/screens/coupon_list_screen.dart';
import 'package:sixvalley_vendor_app/features/dashboard/screens/nav_bar_screen.dart';
import 'package:sixvalley_vendor_app/features/delivery_man/screens/delivery_man_setup_screen.dart';
import 'package:sixvalley_vendor_app/features/menu/widgets/sign_out_confirmation_dialog_widget.dart';
import 'package:sixvalley_vendor_app/features/more/screens/html_view_screen.dart';
import 'package:sixvalley_vendor_app/features/product/screens/product_list_screen.dart';
import 'package:sixvalley_vendor_app/features/profile/screens/profile_view_screen.dart';
import 'package:sixvalley_vendor_app/features/review/screens/product_review_screen.dart';
import 'package:sixvalley_vendor_app/features/settings/screens/setting_screen.dart';
import 'package:sixvalley_vendor_app/features/shop/screens/shop_screen.dart';
import 'package:sixvalley_vendor_app/features/wallet/screens/wallet_screen.dart';
import 'package:sixvalley_vendor_app/features/bank_info/screens/bank_info_screen.dart';

import '../../../main.dart';

class MenuBottomSheetWidget extends StatelessWidget {
  const MenuBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ConfigModel? configModel =
        Provider.of<SplashController>(context, listen: false).configModel;

    return Consumer<SplashController>(builder: (context, splashController, _) {
      List<CustomBottomSheetWidget> activateMenu = [
        // Profile — OWNER ONLY. Contains the vendor's personal account
        // details; staff should never see or edit this.
        CustomBottomSheetWidget(
          image:
              '${Provider.of<ProfileController>(context, listen: false).userInfoModel?.imageFullUrl?.path}',
          isProfile: true,
          title: getTranslated('profile', context),
          onTap: () => _handleMenuTap(context, const ProfileScreenView(),
              ownerOnly: true),
        ),

        // My Shop — shop_settings
        CustomBottomSheetWidget(
          image: Images.myShop,
          title: getTranslated('my_shop', context),
          onTap: () => _handleMenuTap(context, const ShopScreen(),
              module: 'shop_settings'),
        ),

        // Add Product — product_management
        CustomBottomSheetWidget(
          image: Images.addProduct,
          title: getTranslated('add_product', context),
          onTap: () => _handleMenuTap(
              context, const AddProductTabView(fromHome: false),
              module: 'product_management'),
        ),

        // Products — product_management
        CustomBottomSheetWidget(
          image: Images.productIconPp,
          title: getTranslated('products', context),
          onTap: () => _handleMenuTap(context, const ProductListMenuScreen(),
              module: 'product_management'),
        ),

        // Reviews — product_management
        CustomBottomSheetWidget(
          image: Images.reviewIcon,
          title: getTranslated('reviews', context),
          onTap: () => _handleMenuTap(context, const ProductReviewScreen(),
              module: 'product_management'),
        ),

        // Coupons — coupon_management
        CustomBottomSheetWidget(
          image: Images.couponIcon,
          title: getTranslated('coupons', context),
          onTap: () => _handleMenuTap(context, const CouponListScreen(),
              module: 'coupon_management'),
        ),

        // Delivery Man — delivery_man
        CustomBottomSheetWidget(
          image: Images.deliveryManIcon,
          title: getTranslated('deliveryman', context),
          onTap: () => _handleMenuTap(context, const DeliveryManSetupScreen(),
              module: 'delivery_man'),
        ),

        // POS — for employees: show whenever they have pos_management,
        // independent of the vendor's posActive config (that check was
        // causing POS to disappear entirely for employee sessions because
        // userInfoModel was often null/unloaded at menu-build time).
        // For vendor owners (non-employee): keep the original posActive gate.
        if (_shouldShowPos(context, configModel))
          CustomBottomSheetWidget(
            image: Images.pos,
            title: getTranslated('pos', context),
            onTap: () => _handleMenuTap(context, const NavBarScreen(),
                module: 'pos_management'),
          ),

        // Settings — shop_settings
        CustomBottomSheetWidget(
          image: Images.settings,
          title: getTranslated('settings', context),
          onTap: () => _handleMenuTap(context, const SettingsScreen(),
              module: 'shop_settings'),
        ),

        // Restock — product_management
        CustomBottomSheetWidget(
          image: Images.restockIcon,
          title: getTranslated('restock', context),
          onTap: () => _handleMenuTap(context, const RestockListScreen(),
              module: 'product_management'),
        ),

        // Clearance Sale — product_management
        CustomBottomSheetWidget(
          image: Images.clearanceSaleImage,
          title: getTranslated('clearance_sale', context),
          onTap: () => _handleMenuTap(context, const ClearanceSaleScreen(),
              module: 'product_management'),
        ),

        // Wallet — OWNER ONLY. Withdrawals and account balance must
        // never be visible or actionable by staff.
        CustomBottomSheetWidget(
          image: Images.wallet,
          title: getTranslated('wallet', context),
          onTap: () =>
              _handleMenuTap(context, const WalletScreen(), ownerOnly: true),
        ),

        // Inbox — chat
        CustomBottomSheetWidget(
          image: Images.message,
          title: getTranslated('inbox', context),
          onTap: () =>
              _handleMenuTap(context, const InboxScreen(), module: 'chat'),
        ),

        // VAT Management — dashboard (financial overview)
        CustomBottomSheetWidget(
          image: Images.reportIcon,
          title: getTranslated('vat_management', context),
          onTap: () => _handleMenuTap(context, const VatManagementScreen(),
              module: 'dashboard'),
        ),

        // Bank Info — OWNER ONLY. Bank account numbers and payout
        // details must never be visible to staff.
        CustomBottomSheetWidget(
          image: Images.bankingInfo,
          title: getTranslated('bank_info', context),
          onTap: () =>
              _handleMenuTap(context, const BankInfoScreen(), ownerOnly: true),
        ),

        // ── Static info pages — always allowed for everyone ──────────────
        if (getPageBySlug('terms-and-conditions',
                splashController.defaultBusinessPages) !=
            null)
          CustomBottomSheetWidget(
            image: Images.termsAndCondition,
            title: getTranslated('terms_and_condition', context),
            onTap: () => _handleMenuTap(
                context,
                HtmlViewScreen(
                    page: getPageBySlug('terms-and-conditions',
                        splashController.defaultBusinessPages))),
          ),

        if (getPageBySlug('about-us', splashController.defaultBusinessPages) !=
            null)
          CustomBottomSheetWidget(
            image: Images.aboutUs,
            title: getTranslated('about_us', context),
            onTap: () => _handleMenuTap(
                context,
                HtmlViewScreen(
                    page: getPageBySlug(
                        'about-us', splashController.defaultBusinessPages))),
          ),

        if (getPageBySlug(
                'privacy-policy', splashController.defaultBusinessPages) !=
            null)
          CustomBottomSheetWidget(
            image: Images.privacyPolicy,
            title: getTranslated('privacy_policy', context),
            onTap: () => _handleMenuTap(
                context,
                HtmlViewScreen(
                    page: getPageBySlug('privacy-policy',
                        splashController.defaultBusinessPages))),
          ),

        if (getPageBySlug(
                'refund-policy', splashController.defaultBusinessPages) !=
            null)
          CustomBottomSheetWidget(
            image: Images.refundPolicy,
            title: getTranslated('refund_policy', context),
            onTap: () => _handleMenuTap(
                context,
                HtmlViewScreen(
                    page: getPageBySlug('refund-policy',
                        splashController.defaultBusinessPages))),
          ),

        if (getPageBySlug(
                'return-policy', splashController.defaultBusinessPages) !=
            null)
          CustomBottomSheetWidget(
            image: Images.returnPolicy,
            title: getTranslated('return_policy', context),
            onTap: () => _handleMenuTap(
                context,
                HtmlViewScreen(
                    page: getPageBySlug('return-policy',
                        splashController.defaultBusinessPages))),
          ),

        if (getPageBySlug(
                'cancellation-policy', splashController.defaultBusinessPages) !=
            null)
          CustomBottomSheetWidget(
            image: Images.cPolicy,
            title: getTranslated('cancellation_policy', context),
            onTap: () => _handleMenuTap(
                context,
                HtmlViewScreen(
                    page: getPageBySlug('cancellation-policy',
                        splashController.defaultBusinessPages))),
          ),

        // Logout — always allowed
        CustomBottomSheetWidget(
          image: Images.logOut,
          title: getTranslated('logout', context),
          onTap: () async {
            Navigator.pop(context); // Close bottom sheet
            Future.microtask(
              () => showModalBottomSheet(
                  context: Get.context!,
                  builder: (_) => const SignOutConfirmationDialogWidget()),
            );
          },
        ),

        CustomBottomSheetWidget(
            image: Images.appInfo,
            title: 'v - ${AppConstants.appVersion}',
            onTap: () {}),
      ];

      return Container(
        decoration: BoxDecoration(
            color: Provider.of<ThemeController>(context).darkTheme
                ? Theme.of(context).highlightColor
                : Theme.of(context).highlightColor,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.keyboard_arrow_down_outlined,
                color: Theme.of(context).hintColor,
                size: Dimensions.iconSizeLarge),
          ),
          const SizedBox(height: Dimensions.paddingSizeVeryTiny),
          Consumer<ProfileController>(
              builder: (context, profileProvider, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeDefault),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: activateMenu,
              ),
            );
          }),
        ]),
      );
    });
  }

  /// Closes the bottom sheet then navigates — but only if the user
  /// (vendor owner or employee) has access to [module].
  ///
  /// [module] = null means no permission check (static pages, profile,
  /// logout, etc. — always allowed).
  /// Determines whether the POS menu item should be visible.
  ///
  /// - Employee with pos_management access → always show (POS is core
  ///   to their job; don't gate it behind the vendor's posActive flag
  ///   which may not be loaded yet on first menu render).
  /// - Employee WITHOUT pos_management → hidden (they'd just get
  ///   access-denied anyway).
  /// - Vendor owner → original behaviour: only show if posActive is
  ///   enabled both globally (configModel) and for this shop
  ///   (userInfoModel), when that data has loaded. If userInfoModel
  ///   hasn't loaded yet, default to showing POS rather than hiding it,
  ///   since hiding-by-default caused confusion.
  bool _shouldShowPos(BuildContext context, ConfigModel? configModel) {
    final auth = Provider.of<AuthController>(context, listen: false);

    if (auth.isEmployee) {
      return auth.employeeHasAccess('pos_management');
    }

    // Vendor owner
    final userInfo =
        Provider.of<ProfileController>(context, listen: false).userInfoModel;

    if (configModel?.posActive != 1) return false;

    // If shop-level posActive hasn't loaded yet, don't hide POS —
    // assume enabled until proven otherwise.
    if (userInfo == null) return true;

    return userInfo.posActive == 1;
  }

  void _handleMenuTap(BuildContext context, Widget screen,
      {String? module, bool ownerOnly = false}) {
    Navigator.pop(context); // Close bottom sheet first either way

    final auth = Provider.of<AuthController>(Get.context!, listen: false);

    if (ownerOnly && auth.isEmployee) {
      Future.delayed(const Duration(milliseconds: 200), () {
        EmployeeAccessGuard.checkOwnerOrShowDenied(Get.context!);
      });
      return;
    }

    if (module != null && auth.isEmployee && !auth.employeeHasAccess(module)) {
      Future.delayed(const Duration(milliseconds: 200), () {
        EmployeeAccessGuard.checkOrShowDenied(Get.context!, module);
      });
      return;
    }

    Future.microtask(() => Navigator.push(
          Get.context!,
          MaterialPageRoute(builder: (_) => screen),
        ));
  }

  BusinessPageModel? getPageBySlug(
      String slug, List<BusinessPageModel>? pagesList) {
    BusinessPageModel? pageModel;
    if (pagesList != null && pagesList.isNotEmpty) {
      for (var page in pagesList) {
        if (page.slug == slug) {
          pageModel = page;
        }
      }
    }
    return pageModel;
  }
}
