import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../routing/routes.dart';

class EnterTableCodeScreen extends StatefulWidget {
  const EnterTableCodeScreen({super.key});

  @override
  State<EnterTableCodeScreen> createState() => _EnterTableCodeScreenState();
}

class _EnterTableCodeScreenState extends State<EnterTableCodeScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.push('/t/${_controller.text.trim()}');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Your table', style: textTheme.displayMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Enter the code printed under the QR on your table.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Table code', style: textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _controller,
                          autofocus: true,
                          style: textTheme.headlineSmall,
                          decoration: const InputDecoration(
                            hintText: 'table-1',
                            prefixIcon: Icon(Icons.qr_code_2_rounded),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _continue(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a table code';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                    ),
                    child: const Text('Open menu'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Back to home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
