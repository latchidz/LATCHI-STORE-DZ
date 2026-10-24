import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// UI KIT — مكوّنات موحّدة يعاد استعمالها فـكل التطبيق
/// ============================================================

/// ---------- زر أساسي بتحميل ----------
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;
  final Color? color;
  final Color? foreground;

  const AppButton({
    super.key, required this.label, this.onPressed, this.loading = false,
    this.icon, this.expand = true, this.color, this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final btn = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color ?? AppColors.green700,
        foregroundColor: foreground ?? Colors.white,
        minimumSize: Size(expand ? double.infinity : 0, 54),
      ),
      child: loading
          ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpace.x2),
                ],
                Flexible(
                  child: Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppText.button.copyWith(
                          color: foreground ?? Colors.white)),
                ),
              ],
            ),
    );
    return btn;
  }
}

/// ---------- حقل نص ----------
class AppField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboard;
  final IconData? icon;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;
  final TextInputAction? action;

  const AppField({
    super.key, required this.label, this.hint, this.controller, this.keyboard,
    this.icon, this.validator, this.maxLines = 1, this.enabled = true,
    this.onChanged, this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: AppSpace.x2),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          textInputAction: action,
          style: AppText.body.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }
}

/// ---------- شارة ----------
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool small;

  const AppBadge({
    super.key, required this.text, this.color = AppColors.green700,
    this.icon, this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 7 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 11 : 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: AppText.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: small ? 11 : 12,
              )),
        ],
      ),
    );
  }
}

/// ---------- شارة حالة الطلب ----------
class StatusChip extends StatelessWidget {
  final OrderStatus status;
  final bool small;
  const StatusChip({super.key, required this.status, this.small = false});

  static Color colorOf(OrderStatus s) => switch (s) {
        OrderStatus.newOrder => AppColors.stNew,
        OrderStatus.confirmed => AppColors.stConfirmed,
        OrderStatus.canceled => AppColors.stCanceled,
        OrderStatus.postponed => AppColors.stPostponed,
        OrderStatus.inDelivery => AppColors.stInDelivery,
        OrderStatus.delivered => AppColors.stDelivered,
      };

  @override
  Widget build(BuildContext context) {
    final c = colorOf(status);
    return AppBadge(text: status.ar, color: c, small: small);
  }
}

/// ---------- صورة منتج بذاكرة + شيمر ----------
class ProductImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  const ProductImage({
    super.key, this.url, this.width, this.height,
    this.fit = BoxFit.cover, this.radius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (url == null || url!.isEmpty) {
      child = Container(
        color: AppColors.green50,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: AppColors.ink30, size: 32),
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.green50,
          highlightColor: Colors.white,
          child: Container(color: AppColors.green50),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.green50,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.ink30, size: 30),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

/// ---------- حالة فارغة ----------
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key, required this.icon, required this.title,
    this.subtitle, this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: const BoxDecoration(
                color: AppColors.green50, shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: AppColors.green600),
            ),
            const SizedBox(height: AppSpace.x5),
            Text(title, textAlign: TextAlign.center, style: AppText.h3),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpace.x2),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: AppText.bodySm.copyWith(color: AppColors.ink50)),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpace.x6),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// ---------- خطأ ----------
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'ما قدرناش نجيبو البيانات',
      subtitle: error.toString(),
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('عاود المحاولة'),
            ),
    );
  }
}

/// ---------- شيمر قائمة ----------
class ListSkeleton extends StatelessWidget {
  final int count;
  final double height;
  const ListSkeleton({super.key, this.count = 6, this.height = 96});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.line,
      highlightColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpace.x4),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpace.x3),
        itemBuilder: (_, __) => Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

/// ---------- عنوان قسم ----------
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x4, vertical: AppSpace.x3),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.h3)),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!, style: AppText.label.copyWith(color: AppColors.green700)),
            ),
        ],
      ),
    );
  }
}

/// ---------- عداد كمية ----------
class QtyStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const QtyStepper({
    super.key, required this.value, required this.onChanged,
    this.min = 1, this.max = 99,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, value > min ? () => onChanged(value - 1) : null),
          SizedBox(
            width: 36,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(fontWeight: FontWeight.w900)),
          ),
          _btn(Icons.add, value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }

  Widget _btn(IconData ic, VoidCallback? fn) => InkWell(
        onTap: fn,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(ic,
              size: 18,
              color: fn == null ? AppColors.ink30 : AppColors.green700),
        ),
      );
}

/// ---------- تنسيق عملة ----------
class PriceText extends StatelessWidget {
  final num value;
  final double size;
  final Color? color;
  final bool strike;
  const PriceText(this.value,
      {super.key, this.size = 19, this.color, this.strike = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      Money.dz(value),
      style: AppText.price.copyWith(
        fontSize: size,
        color: color ?? AppColors.green700,
        decoration: strike ? TextDecoration.lineThrough : null,
        decorationColor: AppColors.ink30,
      ),
    );
  }
}

/// ---------- Snackbar سريع ----------
void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.ink,
      duration: const Duration(seconds: 3),
    ));
}
