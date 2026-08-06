import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../events/data/event_repository.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/ft_widgets.dart';

class TicketSelectionScreen extends StatefulWidget {
  const TicketSelectionScreen({super.key, required this.slug});
  final String slug;

  @override
  State<TicketSelectionScreen> createState() => _TicketSelectionScreenState();
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  final _eventRepo = EventRepository();
  final _ticketRepo = TicketRepository();

  Event? _event;
  List<TicketType> _ticketTypes = [];
  final Map<String, int> _quantities = {};
  bool _loading = true;
  bool _claiming = false;
  String? _error;
  String? _claimError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final event = await _eventRepo.getEventBySlug(widget.slug);
      if (event == null) {
        setState(() { _error = 'Event not found.'; _loading = false; });
        return;
      }
      final types = await _eventRepo.getTicketTypes(event.id);
      if (mounted) {
        setState(() {
          _event = event;
          _ticketTypes = types;
          // Default quantity = 0
          for (final t in types) { _quantities[t.id] = 0; }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  int _totalSelected() =>
      _quantities.values.fold(0, (sum, q) => sum + q);

  double _totalPrice() {
    double total = 0;
    for (final type in _ticketTypes) {
      total += (type.price) * (_quantities[type.id] ?? 0);
    }
    return total;
  }

  Future<void> _proceed() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      context.go('/auth/login?return=/events/${widget.slug}/tickets');
      return;
    }

    if (_totalSelected() == 0) return;

    // Determine if paid or free
    final hasPaid = _ticketTypes.any(
      (t) => !t.isFree && (_quantities[t.id] ?? 0) > 0,
    );

    if (hasPaid) {
      // TODO Phase 6: route to EcoCash checkout
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paid checkout coming soon. Free tickets work now!',
          ),
        ),
      );
      return;
    }

    // Free claim
    setState(() { _claiming = true; _claimError = null; });
    try {
      final profile = authState.profile;
      // Claim first free ticket type selected
      for (final type in _ticketTypes) {
        final qty = _quantities[type.id] ?? 0;
        if (qty > 0 && type.isFree) {
          final result = await _ticketRepo.claimFreeTicket(
            eventId: _event!.id,
            ticketTypeId: type.id,
            attendeeName: profile.displayName,
            attendeeEmail: profile.email,
            attendeePhone: profile.phone,
          );
          if (mounted) {
            context.go('/tickets/${result.ticketId}');
          }
          return;
        }
      }
    } on Exception catch (e) {
      if (mounted) setState(() { _claimError = e.toString(); _claiming = false; });
    } finally {
      if (mounted && _claiming) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Get Tickets')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: FtErrorState(message: _error!, onRetry: _load),
      );
    }

    final event = _event!;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get Tickets', style: AppTypography.h4.copyWith(color: AppColors.text)),
            Text(
              event.title,
              style: AppTypography.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _ticketTypes.isEmpty
          ? const FtEmptyState(
              message: 'No tickets are available for this event.',
              icon: Icons.confirmation_number_outlined,
            )
          : Column(
              children: [
                // Ticket type list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      if (_claimError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Text(
                            _claimError!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ..._ticketTypes.map((type) => _TicketTypePicker(
                            type: type,
                            quantity: _quantities[type.id] ?? 0,
                            onChanged: (q) {
                              setState(() => _quantities[type.id] = q);
                            },
                          )),
                    ],
                  ),
                ),

                // Sticky bottom
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        // Total
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _totalSelected() == 0
                                    ? 'Select tickets'
                                    : '${ _totalSelected()} ticket${_totalSelected() > 1 ? 's' : ''}',
                                style: AppTypography.caption,
                              ),
                              Text(
                                _totalPrice() == 0
                                    ? 'Free'
                                    : 'USD ${_totalPrice().toStringAsFixed(0)}',
                                style: AppTypography.price.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FtGradientButton(
                            label: _totalPrice() == 0 ? 'Claim Free' : 'Proceed',
                            onPressed: _totalSelected() > 0 ? _proceed : null,
                            isLoading: _claiming,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TicketTypePicker extends StatelessWidget {
  const _TicketTypePicker({
    required this.type,
    required this.quantity,
    required this.onChanged,
  });
  final TicketType type;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final available = type.isAvailable && type.isSalesOpen;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: quantity > 0 ? AppColors.violet : AppColors.border,
          width: quantity > 0 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.name, style: AppTypography.bodyMedium),
                if (type.description.isNotEmpty)
                  Text(type.description, style: AppTypography.caption),
                const SizedBox(height: 4),
                Text(
                  type.isFree
                      ? 'Free'
                      : 'USD ${type.price.toStringAsFixed(0)}',
                  style: AppTypography.price.copyWith(
                    fontSize: 16,
                    color: type.isFree ? AppColors.success : AppColors.text,
                  ),
                ),
                if (!available)
                  Text(
                    type.quantityAvailable == 0 ? 'Sold out' : 'Not available',
                    style: AppTypography.caption.copyWith(color: AppColors.error),
                  ),
              ],
            ),
          ),
          if (available)
            Row(
              children: [
                _QtyButton(
                  icon: Icons.remove_rounded,
                  onPressed: quantity > 0
                      ? () => onChanged((quantity - 1).clamp(0, type.claimLimitPerContact))
                      : null,
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$quantity',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                _QtyButton(
                  icon: Icons.add_rounded,
                  onPressed: quantity < type.claimLimitPerContact
                      ? () => onChanged((quantity + 1).clamp(0, type.claimLimitPerContact))
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      color: onPressed != null ? AppColors.violet : AppColors.border,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.backgroundTertiary,
        minimumSize: const Size(36, 36),
        shape: const CircleBorder(),
      ),
    );
  }
}
