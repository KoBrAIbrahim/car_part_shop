import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';

class AuthLoadingOverlay extends StatelessWidget {
  final String message;
  final bool isVisible;
  final Widget child;

  const AuthLoadingOverlay({
    super.key,
    required this.message,
    required this.isVisible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isVisible)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Logo
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.primary.withOpacity(0.05),
                                Colors.transparent,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.car_repair_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: const Duration(milliseconds: 1500),
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.2, 1.2),
                          end: const Offset(0.8, 0.8),
                          duration: const Duration(milliseconds: 1500),
                        ),

                    const SizedBox(height: 24),

                    // Loading Spinner
                    SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .rotate(duration: const Duration(milliseconds: 1000)),

                    const SizedBox(height: 24),

                    // Loading Message
                    Text(
                          message.tr(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .fadeIn(duration: const Duration(milliseconds: 800))
                        .then(delay: const Duration(milliseconds: 400))
                        .fadeOut(duration: const Duration(milliseconds: 800)),

                    const SizedBox(height: 16),

                    // Status Indicator
                    Text(
                      'auth.loading.please_wait'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Animated Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.2, 1.2),
                              duration: const Duration(milliseconds: 600),
                              delay: Duration(milliseconds: index * 200),
                            )
                            .then()
                            .scale(
                              begin: const Offset(1.2, 1.2),
                              end: const Offset(0.5, 0.5),
                              duration: const Duration(milliseconds: 600),
                            );
                      }),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(),
            ),
          ),
      ],
    );
  }
}

/// Quick helper to show loading overlay
class LoadingHelper {
  static Widget wrapWithLoading({
    required Widget child,
    required bool isLoading,
    required String loadingMessage,
  }) {
    return AuthLoadingOverlay(
      isVisible: isLoading,
      message: loadingMessage,
      child: child,
    );
  }
}
