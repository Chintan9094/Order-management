import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../routing/routes.dart';
import '../providers/customer_session_providers.dart';

/// Resolves table public token via Laravel `/tables/resolve`.
class TableResolveScreen extends ConsumerStatefulWidget {
  const TableResolveScreen({super.key, required this.tableToken});

  final String tableToken;

  @override
  ConsumerState<TableResolveScreen> createState() => _TableResolveScreenState();
}

class _TableResolveScreenState extends ConsumerState<TableResolveScreen> {
  Object? _error;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final token = widget.tableToken.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Invalid table QR. Please scan again.');
      return;
    }
    setState(() {
      _error = null;
      _started = true;
    });
    try {
      await ref
          .read(customerSessionControllerProvider.notifier)
          .resolveTable(token);
      if (!mounted) return;
      context.go(AppRoutes.customerMenu);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tableToken.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Opening table')),
        body: AppErrorView(
          error: 'Invalid table QR. Please scan again.',
          onRetry: () => context.go(AppRoutes.home),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Opening table')),
        body: AppErrorView(
          error: _error!,
          onRetry: _resolve,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Opening table')),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: AppLoading(
          message: _started
              ? 'Joining ${widget.tableToken}…'
              : 'Preparing session…',
        ),
      ),
    );
  }
}
