import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../data/repositories/auth_repository.dart';

class SaveHeartButton extends StatefulWidget {
  const SaveHeartButton({
    super.key,
    required this.eventId,
    required this.repository,
    required this.authRepository,
    this.size = 42,
  });

  final String eventId;
  final SavedEventsRepository repository;
  final AuthRepository authRepository;
  final double size;

  @override
  State<SaveHeartButton> createState() => _SaveHeartButtonState();
}

class _SaveHeartButtonState extends State<SaveHeartButton> {
  bool _scaleDown = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repository,
      builder: (context, _) {
        final isSaved = widget.repository.isSaved(widget.eventId);

        return Semantics(
          label: isSaved ? 'Remove from saved' : 'Save event',
          button: true,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _scaleDown = true),
            onTapCancel: () => setState(() => _scaleDown = false),
            onTapUp: (_) => setState(() => _scaleDown = false),
            onTap: () async {
              HapticFeedback.lightImpact();

              if (!widget.authRepository.isSignedIn) {
                _promptAuth(context);
                return;
              }

              // Optimistic UI toggle
              await widget.repository.toggleSave(widget.eventId);
            },
            child: AnimatedScale(
              scale: _scaleDown ? 0.88 : (isSaved ? 1.06 : 1.0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSaved
                        ? const Color(0xFFFF2B56).withValues(alpha: 0.3)
                        : AppColors.border,
                    width: 1.2,
                  ),
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
                    isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isSaved
                        ? const Color(0xFFFF2B56)
                        : AppColors.textSecondary,
                    size: widget.size * 0.52,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _promptAuth(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Sign in or sign up to save events to your shortlist.'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () {
            // Trigger auth modal/navigation
          },
        ),
      ),
    );
  }
}
