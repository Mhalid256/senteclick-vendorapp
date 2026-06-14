// lib/features/auth/widgets/employee_access_guard.dart
//
// Two kinds of restriction:
//
//  1. Module-based (hasAccess / navigateIfAllowed / checkOrShowDenied):
//     employee is blocked unless their module_access map says true for
//     that module. Vendor owners always pass.
//
//  2. Owner-only (isOwnerOnlyAllowed / navigateIfOwner):
//     ALWAYS blocked for employees, regardless of module_access — used
//     for Wallet, Bank Info, and Profile, which are vendor-account-level
//     screens no staff member should ever see.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/images.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';

class EmployeeAccessGuard {
  // ── Module-based access ───────────────────────────────────────────────

  static bool hasAccess(BuildContext context, String module) {
    return Provider.of<AuthController>(context, listen: false)
        .employeeHasAccess(module);
  }

  static void navigateIfAllowed({
    required BuildContext context,
    required String module,
    required WidgetBuilder builder,
  }) {
    if (hasAccess(context, module)) {
      Navigator.push(context, MaterialPageRoute(builder: builder));
    } else {
      _showAccessDenied(context);
    }
  }

  static bool checkOrShowDenied(BuildContext context, String module) {
    if (hasAccess(context, module)) return true;
    _showAccessDenied(context);
    return false;
  }

  // ── Owner-only access (Wallet, Bank Info, Profile) ──────────────────────

  /// Returns true only for the vendor owner (non-employee session).
  /// Employees ALWAYS get false here, regardless of module_access.
  static bool isOwnerOnly(BuildContext context) {
    return !Provider.of<AuthController>(context, listen: false).isEmployee;
  }

  static void navigateIfOwner({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    if (isOwnerOnly(context)) {
      Navigator.push(context, MaterialPageRoute(builder: builder));
    } else {
      _showAccessDenied(context, ownerOnly: true);
    }
  }

  static bool checkOwnerOrShowDenied(BuildContext context) {
    if (isOwnerOnly(context)) return true;
    _showAccessDenied(context, ownerOnly: true);
    return false;
  }

  // ── Polished dialog ───────────────────────────────────────────────────

  static void _showAccessDenied(BuildContext context, {bool ownerOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Access Denied',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Transform.scale(
          scale: 0.85 + (0.15 * curved.value).clamp(0.0, 1.0),
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: _AccessDeniedDialog(ownerOnly: ownerOnly),
          ),
        );
      },
    );
  }
}

class _AccessDeniedDialog extends StatelessWidget {
  final bool ownerOnly;
  const _AccessDeniedDialog({required this.ownerOnly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeLarge),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top icon badge with gradient ───────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 28, bottom: 8),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent.shade200,
                      Colors.redAccent.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── Title ───────────────────────────────────────────────────
            Text(
              'Access Restricted',
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeLarge + 2,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(height: 10),

            // ── Message ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeExtraLarge),
              child: Text(
                ownerOnly
                    ? 'This section is reserved for the shop owner only. '
                      'Staff accounts do not have permission to view '
                      'financial and account details.'
                    : 'You don\'t have permission to access this feature. '
                      'If you need access, please ask the shop owner to '
                      'update your staff permissions.',
                textAlign: TextAlign.center,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: theme.hintColor,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: 26),

            Divider(height: 1, color: theme.dividerColor),

            // ── Action button ──────────────────────────────────────────
            Material(
              color: Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: InkWell(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Got it',
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}