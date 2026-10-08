import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/wallet_item.dart';
import 'common/glass_card.dart';
import 'event_network_image.dart';

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
    final color = item is WalletItemPayment
        ? _paymentStatusColor(item.statusLabel)
        : _statusColor(item.statusLabel);
    final order = item is WalletItemOrder ? item as WalletItemOrder : null;
    final preorder =
        item is WalletItemPreorder ? item as WalletItemPreorder : null;
    final payment = item is WalletItemPayment ? item as WalletItemPayment : null;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _artwork(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  payment == null ? item.subtitle : _relative(item.createdAt),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                if (payment != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    _paymentAmount(payment),
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (order != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${order.itemCount} '
                    '${order.itemCount == 1 ? 'item' : 'items'} · '
                    '${order.currency} ${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
                if (preorder != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${preorder.quantity} × ${preorder.currency} '
                    '${preorder.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (item.qrPayload != null)
                IconButton(
                  tooltip: 'View QR',
                  onPressed: onTap,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.purple),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _artwork() {
    final imageUrl = item.imageUrl?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return EventNetworkImage(
        url: imageUrl,
        semanticLabel: '${item.title} artwork',
        fallbackIcon: _icon(item.kind),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: .12),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon(item.kind), color: AppColors.purple),
    );
  }

  static String _paymentAmount(WalletItemPayment payment) {
    final amount = payment.amount.toStringAsFixed(2);
    return payment.currency.toUpperCase() == 'USD'
        ? '\$$amount'
        : '${payment.currency} $amount';
  }

  static IconData _icon(String kind) => switch (kind) {
        'ticket' => Icons.confirmation_number_rounded,
        'ride' => Icons.directions_car_rounded,
        'reservation' => Icons.table_restaurant_rounded,
        'order' => Icons.restaurant_rounded,
        'ft_service' => Icons.handyman_rounded,
        'preorder' => Icons.shopping_bag_outlined,
        'payment' => Icons.receipt_long_rounded,
        _ => Icons.wallet_rounded,
      };

  static Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value == 'pending payment' || value == 'pending review') {
      return const Color(0xFFE6A700);
    }
    if (value == 'deposit paid') return const Color(0xFF2389FF);
    if (value == 'approved' || value == 'active') {
      return AppColors.success;
    }
    if (value == 'rejected') return AppColors.error;
    if (value == 'cancelled' || value == 'completed') {
      return AppColors.textMuted;
    }
    if (value.contains('paid') ||
        value.contains('active') ||
        value.contains('issued') ||
        value.contains('ready') ||
        value.contains('served') ||
        value.contains('complete')) {
      return AppColors.success;
    }
    if (value.contains('preparing')) {
      return AppColors.purple;
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

  static Color _paymentStatusColor(String status) => switch (status.toLowerCase()) {
        'paid' => AppColors.success,
        'pending' => const Color(0xFFE6A700),
        'refunded' => AppColors.error,
        'failed' => AppColors.textMuted,
        _ => AppColors.textMuted,
      };

  static String _relative(DateTime date) {
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }
}
