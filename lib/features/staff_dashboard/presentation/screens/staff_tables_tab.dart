import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../shared/domain/enums.dart';
import '../../../shared/domain/staff_permissions.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../providers/staff_providers.dart';

class StaffTablesTab extends ConsumerWidget {
  const StaffTablesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffTablesProvider);
    final canManage = ref
            .watch(authControllerProvider)
            .user
            ?.hasPermission(StaffPermissions.manageTables) ??
        false;

    return async.when(
      loading: () => const AppLoading(message: 'Loading tables…'),
      error: (e, _) => AppErrorView(
        error: e,
        onRetry: () => ref.invalidate(staffTablesProvider),
      ),
      data: (allTables) {
        final tables = allTables.where((t) => t.isActive).toList();

        return Stack(
          children: [
            if (tables.isEmpty)
              AppEmptyState(
                title: 'No tables found',
                subtitle: canManage
                    ? 'Tap + to add your first table.'
                    : 'Ask an admin or manager to add tables.',
                icon: Icons.table_restaurant_outlined,
              )
            else
              RefreshIndicator(
                onRefresh: () async => ref.invalidate(staffTablesProvider),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    canManage ? 88 : AppSpacing.md,
                  ),
                  itemCount: tables.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return _TableCard(
                      table: table,
                      canManage: canManage,
                      onQr: () => _showQr(context, ref, table),
                      onEdit: () => _showTableEditor(context, ref, table: table),
                      onDelete: () => _confirmDelete(context, ref, table),
                      onMarkPaid: () => _markPaid(context, ref, table),
                      onClose: () => _closeSession(context, ref, table),
                    );
                  },
                ),
              ),
            if (canManage)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'add-table',
                  backgroundColor: AppColors.saffron,
                  onPressed: () => _showTableEditor(context, ref),
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove table?'),
        content: Text(
          '${table.label} will be deactivated and its QR will stop working.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(tableRepositoryProvider).deactivateTable(table.id);
      ref.invalidate(staffTablesProvider);
      ref.invalidate(staffDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${table.label} removed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.userMessage(e))),
        );
      }
    }
  }

  Future<void> _showTableEditor(
    BuildContext context,
    WidgetRef ref, {
    RestaurantTable? table,
  }) async {
    final draft = await showDialog<_TableDraft>(
      context: context,
      builder: (ctx) => _TableEditorDialog(
        initialLabel: table?.label,
        initialCapacity: table?.capacity ?? 4,
      ),
    );
    if (draft == null || !context.mounted) return;

    try {
      final repo = ref.read(tableRepositoryProvider);
      if (table != null) {
        await repo.updateTable(
          RestaurantTable(
            id: table.id,
            restaurantId: table.restaurantId,
            label: draft.label,
            publicToken: table.publicToken,
            capacity: draft.capacity,
            isActive: table.isActive,
            displayStatus: table.displayStatus,
            openSessionId: table.openSessionId,
            openPaymentId: table.openPaymentId,
            openPaymentStatus: table.openPaymentStatus,
            openPaymentAmountDue: table.openPaymentAmountDue,
          ),
        );
      } else {
        await repo.createTable(label: draft.label, capacity: draft.capacity);
      }
      ref.invalidate(staffTablesProvider);
      ref.invalidate(staffDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(table != null ? 'Table updated' : 'Table added'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.userMessage(e))),
        );
      }
    }
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) async {
    final paymentId = table.openPaymentId;
    if (paymentId == null) return;
    try {
      await ref.read(paymentRepositoryProvider).markPaid(paymentId);
      ref.invalidate(staffTablesProvider);
      ref.invalidate(staffDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${table.label} marked paid')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.userMessage(e))),
        );
      }
    }
  }

  Future<void> _closeSession(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) async {
    final sessionId = table.openSessionId;
    if (sessionId == null) return;
    try {
      await ref.read(paymentRepositoryProvider).closeSession(sessionId);
      ref.invalidate(staffTablesProvider);
      ref.invalidate(staffDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${table.label} session closed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.userMessage(e))),
        );
      }
    }
  }

  void _showQr(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) {
    final config = ref.read(appConfigProvider);
    final payload = config.tableQrUrl(table.publicToken);
    final size = MediaQuery.sizeOf(context);
    final qrSize = (size.width * 0.55).clamp(180.0, 240.0);
    final qrKey = GlobalKey();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusMd,
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    table.label,
                    style: Theme.of(dialogContext).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone camera opens this link in the browser',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    key: qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: QrImageView(
                        data: payload,
                        size: qrSize,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    payload,
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: payload),
                            );
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('QR link copied'),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Text('Copy'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _shareQr(
                            context: context,
                            qrKey: qrKey,
                            tableLabel: table.label,
                            payload: payload,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Text('Share'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            backgroundColor: AppColors.saffron,
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareQr({
    required BuildContext context,
    required GlobalKey qrKey,
    required String tableLabel,
    required String payload,
  }) async {
    final message = '$tableLabel QR — scan to order:\n$payload';
    final fileName =
        '${tableLabel.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}_qr.png';
    try {
      final boundary =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          await SharePlus.instance.share(
            ShareParams(
              files: [
                XFile.fromData(
                  byteData.buffer.asUint8List(),
                  mimeType: 'image/png',
                  name: fileName,
                ),
              ],
              text: message,
              subject: '$tableLabel ordering QR',
            ),
          );
          return;
        }
      }
      await SharePlus.instance.share(
        ShareParams(text: message, subject: '$tableLabel ordering QR'),
      );
    } catch (e) {
      try {
        await SharePlus.instance.share(
          ShareParams(text: message, subject: '$tableLabel ordering QR'),
        );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorMapper.userMessage(e))),
          );
        }
      }
    }
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.table,
    required this.canManage,
    required this.onQr,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkPaid,
    required this.onClose,
  });

  final RestaurantTable table;
  final bool canManage;
  final VoidCallback onQr;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkPaid;
  final VoidCallback onClose;

  String _statusLabel(TableDisplayStatus status) {
    return switch (status) {
      TableDisplayStatus.available => 'Available',
      TableDisplayStatus.occupied => 'Occupied',
      TableDisplayStatus.orderPlaced => 'Order placed',
      TableDisplayStatus.preparing => 'Preparing',
      TableDisplayStatus.ready => 'Ready',
      TableDisplayStatus.paymentPending => 'Payment pending',
      TableDisplayStatus.paid => 'Paid',
      TableDisplayStatus.completed => 'Completed',
    };
  }

  @override
  Widget build(BuildContext context) {
    final canMarkPaid = table.openPaymentId != null &&
        table.openPaymentStatus != PaymentStatus.paid;
    final canClose = table.openSessionId != null &&
        (table.openPaymentStatus == PaymentStatus.paid ||
            (table.openPaymentAmountDue ?? 0) <= 0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F1419),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(table.displayStatus),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (table.capacity != null)
                      Text(
                        'Seats: ${table.capacity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (table.openPaymentAmountDue != null &&
                        table.openPaymentAmountDue! > 0)
                      Text(
                        'Due: ${CurrencyFormatter.format(table.openPaymentAmountDue!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onQr,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('QR'),
              ),
              if (canManage) ...[
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.danger,
                ),
              ],
            ],
          ),
          if (canMarkPaid || canClose) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                if (canMarkPaid)
                  FilledButton(
                    onPressed: onMarkPaid,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: AppColors.sage,
                    ),
                    child: const Text('Mark paid'),
                  ),
                if (canClose)
                  OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Close session'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TableDraft {
  const _TableDraft({required this.label, required this.capacity});

  final String label;
  final int capacity;
}

class _TableEditorDialog extends StatefulWidget {
  const _TableEditorDialog({
    this.initialLabel,
    this.initialCapacity = 4,
  });

  final String? initialLabel;
  final int initialCapacity;

  @override
  State<_TableEditorDialog> createState() => _TableEditorDialogState();
}

class _TableEditorDialogState extends State<_TableEditorDialog> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _capacityCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.initialLabel ?? '');
    _capacityCtrl =
        TextEditingController(text: widget.initialCapacity.toString());
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialLabel != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit table' : 'Add table'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Table 9',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capacityCtrl,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Enter a valid capacity';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              _TableDraft(
                label: _labelCtrl.text.trim(),
                capacity: int.parse(_capacityCtrl.text.trim()),
              ),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.saffron),
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
