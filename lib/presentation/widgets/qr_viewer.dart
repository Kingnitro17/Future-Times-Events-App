import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/wallet_item.dart';

class QrViewer extends StatelessWidget {
  const QrViewer({super.key, required this.item});

  final WalletItem item;

  static Future<void> show(BuildContext context, WalletItem item) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => QrViewer(item: item),
      );

  @override
  Widget build(BuildContext context) {
    final payload = item.qrPayload;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          if (payload == null)
            const Text('This item does not have a QR code.')
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: payload,
                size: 230,
                backgroundColor: Colors.white,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Reference: ${_reference(item)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: _reference(item)));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reference copied')));
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy reference'),
              ),
              FilledButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: '${item.title}\nReference: ${_reference(item)}',
                    subject: item.title,
                  ),
                ),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
            ],
          ),
          if (item.kind == 'ticket') ...[
            const SizedBox(height: 16),
            const Text('Show this at the gate',
                style: TextStyle(
                    color: AppColors.purple, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  static String _reference(WalletItem item) => switch (item) {
        WalletItemTicket(:final ticketNumber) => ticketNumber,
        WalletItemPayment(:final id) => id,
        _ => item.id,
      };
}
