// lib/features/dashboard/screens/dashboard_screen.dart
// Adds employee-aware navigation — hides tabs the employee has no access to.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/confirmation_dialog_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_dialog_widget.dart';
import 'package:sixvalley_vendor_app/features/addProduct/controllers/digital_product_controller.dart';
import 'package:sixvalley_vendor_app/features/ai/controllers/ai_controller.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/features/pos/controllers/cart_controller.dart';
import 'package:sixvalley_vendor_app/features/product/controllers/category_controller.dart';
import 'package:sixvalley_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:sixvalley_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:sixvalley_vendor_app/features/transaction/controllers/transaction_controller.dart';
import 'package:sixvalley_vendor_app/features/wallet/controllers/wallet_controller.dart';
import 'package:sixvalley_vendor_app/helper/network_info.dart';
import 'package:sixvalley_vendor_app/localization/controllers/localization_controller.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/images.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';
import 'package:sixvalley_vendor_app/features/home/screens/home_page_screen.dart';
import 'package:sixvalley_vendor_app/features/menu/widgets/menu_widget.dart';
import 'package:sixvalley_vendor_app/features/order/screens/order_screen.dart';
import 'package:sixvalley_vendor_app/features/refund/screens/refund_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  late List<_NavItem> _navItems;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<AuthController>(context, listen: false);
    final bool isEmployee = auth.isEmployee;

    String languageCode =
        Provider.of<LocalizationController>(context, listen: false)
                    .locale
                    .countryCode ==
                'US'
            ? 'en'
            : Provider.of<LocalizationController>(context, listen: false)
                .locale
                .countryCode!
                .toLowerCase();

    // Always fetch seller/employee profile info
    Provider.of<ProfileController>(context, listen: false).getSellerInfo();
    Provider.of<CategoryController>(context, listen: false)
        .getCategoryList(context, null, languageCode);

    // Only load data the employee has access to
    if (!isEmployee || auth.employeeHasAccess('pos_management')) {
      Provider.of<CartController>(context, listen: false).getCartData();
    }
    if (!isEmployee || auth.employeeHasAccess('shop_settings')) {
      Provider.of<ShopController>(context, listen: false).getShopInfo();
    }
    if (!isEmployee || auth.employeeHasAccess('product_management')) {
      Provider.of<DigitalProductController>(context, listen: false)
          .getDigitalAuthor();
      Provider.of<DigitalProductController>(context, listen: false)
          .getPublishingHouse();
    }
    if (!isEmployee || auth.employeeHasAccess('dashboard')) {
      Provider.of<TransactionController>(context, listen: false)
          .getTransactionList(context, 'all', '', '');
      Provider.of<WalletController>(context, listen: false)
          .getPaymentInfoList();
    }

    if (Provider.of<SplashController>(context, listen: false)
            .configModel
            ?.isAiFeatureActive ==
        1) {
      Provider.of<AiController>(context, listen: false).generateLimitCheck();
    }

    // Build nav items — filter out tabs the employee cannot access
    _navItems = _buildNavItems(auth);

    NetworkInfo.checkConnectivity(context);
  }

  /// Build the navigation items based on whether this is an employee session
  /// and which modules they have access to.
  List<_NavItem> _buildNavItems(AuthController auth) {
    final bool isEmployee = auth.isEmployee;
    final items = <_NavItem>[];

    // Home / Dashboard — shown if has dashboard access (or is vendor)
    if (!isEmployee || auth.employeeHasAccess('dashboard')) {
      items.add(_NavItem(
        icon: Images.home,
        label: 'home',
        screen: HomePageScreen(callback: () {
          setState(() => _goToTab(1));
        }),
      ));
    }

    // Orders — shown if has order_management access (or is vendor)
    if (!isEmployee || auth.employeeHasAccess('order_management')) {
      items.add(_NavItem(
        icon: Images.order,
        label: 'my_order',
        screen: const OrderScreen(),
      ));
    }

    // Refund — shown if has order_management access (or is vendor)
    if (!isEmployee || auth.employeeHasAccess('order_management')) {
      items.add(_NavItem(
        icon: Images.refund,
        label: 'refund',
        screen: const RefundScreen(fromNotification: false),
      ));
    }

    // Menu is always shown — it contains all other features gated inside
    items.add(_NavItem(
      icon: Images.menu,
      label: 'menu',
      screen: null, // menu opens as bottom sheet
    ));

    return items;
  }

  void _goToTab(int index) {
    if (index < _navItems.length) {
      setState(() {
        _pageController.jumpToPage(index);
        _pageIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _navItems
        .where((item) => item.screen != null)
        .map((item) => item.screen!)
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (_pageIndex != 0) {
          _goToTab(0);
        } else {
          _onWillPop(context);
        }
        if (didPop) return;
      },
      child: Scaffold(
        key: _scaffoldKey,
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Theme.of(context).hintColor,
          selectedFontSize: Dimensions.fontSizeSmall,
          unselectedFontSize: Dimensions.fontSizeSmall,
          selectedLabelStyle: robotoBold,
          showUnselectedLabels: true,
          currentIndex: _pageIndex,
          type: BottomNavigationBarType.fixed,
          items: _navItems
              .asMap()
              .entries
              .map((e) => _barItem(
                  e.value.icon, getTranslated(e.value.label, context), e.key))
              .toList(),
          onTap: (int index) {
            final item = _navItems[index];
            if (item.screen == null) {
              // Menu tab — open bottom sheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (con) => const MenuBottomSheetWidget(),
              );
            } else {
              _goToTab(index);
            }
          },
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: screens.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => screens[index],
        ),
      ),
    );
  }

  BottomNavigationBarItem _barItem(String icon, String? label, int index) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding:
            const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
        child: SizedBox(
          width: index == _pageIndex
              ? Dimensions.iconSizeLarge
              : Dimensions.iconSizeMedium,
          child: Image.asset(icon,
              color: index == _pageIndex
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).hintColor),
        ),
      ),
      label: label,
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    showAnimatedDialogWidget(
        context,
        ConfirmationDialogWidget(
          icon: Images.logOut,
          title: getTranslated('exit_app', context),
          description: getTranslated('do_you_want_to_exit_the_app', context),
          onYesPressed: () => SystemNavigator.pop(),
        ),
        isFlip: true);
    return true;
  }
}

class _NavItem {
  final String icon;
  final String label;
  final Widget? screen;
  const _NavItem({required this.icon, required this.label, this.screen});
}
