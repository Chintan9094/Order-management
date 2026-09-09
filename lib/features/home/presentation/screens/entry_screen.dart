import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../routing/routes.dart';

/// Staff-only entry. Customers order via web QR (`/t/{token}`).
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: PageBackground(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _Blob(
                size: size.width * 0.55,
                color: AppColors.saffron.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -70,
              child: _Blob(
                size: size.width * 0.45,
                color: AppColors.ink.withValues(alpha: 0.06),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.saffron,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'SPICE GARDEN',
                          style: textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                    Text(
                      'Staff\nworkspace',
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 44,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Manage tables, kitchen orders, menu, and counter payments. '
                      'Customers order from the table QR in their browser.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.inkSoft,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(flex: 3),
                    FilledButton(
                      onPressed: () => context.push(AppRoutes.staffLogin),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Staff sign in'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Customer ordering is web-only via table QR',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
