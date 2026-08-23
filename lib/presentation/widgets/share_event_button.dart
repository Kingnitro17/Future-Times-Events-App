import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';

class ShareEventButton extends StatefulWidget {
  const ShareEventButton({
    super.key,
    required this.event,
    this.size = 42,
  });

  final EventModel event;
  final double size;

  @override
  State<ShareEventButton> createState() => _ShareEventButtonState();
}

class _ShareEventButtonState extends State<ShareEventButton> {
  bool _scaleDown = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Share event',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scaleDown = true),
        onTapCancel: () => setState(() => _scaleDown = false),
        onTapUp: (_) => setState(() => _scaleDown = false),
        onTap: () async {
          HapticFeedback.lightImpact();
          await _shareEvent();
        },
        child: AnimatedScale(
          scale: _scaleDown ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.share_rounded,
                color: AppColors.textSecondary,
                size: widget.size * 0.50,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareEvent() async {
    final event = widget.event;
    final slug = event.slug;
    final url = 'https://futuretimesevents.com/events/$slug';
    final dateStr = DateFormat('EEE, d MMM • h:mm a').format(event.startsAt);
    final venueStr = event.venue?.name ?? event.venue?.address?.city ?? 'Zimbabwe';

    final text = 'Join me at ${event.name.text}!\n\n📅 $dateStr\n📍 $venueStr\n\n$url';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: event.name.text,
      ),
    );
  }
}
