import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/event_model.dart';

/// Production-safe event artwork for Android and Flutter Web QA.
///
/// Several approved production image hosts do not return CORS headers. Flutter
/// Web's CanvasKit fetch path therefore cannot decode them, even though browsers
/// can display them in an HTML image element. Android uses the cached provider;
/// Web uses an HTML element where required so both targets render the same URL.
class EventNetworkImage extends StatelessWidget {
  const EventNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.semanticLabel = 'Event artwork',
    this.fallbackIcon = Icons.event_rounded,
  });

  factory EventNetworkImage.forEvent(
    EventModel event, {
    Key? key,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
  }) =>
      EventNetworkImage(
        key: key,
        url: event.logo?.original?.url ?? event.logo?.url,
        fit: fit,
        alignment: alignment,
        semanticLabel: '${event.name.text} artwork',
      );

  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final String semanticLabel;
  final IconData fallbackIcon;

  static const _unavailableHosts = {
    'b2-image-proxy.sahwigate.workers.dev',
  };

  static String? normalize(String? value) {
    final source = value?.trim();
    if (source == null || source.isEmpty) return null;
    final uri = Uri.tryParse(source);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    if (_unavailableHosts.contains(uri.host.toLowerCase())) return null;
    return uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = normalize(url);
    if (imageUrl == null) return _fallback();

    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const _ImageSkeleton(),
        errorBuilder: (_, error, __) {
          _debugFailure(imageUrl, error);
          return _fallback();
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholderFadeInDuration: const Duration(milliseconds: 100),
      placeholder: (_, __) => const _ImageSkeleton(),
      errorWidget: (_, __, error) {
        _debugFailure(imageUrl, error);
        return _fallback();
      },
    );
  }

  void _debugFailure(String imageUrl, Object error) {
    if (kDebugMode) {
      final uri = Uri.tryParse(imageUrl);
      debugPrint(
        '[event-image] load failed host=${uri?.host ?? 'invalid'} '
        'path=${uri?.path ?? ''} error=${error.runtimeType}',
      );
    }
  }

  Widget _fallback() => Semantics(
        image: true,
        label: '$semanticLabel unavailable',
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppGradients.brand),
            child: Center(
              child: Icon(fallbackIcon, color: Colors.white, size: 42),
            ),
          ),
        ),
      );
}

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.surfaceMuted),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: AppColors.purple.withValues(alpha: .35),
          ),
        ),
      );
}
