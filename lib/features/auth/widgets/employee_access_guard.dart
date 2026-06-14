// lib/features/auth/widgets/employee_access_guard.dart
//
// FIX: getTranslated() in this app returns the KEY ITSELF (not null) when
// a translation is missing — so `?? 'fallback'` never triggered, and raw
// keys like "access_denied" and "you_do_not_have_permission_to_..." were
// shown verbatim with underscores. We now hardcode the English strings
// directly instead of relying on translation keys that don't exist yet.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';

class EmployeeAccessGuard {
  /// Checks if the current session (vendor or employee) has access to
  /// [module]. Vendor owners always return true.
  static bool hasAccess(BuildContext context, String module) {
    return Provider.of<AuthController>(context, listen: false)
        .employeeHasAccess(module);
  }

  /// Navigates to the screen built by [builder] if the user has access
  /// to [module]. If not, shows an "Access Denied" dialog instead of
  /// navigating to a blank/broken screen.
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

  /// For actions that aren't navigation (e.g. opening a bottom sheet).
  /// Returns true if allowed (caller should proceed), false if denied
  /// (this method has already shown the dialog).
  static bool checkOrShowDenied(BuildContext context, String module) {
    if (hasAccess(context, module)) return true;
    _showAccessDenied(context);
    return false;
  }

  static void _showAccessDenied(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text(
          'You do not have permission to access this feature. '
          'Contact your shop owner if you need access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog telling the employee that this feature is restricted
  /// to the shop owner only.
  static void checkOwnerOrShowDenied(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text(
          'This feature is only available to the shop owner. '
          'Please contact your shop owner if you need access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
