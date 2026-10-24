import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// شاشة تفاصيل المتابعة — كانت مطلوبة فالراوتر
class LeadDetailScreen extends ConsumerWidget {
  final String id;
  const LeadDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المتابعة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.go('/merchant'),
        ),
      ),
      body: Center(
        child: Text('المتابعة #$id', style: AppText.body),
      ),
    );
  }
}
