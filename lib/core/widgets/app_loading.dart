import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.ink),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSpacing.screenPadding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.stoneDark,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
