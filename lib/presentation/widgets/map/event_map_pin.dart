import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/category_colors.dart';
import '../event_network_image.dart';

class EventMapPin extends StatelessWidget {
  final String? eventImageUrl;
  final String eventName;
  final String? category;
  final bool isSelected;
  final VoidCallback? onTap;

  const EventMapPin({
    super.key,
    this.eventImageUrl,
    required this.eventName,
    this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColors.forCategory(category);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.spring,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PinHead(
                  imageUrl: eventImageUrl,
                  color: categoryColor,
                  selected: isSelected,
                ),
                if (eventName.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _EventNamePill(eventName: eventName),
                ],
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: CustomPaint(
                size: const Size(16, 12),
                painter: _PinTailPainter(categoryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinHead extends StatelessWidget {
  const _PinHead({
    required this.imageUrl,
    required this.color,
    required this.selected,
  });

  final String? imageUrl;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: EventNetworkImage(
          url: imageUrl,
          fallbackIcon: Icons.event_rounded,
          semanticLabel: 'Event artwork',
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => oldDelegate.color != color;
}

class _EventNamePill extends StatelessWidget {
  const _EventNamePill({required this.eventName});

  final String eventName;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          eventName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: .1,
          ),
        ),
      );
}
