import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TopNotification {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.error,
    Duration duration = const Duration(seconds: 4),
    bool shouldTranslate = true,
  }) {
    // Remove any existing notification
    hide();

    final overlay = Overlay.of(context);
    _currentEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        type: type,
        onDismiss: hide,
        shouldTranslate: shouldTranslate,
      ),
    );

    overlay.insert(_currentEntry!);

    // Auto-dismiss after specified duration
    Future.delayed(duration, () {
      hide();
    });
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

enum NotificationType { success, error, warning, info }

class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;
  final bool shouldTranslate;

  const _NotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.shouldTranslate = true,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await _controller.reverse();
                    widget.onDismiss();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(_getIcon(), color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.shouldTranslate
                                ? widget.message.tr()
                                : widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await _controller.reverse();
                            widget.onDismiss();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
