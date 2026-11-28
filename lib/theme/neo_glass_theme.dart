import 'dart:ui';
import 'package:flutter/material.dart';
import 'glass_components.dart';

export 'glass_components.dart';

/// 2026 Light Glassmorphism Design System
/// Inspired by Apple Vision Pro, modern fintech dashboards & sports broadcast UI.
class NeoGlassTheme {
  // ==========================================
  // COLOR PALETTE (Light Glassmorphism)
  // ==========================================
  static const Color bgCanvas = GlassTokens.bgIcyWhite;   // #F5F8FC
  static const Color bgSurface = Colors.white;
  static const Color bgCard = GlassTokens.glassFillHigh;

  // Brand & Semantic Accents
  static const Color neonEmerald = GlassTokens.mintGreen;    // #39C9A5
  static const Color neonCyan = GlassTokens.electricBlue;    // #477BFF
  static const Color neonViolet = GlassTokens.indigo;        // #6657E8
  static const Color neonAmber = GlassTokens.amber;          // #F59E0B
  static const Color neonRose = GlassTokens.coral;           // #FF7777

  // Typography Inks
  static const Color inkPrimary = GlassTokens.inkPrimary;    // #17233C
  static const Color inkSecondary = GlassTokens.inkSecondary;// #72809A
  static const Color inkMuted = GlassTokens.inkMuted;        // #A0AABD

  // Glass Specular & Border Colors
  static const Color glassBorder = GlassTokens.glassHairline;
  static const Color glassHighlight = GlassTokens.glassBorder;
  static const Color glassFill = GlassTokens.glassFillMid;

  // Soft Ambient Glass Shadows
  static const BoxShadow neoDarkShadow = BoxShadow(
    color: Color(0x1017233C),
    offset: Offset(0, 8),
    blurRadius: 24,
  );

  static const BoxShadow neoLightHighlight = BoxShadow(
    color: Color(0x80FFFFFF),
    offset: Offset(0, -1),
    blurRadius: 4,
  );

  static BoxShadow neoGlowShadow(Color color, {double opacity = 0.18, double blur = 16}) {
    return BoxShadow(
      color: color.withValues(alpha: opacity),
      offset: const Offset(0, 4),
      blurRadius: blur,
    );
  }

  // Linear Gradients
  static const LinearGradient neonGradient = GlassTokens.accentGradient;
  static const LinearGradient mintGradient = GlassTokens.mintGradient;

  static const LinearGradient amberGoldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    colors: [
      Color(0xCCFFFFFF),
      Color(0xA6F5F8FC),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassHeroGradient = LinearGradient(
    colors: [
      Color(0xD9FFFFFF),
      Color(0xCCEAF2FF),
      Color(0xCCF1EEFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Consistent Light Glass input decoration for forms and dialogs
  static InputDecoration inputDecoration({
    required String hintText,
    String? labelText,
    IconData? prefixIcon,
    Color? iconColor,
    Widget? suffixIcon,
  }) {
    return GlassInput.decoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      iconColor: iconColor ?? GlassTokens.electricBlue,
      suffixIcon: suffixIcon,
    );
  }

  // App Global Light Glassmorphism ThemeData
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: GlassTokens.bgIcyWhite,
      colorScheme: const ColorScheme.light(
        primary: GlassTokens.electricBlue,
        secondary: GlassTokens.indigo,
        tertiary: GlassTokens.mintGreen,
        error: GlassTokens.coral,
        surface: Colors.white,
        onSurface: GlassTokens.inkPrimary,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: GlassTokens.inkPrimary),
        bodyMedium: TextStyle(color: GlassTokens.inkPrimary),
        bodySmall: TextStyle(color: GlassTokens.inkSecondary),
        titleLarge: TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GlassTokens.glassFillHigh,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: GlassTokens.inkPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: GlassTokens.glassFillHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: GlassTokens.glassHairline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF2FFFFFF),
        modalBackgroundColor: Color(0xF2FFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xF2FFFFFF),
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: GlassTokens.glassHairline),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: GlassTokens.glassHairline,
        thickness: 1,
      ),
    );
  }
}

/// Reusable Light Glassmorphism Card (preserves NeoGlassCard API)
class NeoGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final LinearGradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final Color? glowColor;
  final VoidCallback? onTap;

  const NeoGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20.0,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sigma = GlassTokens.blurSigma(context);
    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? GlassTokens.glassFillHigh : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? GlassTokens.glassBorder,
          width: borderWidth,
        ),
        boxShadow: GlassTokens.softShadow(glow: glowColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardContent,
      );
    }
    return cardContent;
  }
}

/// Tactile Light Glass Interactive Button
class NeoGlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final Color? color;
  final LinearGradient? gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isSecondary;

  const NeoGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 14.0,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onPressed: onPressed,
      icon: icon,
      color: color,
      gradient: gradient,
      padding: padding,
      borderRadius: borderRadius,
      isSecondary: isSecondary,
      child: child,
    );
  }
}

/// Translucent Light Glass Capsule Badge / Pill
class NeoGlassBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const NeoGlassBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = GlassTokens.electricBlue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBadge(
      label: label,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }
}

/// Frosted Light Glass Dialog Wrapper with Backdrop Blur
class NeoGlassDialog extends StatelessWidget {
  final Widget child;
  final EdgeInsets insetPadding;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? glowColor;

  const NeoGlassDialog({
    super.key,
    required this.child,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24.0,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassModal(
      insetPadding: insetPadding,
      padding: padding,
      borderRadius: borderRadius,
      glowColor: glowColor,
      child: child,
    );
  }
}
