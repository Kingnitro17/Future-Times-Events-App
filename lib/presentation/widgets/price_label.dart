import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/event_model.dart';

class PriceLabel extends StatelessWidget {
  const PriceLabel({
    super.key,
    required this.isFree,
    required this.ticketClasses,
    this.compact = false,
  });

  final bool isFree;
  final List<TicketClass> ticketClasses;
  final bool compact;

  String get _label {
    final freeCount = ticketClasses.where((ticket) => ticket.free).length;
    final paidClasses =
        ticketClasses.where((ticket) => !ticket.free).toList(growable: false);
    if (isFree && freeCount > 0 && paidClasses.isEmpty) return 'Free';
    if (paidClasses.isNotEmpty) {
      final cheapest = paidClasses.reduce(
        (a, b) => (a.cost?.value ?? 0x7fffffff) <= (b.cost?.value ?? 0x7fffffff)
            ? a
            : b,
      );
      return 'Starting from ${cheapest.cost?.display ?? '\$?'}';
    }
    return isFree ? 'Free' : 'View tickets';
  }

  @override
  Widget build(BuildContext context) => Text(
        _label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.micro.copyWith(
          color: AppColors.purple,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w800,
        ),
      );
}
