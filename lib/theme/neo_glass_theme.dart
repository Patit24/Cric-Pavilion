import 'dart:ui';
import 'package:flutter/material.dart';

/// Ultra-modern Neomorphic + Glassmorphism Combined Design System
class NeoGlassTheme {
  // ==========================================
  // COLOR PALETTE (Cyber Emerald & Electric Cyan)
  // ==========================================
  static const Color bgCanvas = Color(0xFF070B14);
  static const Color bgSurface = Color(0xFF0B1120);
  static const Color bgCard = Color(0xFF0F172A);

  // Vibrant Accents
  static const Color neonEmerald = Color(0xFF00F5A0);
  static const Color neonCyan = Color(0xFF00D9F5);
  static const Color neonViolet = Color(0xFF8B5CF6);
  static const Color neonAmber = Color(0xFFFBBF24);
  static const Color neonRose = Color(0xFFF43F5E);

  // Glass Specular & Border Colors
  static final Color glassBorder = Colors.white.withValues(alpha: 0.14);
  static final Color glassHighlight = Colors.white.withValues(alpha: 0.28);
  static final Color glassFill = Colors.white.withValues(alpha: 0.05);

  // Neomorphic Dual Shadows (Depth + Light Highlight)
  static final BoxShadow neoDarkShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.65),
    offset: const Offset(4, 7),
    blurRadius: 16,
  );

  static final BoxShadow neoLightHighlight = BoxShadow(
    color: Colors.white.withValues(alpha: 0.07),
    offset: const Offset(-2, -2),
    blurRadius: 6,
  );

  static BoxShadow neoGlowShadow(Color color, {double opacity = 0.25, double blur = 14}) {
    return BoxShadow(
      color: color.withValues(alpha: opacity),
      offset: const Offset(0, 4),
      blurRadius: blur,
    );
  }

  // Linear Gradients
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonEmerald, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGoldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    colors: [
      Color(0x1F2A3F60),
      Color(0x0F111D33),
      Color(0x080B1220),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassHeroGradient = LinearGradient(
    colors: [
      Color(0x3300F5A0),
      Color(0x1800D9F5),
      Color(0xF00B1120),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Consistent Neo-Glass input decoration for forms and dialogs
  static InputDecoration inputDecoration({
    required String hintText,
    String? labelText,
    IconData? prefixIcon,
    Color? iconColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: iconColor ?? neonEmerald, size: 18) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0x660F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: glassBorder),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: neonEmerald, width: 1.5),
      ),
    );
  }

  // App Global ThemeData
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgCanvas,
      colorScheme: const ColorScheme.dark(
        primary: neonEmerald,
        secondary: neonCyan,
        tertiary: neonViolet,
        surface: bgSurface,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSurface,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: glassBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgSurface,
        modalBackgroundColor: bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: bgSurface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x22FFFFFF),
        thickness: 1,
      ),
    );
  }
}

/// Reusable Glassmorphism + Neomorphism Tactile Card
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
    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? NeoGlassTheme.glassCardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? NeoGlassTheme.glassBorder,
          width: borderWidth,
        ),
        boxShadow: [
          NeoGlassTheme.neoDarkShadow,
          NeoGlassTheme.neoLightHighlight,
          if (glowColor != null) NeoGlassTheme.neoGlowShadow(glowColor!),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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

/// Tactile Neo-Glass Interactive Button
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
    final effectiveGradient = isSecondary
        ? null
        : (gradient ?? NeoGlassTheme.neonGradient);

    final effectiveColor = isSecondary
        ? (color ?? const Color(0xFF1E293B))
        : null;

    final border = Border.all(
      color: isSecondary
          ? (color?.withValues(alpha: 0.5) ?? NeoGlassTheme.glassBorder)
          : Colors.white.withValues(alpha: 0.35),
      width: 1.2,
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(borderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveColor,
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          boxShadow: [
            NeoGlassTheme.neoDarkShadow,
            NeoGlassTheme.neoLightHighlight,
            if (!isSecondary)
              NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonEmerald, opacity: 0.3),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSecondary ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 8),
            ],
            DefaultTextStyle(
              style: TextStyle(
                color: isSecondary ? Colors.white : Colors.black87,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Translucent Neo-Glass Capsule Badge / Pill
class NeoGlassBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const NeoGlassBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = NeoGlassTheme.neonEmerald,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: [
          NeoGlassTheme.neoGlowShadow(color, opacity: 0.25, blur: 10),
          NeoGlassTheme.neoDarkShadow,
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      );
    }
    return content;
  }
}

/// Frosted Neo-Glass Dialog Wrapper with Backdrop Blur
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
    return Dialog(
      insetPadding: insetPadding,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xE60B1120),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: NeoGlassTheme.glassBorder, width: 1.2),
          boxShadow: [
            NeoGlassTheme.neoDarkShadow,
            NeoGlassTheme.neoLightHighlight,
            if (glowColor != null) NeoGlassTheme.neoGlowShadow(glowColor!),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
