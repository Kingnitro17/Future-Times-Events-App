import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../data/repositories/likes_repository.dart';

class LikeButton extends StatefulWidget {
  const LikeButton({
    super.key,
    required this.eventId,
    this.initialCount,
    this.compact = false,
  });

  final String eventId;
  final int? initialCount;
  final bool compact;

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  final _repository = LikesRepository();
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  int _count = 0;
  bool _isLiked = false;
  bool _isBusy = false;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount ?? 0;
    _animationController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_animationController);
    _loadState();
  }

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      _count = widget.initialCount ?? 0;
      _isLiked = false;
      _isBusy = false;
      _hasInteracted = false;
      _loadState();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final eventId = widget.eventId;
    try {
      final countFuture = _repository.getLikeCount(eventId);
      final likedFuture = _repository.hasLiked(eventId);
      final count = await countFuture;
      final liked = await likedFuture;
      if (!mounted || eventId != widget.eventId || _hasInteracted) return;
      setState(() {
        _count = count;
        _isLiked = liked;
      });
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            '[likes] Failed to load state for ${widget.eventId}: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isBusy) return;
    final eventId = widget.eventId;
    final wasLiked = _isLiked;
    final previousCount = _count;
    setState(() {
      _isBusy = true;
      _hasInteracted = true;
      _isLiked = !wasLiked;
      _count = (_count + (wasLiked ? -1 : 1)).clamp(0, 1 << 31);
    });
    HapticFeedback.selectionClick();
    if (!wasLiked) _animationController.forward(from: 0);

    try {
      if (wasLiked) {
        await _repository.unlikeEvent(eventId);
      } else {
        await _repository.likeEvent(eventId);
      }
    } catch (error) {
      if (!mounted || eventId != widget.eventId) return;
      setState(() {
        _isLiked = wasLiked;
        _count = previousCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update like: $error')),
      );
    } finally {
      if (mounted && eventId == widget.eventId) {
        setState(() => _isBusy = false);
      }
    }
  }

  String _formattedCount() {
    if (_count > 999) {
      final thousands = _count / 1000;
      return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}K';
    }
    return '$_count';
  }

  @override
  Widget build(BuildContext context) {
    final color = _isLiked ? const Color(0xFFE53935) : AppColors.textSecondary;
    return Semantics(
      label: _isLiked
          ? 'Unlike event, $_count likes'
          : 'Like event, $_count likes',
      button: true,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: widget.compact
              ? Colors.white.withValues(alpha: .92)
              : Colors.white,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: _toggleLike,
            customBorder: const StadiumBorder(),
            child: Container(
              constraints: BoxConstraints(minHeight: widget.compact ? 34 : 42),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 8 : 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: color,
                    size: widget.compact ? 17 : 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formattedCount(),
                    style: TextStyle(
                      color: color,
                      fontSize: widget.compact ? 11 : 13,
                      fontWeight: FontWeight.w700,
                    ),
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
