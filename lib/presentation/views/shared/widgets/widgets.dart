import 'package:athlos/core/theme/theme_notifier.dart';
import 'package:flutter/material.dart';

// ─── Athlos Avatar ────────────────────────────────────────────────────────────
class AthlosAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool showOnlineIndicator;

  const AthlosAvatar({super.key, required this.name, this.size = 36, this.showOnlineIndicator = false});

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return Stack(children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: ext.primaryColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text(initials, style: TextStyle(
          fontSize: size * 0.35, fontWeight: FontWeight.w600, color: ext.primaryColor))),
      ),
      if (showOnlineIndicator)
        Positioned(right: 0, bottom: 0,
          child: Container(
            width: size * 0.28, height: size * 0.28,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981), shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          )),
    ]);
  }
}

// ─── Athlos App Bar ───────────────────────────────────────────────────────────
class AthlosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const AthlosAppBar({
    super.key, this.title, this.showLogo = false,
    this.actions, this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return AppBar(
      backgroundColor: ext.surfaceColor,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: automaticallyImplyLeading ? null : const SizedBox.shrink(),
      title: showLogo ? Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.sports, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Text('ATHLOS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
            color: ext.textPrimary, letterSpacing: 2)),
      ]) : (title != null ? Text(title!, style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.w600, color: ext.textPrimary)) : null),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: ext.borderColor),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({super.key, required this.label, this.color});

  Color _colorFor(String label) {
    switch (label.toLowerCase()) {
      case 'ativo': return const Color(0xFF10B981);
      case 'inativo': return const Color(0xFFEF4444);
      default: return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? _colorFor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

// ─── Athlos Card ──────────────────────────────────────────────────────────────
class AthlosCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool highlighted;

  const AthlosCard({
    super.key, required this.child, this.padding,
    this.onTap, this.backgroundColor, this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? ext.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted ? ext.primaryColor : ext.borderColor,
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─── Filter Chip Row ──────────────────────────────────────────────────────────
class FilterChipRow extends StatelessWidget {
  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onSelect;

  const FilterChipRow({
    super.key, required this.filters,
    required this.activeFilter, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final sel = f == activeFilter;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? ext.primaryColor : ext.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? ext.primaryColor : ext.borderColor),
              ),
              child: Text(f, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: sel ? Colors.white : ext.textSecondary,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ext.textPrimary)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.primaryColor)),
          ),
      ],
    );
  }
}

// ─── Form Field Helper ────────────────────────────────────────────────────────
class AthlosTextField extends StatelessWidget {
  final String hint;
  final String? label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const AthlosTextField({
    super.key, required this.hint, this.label,
    this.controller, this.keyboardType, this.maxLines = 1,
    this.obscureText = false, this.suffixIcon, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: ext.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          onChanged: onChanged,
          style: TextStyle(fontSize: 13, color: ext.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: ext.textSecondary.withOpacity(0.5), fontSize: 12),
            filled: true, fillColor: ext.surfaceVariant, isDense: true,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ext.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ext.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ext.primaryColor, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

// ─── Color Picker Section ─────────────────────────────────────────────────────
class ColorPickerSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;

  const ColorPickerSection({
    super.key, required this.title, required this.subtitle,
    required this.icon, required this.colors,
    required this.selected, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return AthlosCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: selected.withOpacity(0.15), borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 16, color: selected),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 10, color: ext.textSecondary)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24, height: 24,
            decoration: BoxDecoration(color: selected, shape: BoxShape.circle,
                border: Border.all(color: ext.borderColor, width: 2)),
          ),
        ]),
        const SizedBox(height: 12),
        Divider(color: ext.borderColor, height: 1),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 8, children: colors.map((c) {
          final sel = c.value == selected.value;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: c, shape: BoxShape.circle,
                border: sel ? Border.all(color: ext.textPrimary, width: 2.5) : Border.all(color: Colors.transparent),
                boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))] : [],
              ),
              child: sel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          );
        }).toList()),
      ]),
    );
  }
}
