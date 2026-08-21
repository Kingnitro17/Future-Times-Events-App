import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/saved_events_repository.dart';

class SaveEventButton extends StatelessWidget {
  const SaveEventButton(
      {super.key,
      required this.eventId,
      required this.repository,
      this.onAuthenticationRequired,
      this.onSurface = false});
  final String eventId;
  final SavedEventsRepository repository;
  final VoidCallback? onAuthenticationRequired;
  final bool onSurface;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final saved = repository.isSaved(eventId);
          return IconButton(
            tooltip: saved ? 'Remove from saved events' : 'Save event',
            onPressed: () async {
              try {
                await repository.toggle(eventId);
              } on AuthFailure {
                onAuthenticationRequired?.call();
                if (onAuthenticationRequired == null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sign in from Profile to save events.'),
                  ));
                }
              } on AppFailure catch (failure) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(failure.message)));
                }
              }
            },
            style: onSurface
                ? IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .9),
                    foregroundColor: AppColors.text,
                  )
                : null,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  key: ValueKey(saved),
                  color: saved ? AppColors.purple : null),
            ),
          );
        },
      );
}
