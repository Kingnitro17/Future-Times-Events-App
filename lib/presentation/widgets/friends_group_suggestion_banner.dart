import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FriendsGroupSuggestionBanner extends StatelessWidget {
  const FriendsGroupSuggestionBanner({
    super.key,
    required this.friendCount,
    required this.onCreateGroup,
    required this.onDismiss,
  });

  final int friendCount;
  final VoidCallback onCreateGroup;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.purple.withValues(alpha: .07),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, color: AppColors.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$friendCount of your friends are going. Coordinate?',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: onCreateGroup,
                child: const Text('Create group'),
              ),
              IconButton(
                tooltip: 'Not now',
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
        ),
      );
}
