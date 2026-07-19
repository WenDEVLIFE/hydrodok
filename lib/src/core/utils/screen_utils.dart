import 'package:flutter/material.dart';

/// Enum for different screen size categories
enum ScreenSize {
  small,
  medium,
  large,
  extraLarge,
}

/// Enum for screen dimension types
enum ScreenDimension {
  width,
  height,
}

/// Utility class for handling screen dimensions and responsive design
class ScreenUtils {
  /// Get screen width from context
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height from context
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get specific dimension based on enum
  static double getDimension(BuildContext context, ScreenDimension dimension) {
    switch (dimension) {
      case ScreenDimension.width:
        return getWidth(context);
      case ScreenDimension.height:
        return getHeight(context);
    }
  }

  /// Determine screen size category based on width
  static ScreenSize getScreenSize(BuildContext context) {
    double width = getWidth(context);

    if (width < 600) {
      return ScreenSize.small;
    } else if (width < 900) {
      return ScreenSize.medium;
    } else if (width < 1200) {
      return ScreenSize.large;
    } else {
      return ScreenSize.extraLarge;
    }
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T small,
    T? medium,
    T? large,
    T? extraLarge,
  }) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.small:
        return small;
      case ScreenSize.medium:
        return medium ?? small;
      case ScreenSize.large:
        return large ?? medium ?? small;
      case ScreenSize.extraLarge:
        return extraLarge ?? large ?? medium ?? small;
    }
  }

  /// Get percentage of screen width
  static double getWidthPercentage(BuildContext context, double percentage) {
    return getWidth(context) * (percentage / 100);
  }

  /// Get percentage of screen height
  static double getHeightPercentage(BuildContext context, double percentage) {
    return getHeight(context) * (percentage / 100);
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get device pixel ratio
  static double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }
}

/// Extension on BuildContext for easier access to screen utilities
extension ScreenUtilsExtension on BuildContext {
  double get screenWidth => ScreenUtils.getWidth(this);
  double get screenHeight => ScreenUtils.getHeight(this);
  ScreenSize get screenSize => ScreenUtils.getScreenSize(this);
  bool get isLandscape => ScreenUtils.isLandscape(this);
  bool get isPortrait => ScreenUtils.isPortrait(this);
  EdgeInsets get safeAreaPadding => ScreenUtils.getSafeAreaPadding(this);

  double widthPercentage(double percentage) => ScreenUtils.getWidthPercentage(this, percentage);
  double heightPercentage(double percentage) => ScreenUtils.getHeightPercentage(this, percentage);

  // Short aliases for responsive sizing
  double w(double p) => widthPercentage(p);
  double h(double p) => heightPercentage(p);

  /// Design-based width scaling (based on 375 design width)
  double dw(double designWidth) {
    return designWidth * (screenWidth / 375).clamp(0.8, 1.2);
  }

  /// Design-based height scaling (based on 812 design height)
  double dh(double designHeight) {
    return designHeight * (screenHeight / 812).clamp(0.8, 1.2);
  }
  
  /// Responsive font size scaling with tablet-aware clamping
  double sp(double size) {
    double width = screenWidth;
    double scale = width / 375;
    
    // Smooth the scaling for larger screens to avoid massive text
    if (width >= 600) {
      scale = 1.1 + (width - 600) / 2500;
    }
    
    return size * scale.clamp(0.8, 1.4);
  }
}

/// Extension on num for easier access to responsive sizing
extension ResponsiveNum on num {
  double w(BuildContext context) => context.widthPercentage(toDouble());
  double h(BuildContext context) => context.heightPercentage(toDouble());
  double dw(BuildContext context) => context.dw(toDouble());
  double dh(BuildContext context) => context.dh(toDouble());
  double sp(BuildContext context) => context.sp(toDouble());
}
