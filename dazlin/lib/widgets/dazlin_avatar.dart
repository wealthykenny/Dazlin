// lib/widgets/dazlin_avatar.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class DazlinAvatar extends StatelessWidget {
  final String? url;
  final String initials;
  final double size;
  final bool isOnline;
  final Color? bgColor;

  const DazlinAvatar({
    super.key,
    this.url,
    required this.initials,
    this.size = 44,
    this.isOnline = false,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor ?? DazlinTheme.card,
        border: Border.all(color: DazlinTheme.border, width: 1),
        image: url != null && url!.isNotEmpty
            ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
            : null,
      ),
      child: url == null || url!.isEmpty
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: DazlinTheme.lime,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
    );

    if (!isOnline) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width:  size * 0.26,
            height: size * 0.26,
            decoration: BoxDecoration(
              color:  DazlinTheme.online,
              shape:  BoxShape.circle,
              border: Border.all(color: DazlinTheme.bg, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Unread badge ──────────────────────────────────────────────────────────────

class UnreadBadge extends StatelessWidget {
  final int count;
  const UnreadBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        DazlinTheme.lime,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color:      DazlinTheme.textOnLime,
          fontSize:   11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Glowing lime button ───────────────────────────────────────────────────────

class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Widget? icon;

  const GlowButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color:        loading ? DazlinTheme.limeDeep : DazlinTheme.lime,
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color:      DazlinTheme.limeGlow,
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset:     const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width:  20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: DazlinTheme.textOnLime,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(
                      label,
                      style: const TextStyle(
                        color:      DazlinTheme.textOnLime,
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Dazlin text field ─────────────────────────────────────────────────────────

class DazlinField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? prefix;
  final Widget? suffix;
  final String? error;
  final void Function(String)? onSubmit;
  final int? maxLines;

  const DazlinField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboard,
    this.prefix,
    this.suffix,
    this.error,
    this.onSubmit,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:      controller,
      obscureText:     obscure,
      keyboardType:    keyboard,
      maxLines:        maxLines,
      onSubmitted:     onSubmit,
      style: const TextStyle(color: DazlinTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText:    hint,
        prefixIcon:  prefix,
        suffixIcon:  suffix,
        errorText:   error,
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
      ),
    );
  }
}
