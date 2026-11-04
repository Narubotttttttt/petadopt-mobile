import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/network_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/app_confirmation_dialog.dart';

/// Global wrapper that adds an animated network connectivity status banner
/// at the top of the application.
class NetworkAwareWrapper extends StatefulWidget {
  final Widget child;

  const NetworkAwareWrapper({super.key, required this.child});

  @override
  State<NetworkAwareWrapper> createState() => _NetworkAwareWrapperState();
}

class _NetworkAwareWrapperState extends State<NetworkAwareWrapper> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConnectivityStatusBanner(),
          ),
        ],
      ),
    );
  }
}

/// Animated connectivity status banner
class ConnectivityStatusBanner extends StatelessWidget {
  const ConnectivityStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final network = NetworkService.instance;

    return ValueListenableBuilder<bool>(
      valueListenable: network.isConnected,
      builder: (context, isConnected, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: network.isRestored,
          builder: (context, isRestored, _) {
            final isVisible = !isConnected || isRestored;

            return IgnorePointer(
              ignoring: !isVisible,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                offset: isVisible ? Offset.zero : const Offset(0, -1.2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  opacity: isVisible ? 1.0 : 0.0,
                  child: Material(
                    type: MaterialType.transparency,
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isRestored
                              ? const Color(0xFF047857) // Emerald green
                              : const Color(0xFF1E293B), // Slate dark
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isRestored
                                ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                : const Color(0xFFDC2626).withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isRestored
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(0xFFDC2626).withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isRestored
                                    ? Icons.wifi_rounded
                                    : Icons.wifi_off_rounded,
                                color: isRestored
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFFCA5A5),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isRestored
                                        ? 'Connection Restored'
                                        : 'No Internet Connection',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isRestored
                                        ? 'You are back online'
                                        : 'Please check your Wi-Fi or mobile data',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isRestored) ...[
                              const SizedBox(width: 8),
                              ValueListenableBuilder<bool>(
                                valueListenable: network.isChecking,
                                builder: (context, isChecking, _) {
                                  return InkWell(
                                    onTap: isChecking
                                        ? null
                                        : () => network.checkConnection(),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: isChecking
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.8,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'Retry',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Helper utility for mid-transaction connection loss alerts
class NetworkErrorHelper {
  /// Shows a specialized connection lost modal dialog with retry capability
  static Future<bool?> showConnectionLostDialog(
    BuildContext context, {
    String title = 'Connection Lost',
    String? message,
    VoidCallback? onRetry,
  }) {
    return AppConfirmationDialog.show(
      context,
      icon: Icons.wifi_off_rounded,
      iconColor: AppTheme.errorColor,
      iconBackgroundColor: const Color(0xFFFFEAEA),
      title: title,
      message: message ??
          'Unable to reach CAWS servers. Your connection was lost during this action. Please check your internet connection and try again.',
      confirmText: onRetry != null ? 'Retry' : 'Dismiss',
      cancelText: onRetry != null ? 'Dismiss' : null,
      onConfirm: onRetry,
    );
  }

  /// Shows a specialized connection lost floating SnackBar
  static void showConnectionLostSnackBar(
    BuildContext context, {
    String? message,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message ?? 'Connection lost. Please check your internet connection.',
                style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: AppTheme.primaryLight,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}

