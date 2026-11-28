import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// 2026 Light Glassmorphism Design Tokens (Apple Vision Pro / Modern Fintech / Sports)
class GlassTokens {
  // Primary Backgrounds
  static const Color bgIcyWhite = Color(0xFFF5F8FC);
  static const Color bgLightBlue = Color(0xFFEAF2FF);
  static const Color bgLavender = Color(0xFFF1EEFF);

  // Accents
  static const Color electricBlue = Color(0xFF477BFF);
  static const Color indigo = Color(0xFF6657E8);
  static const Color mintGreen = Color(0xFF39C9A5);
  static const Color coral = Color(0xFFFF7777);
  static const Color amber = Color(0xFFF59E0B);

  // Typography
  static const Color inkPrimary = Color(0xFF17233C);
  static const Color inkSecondary = Color(0xFF72809A);
  static const Color inkMuted = Color(0xFFA0AABD);

  // Glass Surfaces (White 55-75% opacity + crisp translucent border)
  static const Color glassFillHigh = Color(0xBFFFFFFF); // 75%
  static const Color glassFillMid = Color(0xA6FFFFFF);  // 65%
  static const Color glassFillLow = Color(0x8CFFFFFF);  // 55%
  static const Color glassBorder = Color(0xCCFFFFFF);
  static const Color glassHairline = Color(0x1A17233C);

  static const LinearGradient canvasGradient = LinearGradient(
    colors: [bgIcyWhite, bgLightBlue, bgLavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [electricBlue, indigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [mintGreen, Color(0xFF22B89A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> softShadow({Color? glow}) => [
        const BoxShadow(
          color: Color(0x1017233C),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
        const BoxShadow(
          color: Color(0x0817233C),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
        if (glow != null)
          BoxShadow(
            color: glow.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
      ];

  /// Responsive blur sigma: 20px on desktop/web, 14px on mobile for smooth 60fps
  static double blurSigma(BuildContext context) {
    final width = MediaQuery.maybeOf(context)?.size.width ?? 1024;
    if (!kIsWeb && width < 600) return 14.0;
    return 18.0;
  }
}

/// Ambient Light Glassmorphism Canvas Background
class GlassScaffoldBackground extends StatelessWidget {
  final Widget child;

  const GlassScaffoldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: GlassTokens.canvasGradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      GlassTokens.electricBlue.withValues(alpha: 0.12),
                      GlassTokens.electricBlue.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -90,
            child: IgnorePointer(
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      GlassTokens.indigo.withValues(alpha: 0.10),
                      GlassTokens.indigo.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Core Reusable Frosted Glass Card with hover elevation & tactile press feedback
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.fillColor,
    this.borderColor,
    this.glowColor,
    this.onTap,
    this.enableBlur = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final sigma = widget.enableBlur ? GlassTokens.blurSigma(context) : 0.0;
    final scale = _pressed ? 0.985 : (_hovered && widget.onTap != null ? 1.005 : 1.0);
    final box = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.fillColor ?? GlassTokens.glassFillHigh,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor ?? GlassTokens.glassBorder,
            width: 1.1,
          ),
          boxShadow: GlassTokens.softShadow(glow: widget.glowColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: sigma > 0
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: Padding(padding: widget.padding, child: widget.child),
                )
              : Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    if (widget.onTap == null) return box;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: box,
      ),
    );
  }
}

/// Tactile Glassmorphism Button with subtle press scale (0.97)
class GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final Color? color;
  final LinearGradient? gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isSecondary;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 14,
    this.isSecondary = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final fg = widget.isSecondary ? GlassTokens.inkPrimary : Colors.white;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: disabled ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.isSecondary
                  ? (widget.color ?? GlassTokens.glassFillHigh)
                  : widget.color,
              gradient: widget.isSecondary
                  ? null
                  : (widget.color == null
                      ? (widget.gradient ?? GlassTokens.accentGradient)
                      : null),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.isSecondary
                    ? GlassTokens.glassHairline
                    : Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: widget.isSecondary
                  ? GlassTokens.softShadow()
                  : GlassTokens.softShadow(
                      glow: widget.color ?? GlassTokens.electricBlue,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: fg),
                  const SizedBox(width: 8),
                ],
                DefaultTextStyle(
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Consistent Glass Text Input
class GlassInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const GlassInput({
    super.key,
    this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 13.5, fontWeight: FontWeight.w500),
      decoration: decoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  static InputDecoration decoration({
    required String hintText,
    String? labelText,
    IconData? prefixIcon,
    Color? iconColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
      hintText: hintText,
      hintStyle: const TextStyle(color: GlassTokens.inkMuted, fontSize: 12.5),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: iconColor ?? GlassTokens.electricBlue, size: 18)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xB8FFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GlassTokens.glassHairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GlassTokens.glassHairline),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: GlassTokens.electricBlue, width: 1.5),
      ),
    );
  }
}

/// Frosted Glass Modal Container
class GlassModal extends StatelessWidget {
  final Widget child;
  final EdgeInsets insetPadding;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? glowColor;

