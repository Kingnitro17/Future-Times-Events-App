import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/wallet_item.dart';

class WalletItemCard extends StatelessWidget {
  const WalletItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final WalletItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.statusLabel);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_icon(item.kind), color: AppColors.purple),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(item.statusLabel,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ),
                        Text(_relative(item.createdAt),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              if (item.qrPayload != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    tooltip: 'View QR',
                    onPressed: onTap,
                    icon: const Icon(Icons.qr_code_2_rounded,
                        color: AppColors.purple),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _icon(String kind) => switch (kind) {
        'ticket' => Icons.confirmation_number_rounded,
        'ride' => Icons.directions_car_rounded,
        'reservation' => Icons.table_restaurant_rounded,
        'order' => Icons.restaurant_rounded,
        'payment' => Icons.receipt_long_rounded,
        _ => Icons.wallet_rounded,
      };

  static Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value.contains('paid') ||
        value.contains('active') ||
        value.contains('issued')) {
      return AppColors.success;
    }
    if (value.contains('used') || value.contains('checked')) {
      return AppColors.purple;
    }
    if (value.contains('failed') ||
        value.contains('cancel') ||
        value.contains('refund')) {
      return AppColors.error;
    }
    return AppColors.textMuted;
  }

  static String _relative(DateTime date) {
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }
}
