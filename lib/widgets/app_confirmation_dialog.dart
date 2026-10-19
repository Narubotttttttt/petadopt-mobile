import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class AppConfirmationDialog extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? message;
  final Widget? content;
  final String? cancelText;
  final String confirmText;
  final bool isDestructive;
  final Color? confirmColor;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const AppConfirmationDialog({
    super.key,
    this.icon,
    this.customIcon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.message,
    this.content,
    this.cancelText,
    this.confirmText = 'OK',
    this.isDestructive = false,
    this.confirmColor,
    this.onCancel,
    this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    IconData? icon,
    Widget? customIcon,
    Color? iconColor,
    Color? iconBackgroundColor,
    required String title,
    String? message,
    Widget? content,
    String? cancelText,
    String confirmText = 'OK',
    bool isDestructive = false,
    Color? confirmColor,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogCtx) => AppConfirmationDialog(
        icon: icon,
        customIcon: customIcon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        title: title,
        message: message,
        content: content,
        cancelText: cancelText,
        confirmText: confirmText,
        isDestructive: isDestructive,
        confirmColor: confirmColor,
        onCancel: onCancel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? (isDestructive ? AppTheme.errorColor : AppTheme.primary);
    final effectiveIconBgColor = iconBackgroundColor ??
        (isDestructive ? const Color(0xFFFEE2E2) : effectiveIconColor.withValues(alpha: 0.12));

    Widget? headerIconWidget;
    if (customIcon != null) {
      headerIconWidget = customIcon;
    } else if (icon != null) {
      headerIconWidget = Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: effectiveIconBgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: effectiveIconColor,
            size: 30,
          ),
        ),
      );
    }

    final hasTwoButtons = cancelText != null && cancelText!.trim().isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (headerIconWidget != null) ...[
              Center(child: headerIconWidget),
              const SizedBox(height: 18),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: 14),
              content!,
            ],
            const SizedBox(height: 24),
            if (hasTwoButtons)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        onCancel?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF475569),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        cancelText!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        onConfirm?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor ??
                            (isDestructive ? AppTheme.errorColor : AppTheme.primary),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor ??
                        (isDestructive ? AppTheme.errorColor : AppTheme.primary),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    confirmText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