  const GlassModal({
    super.key,
    required this.child,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final sigma = GlassTokens.blurSigma(context);
    return Dialog(
      insetPadding: insetPadding,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xE8FFFFFF),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white, width: 1.3),
          boxShadow: GlassTokens.softShadow(glow: glowColor ?? GlassTokens.electricBlue),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Glass Dropdown Field
class GlassDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;

  const GlassDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: GlassTokens.glassFillHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassTokens.glassHairline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          hint: hint != null
              ? Text(hint!, style: const TextStyle(color: GlassTokens.inkMuted, fontSize: 13))
              : null,
          dropdownColor: Colors.white,
          style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
          iconEnabledColor: GlassTokens.inkSecondary,
        ),
      ),
    );
  }
}

/// Glass Segmented / Pill Tabs
class GlassTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const GlassTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: GlassTokens.glassFillMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassTokens.glassHairline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(labels.length, (i) {
            final active = i == selectedIndex;
            return GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: Color(0x1417233C),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: active ? GlassTokens.electricBlue : GlassTokens.inkSecondary,
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Navigation Item descriptor for GlassSidebar
class GlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Collapsible Floating Translucent Sidebar for Desktop
class GlassSidebar extends StatelessWidget {
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final Widget? footer;

  const GlassSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.collapsed,
    required this.onToggleCollapse,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 76.0 : 228.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      decoration: BoxDecoration(
        color: GlassTokens.glassFillHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: GlassTokens.softShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                  children: [
                    if (!collapsed)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: GlassTokens.accentGradient,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.sports_cricket, color: Colors.white, size: 17),
                            ),
                            const SizedBox(width: 9),
                            const Flexible(
                              child: Text(
                                'CricPavilion',
                                style: TextStyle(
                                  color: GlassTokens.inkPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        collapsed ? Icons.menu_open : Icons.chevron_left,
                        color: GlassTokens.inkSecondary,
                        size: 20,
                      ),
                      tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                      onPressed: onToggleCollapse,
                    ),
                  ],
                ),
              ),
              const Divider(color: GlassTokens.glassHairline, height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final active = idx == selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () => onSelect(idx),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: EdgeInsets.symmetric(
                            horizontal: collapsed ? 0 : 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? GlassTokens.electricBlue.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active
                                  ? GlassTokens.electricBlue.withValues(alpha: 0.25)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                            children: [
                              Icon(
                                active ? item.activeIcon : item.icon,
                                size: 20,
                                color: active ? GlassTokens.electricBlue : GlassTokens.inkSecondary,
                              ),
                              if (!collapsed) ...[
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: active
                                          ? GlassTokens.electricBlue
                                          : GlassTokens.inkPrimary,
                                      fontSize: 13,
                                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (footer != null && !collapsed) ...[
                const Divider(color: GlassTokens.glassHairline, height: 1),
                Padding(padding: const EdgeInsets.all(12), child: footer!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating Translucent Top Navbar
class GlassNavbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const GlassNavbar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AppBar(
          backgroundColor: GlassTokens.glassFillHigh,
          foregroundColor: GlassTokens.inkPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: leading,
          title: title,
          actions: actions,
          bottom: bottom,
          shape: const Border(
            bottom: BorderSide(color: GlassTokens.glassHairline),
          ),
        ),
      ),
    );
  }
}

/// Clean Glass Data Table Container
class GlassTable extends StatelessWidget {
  final Widget header;
  final List<Widget> rows;

  const GlassTable({super.key, required this.header, required this.rows});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0x80EAF2FF),
              border: Border(bottom: BorderSide(color: GlassTokens.glassHairline)),
            ),
            child: header,
          ),
          ...rows,
        ],
      ),
    );
  }
}

/// Translucent Glass Pill Badge
class GlassBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const GlassBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = GlassTokens.electricBlue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return badge;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: badge);
  }
}

/// Compact Glass KPI Stat Card
class GlassStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const GlassStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = GlassTokens.electricBlue,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: GlassTokens.inkPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: GlassTokens.inkSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass Player Card
class GlassPlayerCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? photoUrl;
  final Widget? trailing;
  final VoidCallback? onTap;

  const GlassPlayerCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.photoUrl,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      borderRadius: 16,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: GlassTokens.bgLightBlue,
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: GlassTokens.electricBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: GlassTokens.inkPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Glass Match Card Wrapper
class GlassMatchCard extends StatelessWidget {
  final Widget child;
  final bool isLive;
  final VoidCallback? onTap;

  const GlassMatchCard({
    super.key,
    required this.child,
    this.isLive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      borderColor: isLive
          ? GlassTokens.coral.withValues(alpha: 0.45)
          : GlassTokens.glassBorder,
      glowColor: isLive ? GlassTokens.coral : null,
      onTap: onTap,
      child: child,
    );
  }
}

/// Glass Score Card Header
class GlassScoreCard extends StatelessWidget {
  final Widget child;

  const GlassScoreCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      glowColor: GlassTokens.electricBlue,
      child: child,
    );
  }
}

/// Glass Notification / Banner Callout
class GlassNotification extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Widget? action;

  const GlassNotification({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = GlassTokens.electricBlue,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 14,
      fillColor: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.25),
      enableBlur: false,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: GlassTokens.inkPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
