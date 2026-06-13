// lib/features/dashboard/screens/dashboard_screen.dart
//
// Fixes:
//  1. POS tab added to nav items (was completely missing for employees)
//  2. Nav items rebuilt in didChangeDependencies (not just initState) so
//     freshly-written SharedPreferences module_access is picked up —
//     this was why login showed a blank "Menu only" screen until app restart
//  3. If _navItems ends up empty for any reason, fall back to showing
//     Home so the screen is never blank

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
import 'package:sixvalley_vendor_app/features/pos/screens/pos_screen.dart';
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
  List<_NavItem> _navItems = [];
  bool _dataLoaded = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    NetworkInfo.checkConnectivity(context);
  }

  /// Runs every time this screen's dependencies change — critically,
  /// the FIRST time it runs is right after the widget tree is built
  /// following login, by which point SharedPreferences has been written
  /// with module_access. initState() alone was too early in some cases.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadInitialData();
      _navItems =
          _buildNavItems(Provider.of<AuthController>(context, listen: false));
      setState(() {});
    }
  }

  void _loadInitialData() {
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

    // Always fetch profile info (works for both vendor and employee —
    // ProfileController.getSellerInfo() uses the seller token either way)
    Provider.of<ProfileController>(context, listen: false).getSellerInfo();
    Provider.of<CategoryController>(context, listen: false)
        .getCategoryList(context, null, languageCode);

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
  }

  /// Build the bottom navigation tabs based on employee module_access.
  /// Vendor owners (isEmployee == false) always see everything.
  List<_NavItem> _buildNavItems(AuthController auth) {
    final bool isEmployee = auth.isEmployee;
    final items = <_NavItem>[];

    // Home / Dashboard
    if (!isEmployee || auth.employeeHasAccess('dashboard')) {
      items.add(_NavItem(
        icon: Images.home,
        label: 'home',
        screen:
            HomePageScreen(callback: () => _goToTab(_indexOfLabel('my_order'))),
      ));
    }

    // POS — was completely missing before. Added here.
    if (!isEmployee || auth.employeeHasAccess('pos_management')) {
      items.add(_NavItem(
        icon: Images.pos,
        label: 'pos',
        screen: const PosScreen(),
      ));
    }

    // Orders
    if (!isEmployee || auth.employeeHasAccess('order_management')) {
      items.add(_NavItem(
        icon: Images.order,
        label: 'my_order',
        screen: const OrderScreen(),
      ));
    }

    // Refund (part of order management)
    if (!isEmployee || auth.employeeHasAccess('order_management')) {
      items.add(_NavItem(
        icon: Images.refund,
        label: 'refund',
        screen: const RefundScreen(fromNotification: false),
      ));
    }

    // Menu is always available — individual menu items are gated
    // inside MenuBottomSheetWidget with access-denied messaging.
    items.add(const _NavItem(icon: Images.menu, label: 'menu', screen: null));

    // Safety net: if somehow everything except Menu got filtered out
    // (e.g. employee has zero modules), still show Home so the screen
    // is never blank.
    final hasRealScreen = items.any((i) => i.screen != null);
    if (!hasRealScreen) {
      items.insert(
        0,
        _NavItem(
          icon: Images.home,
          label: 'home',
          screen: HomePageScreen(callback: () {}),
        ),
      );
    }

    return items;
  }

  int _indexOfLabel(String label) {
    final idx = _navItems.indexWhere((i) => i.label == label);
    return idx == -1 ? 0 : idx;
  }

  void _goToTab(int index) {
    final screens = _navItems.where((i) => i.screen != null).toList();
    if (index < 0 || index >= screens.length) return;
    setState(() {
      _pageController.jumpToPage(index);
      _pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // While the first frame is building, _navItems may briefly be empty —
    // show a loader instead of a blank screen.
    if (_navItems.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = _navItems
        .where((item) => item.screen != null)
        .map((i) => i.screen!)
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
              // Map full nav index → screens-only index
              final screenIndex = _navItems
                      .sublist(0, index + 1)
                      .where((i) => i.screen != null)
                      .length -
                  1;
              _goToTab(screenIndex);
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

  BottomNavigationBarItem _barItem(String icon, String? label, int navIndex) {
    // currentIndex comparison uses the screens-only index for screens,
    // but BottomNavigationBar needs currentIndex aligned with `items` order.
    // We keep _pageIndex as the screens-only index and compute the
    // corresponding nav index for highlighting.
    final screenIndexForThisItem = _navItems
            .sublist(0, navIndex + 1)
            .where((i) => i.screen != null)
            .length -
        1;
    final isSelected = _navItems[navIndex].screen != null &&
        screenIndexForThisItem == _pageIndex;

    return BottomNavigationBarItem(
      icon: Padding(
        padding:
            const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
        child: SizedBox(
          width:
              isSelected ? Dimensions.iconSizeLarge : Dimensions.iconSizeMedium,
          child: Image.asset(icon,
              color: isSelected
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
