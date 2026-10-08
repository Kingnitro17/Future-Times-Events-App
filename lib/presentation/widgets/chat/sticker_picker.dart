import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class StickerPicker extends StatelessWidget {
  const StickerPicker({
    super.key,
    this.onEmojiSelected,
  });

  final ValueChanged<String>? onEmojiSelected;

  static const List<Map<String, List<String>>> _categories = [
    {
      'Reactions': ['❤️', '👍', '🔥', '👏', '🎉', '😮', '😂', '😢', '💯', '✨', '💪', '🎊'],
    },
    {
      'Faces': ['😀', '😄', '😁', '😎', '🙂', '😅', '😬', '🥳', '🤩', '😍', '😴', '🤠'],
    },
    {
      'Animals': ['🐶', '🐱', '🦊', '🐼', '🐸', '🐵', '🦄', '🐧', '🐻', '🦁', '🐮', '🐰'],
    },
    {
      'Food': ['🍕', '🍔', '🌮', '🍣', '🍰', '🍩', '🍉', '🍇', '🍓', '🥤', '☕', '🍟'],
    },
    {
      'Party': ['🎈', '🎁', '🎊', '🎉', '🎂', '🍾', '🥂', '🎵', '🎶', '🎭', '🎤', '🎷'],
    },
    {
      'Objects': ['🎧', '📸', '💼', '🧢', '🚀', '🎒', '⚽', '🎳', '📚', '🕺', '🌈', '⭐'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: DefaultTabController(
        length: _categories.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              dividerHeight: 0,
              tabs: _categories
                  .map((category) => Tab(text: category.keys.first))
                  .toList(),
              labelColor: AppColors.purple,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.purple,
            ),
            Expanded(
              child: TabBarView(
                children: _categories.map((category) {
                  final emojis = category.values.first;
                  return GridView.count(
                    crossAxisCount: 6,
                    padding: const EdgeInsets.all(12),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: emojis
                        .map(
                          (emoji) => InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              onEmojiSelected?.call(emoji);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Text(
                                emoji,
                                style: AppText.h2,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
