import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/ft_service.dart';
import '../../data/repositories/ft_services_repository.dart';

class FtServicesSection extends StatefulWidget {
  FtServicesSection({super.key, FtServicesRepository? repository})
      : repository = repository ?? FtServicesRepository();

  final FtServicesRepository repository;

  @override
  State<FtServicesSection> createState() => _FtServicesSectionState();
}

class _FtServicesSectionState extends State<FtServicesSection> {
  late Future<List<FtService>> _servicesFuture;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _servicesFuture = widget.repository.listServices();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FtService>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const SizedBox.shrink();
          if (snapshot.connectionState != ConnectionState.done) {
            return _loadingSection();
          }
          final services = snapshot.data ?? const <FtService>[];
          if (services.isEmpty) return const SizedBox.shrink();

          final categories =
              services.map((service) => service.category).toSet();
          final visible = _selectedCategory == 'all'
              ? services
              : services
                  .where((service) => service.category == _selectedCategory)
                  .toList();

          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Setup your event with Future Times',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/ft-services'),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: _selectedCategory == 'all',
                        onTap: () => setState(() => _selectedCategory = 'all'),
                      ),
                      for (final category in categories)
                        _CategoryChip(
                          label: _categoryLabel(category),
                          selected: _selectedCategory == category,
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 292,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) =>
                        FtServiceCard(service: visible[index]),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _loadingSection() => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Setup your event with Future Times',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              height: 292,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => Shimmer.fromColors(
                  baseColor: AppColors.surfaceMuted,
                  highlightColor: Colors.white,
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  String _categoryLabel(String category) {
    if (category.isEmpty) return category;
    return '${category[0].toUpperCase()}${category.substring(1)}';
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.purple,
          backgroundColor: AppColors.surfaceMuted,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide.none,
          shape: const StadiumBorder(),
        ),
      );
}

class FtServiceCard extends StatelessWidget {
  const FtServiceCard({
    super.key,
    required this.service,
    this.fullWidth = false,
    this.onTap,
  });

  final FtService service;
  final bool fullWidth;
  final VoidCallback? onTap;

  void _open(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      context.push('/ft-services/${service.id}');
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: fullWidth ? double.infinity : 220,
        child: Material(
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () => _open(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: fullWidth ? 180 : 160,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (service.imageUrl != null &&
                          service.imageUrl!.trim().isNotEmpty)
                        Image.network(
                          service.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : const ColoredBox(
                                      color: AppColors.surfaceMuted),
                          errorBuilder: (_, __, ___) =>
                              const _ServiceImageFallback(),
                        )
                      else
                        const _ServiceImageFallback(),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .58),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _categoryLabel(service.category),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (fullWidth)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'From ${service.currency} ${service.basePrice.toStringAsFixed(0)} / ${service.unit}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 32,
                              child: FilledButton(
                                onPressed: () => _open(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Hire'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          _PriceAndHire(
                            service: service,
                            onPressed: () => _open(context),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  String _categoryLabel(String category) => category.isEmpty
      ? 'Service'
      : '${category[0].toUpperCase()}${category.substring(1)}';
}

class _PriceAndHire extends StatelessWidget {
  const _PriceAndHire({required this.service, required this.onPressed});

  final FtService service;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              'From ${service.currency} ${service.basePrice.toStringAsFixed(0)} / ${service.unit}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Hire'),
            ),
          ),
        ],
      );
}

class _ServiceImageFallback extends StatelessWidget {
  const _ServiceImageFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.brand),
        child: Center(
          child: Icon(Icons.handyman_outlined, color: Colors.white, size: 38),
        ),
      );
}
