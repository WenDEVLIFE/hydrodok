// dart
import 'package:flutter/material.dart';

enum ToastPosition { top, bottom }

class SlidingToast {
  SlidingToast._(); // prevent instantiation

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.bottom,
    Color backgroundColor = const Color(0xFF323232),
    Color textColor = Colors.white,
    double horizontalPadding = 16.0,
    Widget? leading,
    EdgeInsetsGeometry? margin,
  }) {
    final overlay = Overlay.of(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastOverlay(
        message: message,
        duration: duration,
        position: position,
        backgroundColor: backgroundColor,
        textColor: textColor,
        horizontalPadding: horizontalPadding,
        leading: leading,
        margin: margin,
        onDismissed: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final Duration duration;
  final ToastPosition position;
  final Color backgroundColor;
  final Color textColor;
  final double horizontalPadding;
  final Widget? leading;
  final EdgeInsetsGeometry? margin;
  final VoidCallback onDismissed;

  const _ToastOverlay({
    required this.message,
    required this.duration,
    required this.position,
    required this.backgroundColor,
    required this.textColor,
    required this.horizontalPadding,
    this.leading,
    this.margin,
    required this.onDismissed,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    final beginOffset = widget.position == ToastPosition.top
        ? const Offset(0, -1.0)
        : const Offset(0, 1.0);
    _offsetAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(widget.duration, () async {
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).viewPadding;
    final margin =
        widget.margin ??
        EdgeInsets.only(
          left: 16,
          right: 16,
          top: widget.position == ToastPosition.top ? safePadding.top + 12 : 0,
          bottom: widget.position == ToastPosition.bottom
              ? safePadding.bottom + 12
              : 0,
        );

    return IgnorePointer(
      ignoring: false,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Align(
            alignment: widget.position == ToastPosition.top
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: Padding(
              padding: margin,
              child: SlideTransition(
                position: _offsetAnimation,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: widget.horizontalPadding,
                    ),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(color: widget.textColor),
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
