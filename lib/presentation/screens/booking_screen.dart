import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/event_model.dart';
import '../../logic/blocs/booking/booking_bloc.dart';
import '../../logic/blocs/booking/booking_event.dart';
import '../../logic/blocs/booking/booking_state.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/glassmorphism_card.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key, required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingSuccess) {
          _showSuccessSheet(context, state);
        }
        if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMedium),
          ));
        }
      },
      builder: (context, state) {
        if (state is BookingExternalCheckout) {
          return _WebViewScreen(url: state.checkoutUrl, event: event);
        }
        return _BookingBody(event: event, state: state);
      },
    );
  }

  void _showSuccessSheet(BuildContext context, BookingSuccess state) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(state: state),
    ).then((_) {
      context.read<BookingBloc>().add(const ResetBooking());
      Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }
}

// ── Main Booking Body ─────────────────────────────────────────────────────────

class _BookingBody extends StatelessWidget {
  const _BookingBody({required this.event, required this.state});
  final EventModel event;
  final BookingState state;

  bool get _isLoading =>
      state is BookingProcessing || state is BookingAwaitingPayment;

  @override
  Widget build(BuildContext context) {
    final processing =
        state is BookingProcessing ? state as BookingProcessing : null;
    final awaiting = state is BookingAwaitingPayment
        ? state as BookingAwaitingPayment
        : null;

    final ticket = processing?.selectedTicket ?? awaiting?.selectedTicket;
    final quantity = processing?.quantity ?? awaiting?.quantity ?? 1;
    final total = ticket != null && !ticket.free
        ? (ticket.cost?.value ?? 0) * quantity
        : 0;

    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppTheme.charcoal,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            context.read<BookingBloc>().add(const CancelBooking());
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Order Summary ──────────────────────────────────────────────
            Text('Order Summary',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _OrderSummaryCard(
                event: event,
                ticket: ticket,
                quantity: quantity,
                totalCents: total),
            const SizedBox(height: 28),

            // ── Payment ────────────────────────────────────────────────────
            Text('Payment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _PaymentInfoCard(),
            const SizedBox(height: 32),

            // ── CTA ────────────────────────────────────────────────────────
            AdaptiveButton(
              label: ticket != null && !ticket.free
                  ? 'Pay ${ticket.cost?.display ?? ''}'
                  : 'Complete Registration',
              loading: _isLoading,
              icon: Icons.lock_rounded,
              onPressed: _isLoading
                  ? null
                  : () {
                      if (awaiting != null) {
                        context.read<BookingBloc>().add(ConfirmPayment(
                            clientSecret: awaiting.clientSecret));
                      }
                    },
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 13, color: AppTheme.subtleGrey),
                const SizedBox(width: 6),
                Text('Secured by Stripe',
                    style: Theme.of(context).textTheme.labelSmall),
              ]),
            ),
            const SizedBox(height: 80),
          ]),
        ),

        // ── Processing Overlay ──────────────────────────────────────────────
        if (_isLoading)
          Positioned.fill(
            child: GlassmorphismCard(
              blur: 16,
              opacity: 0.7,
              borderRadius: BorderRadius.zero,
              padding: EdgeInsets.zero,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                        color: AppTheme.electricIndigo, strokeWidth: 3),
                  ),
                  const SizedBox(height: 20),
                  Text('Processing Payment…',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Please do not close this screen',
                      style:
                          TextStyle(color: AppTheme.subtleGrey, fontSize: 13)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Order Summary Card ────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.event,
    required this.ticket,
    required this.quantity,
    required this.totalCents,
  });
  final EventModel event;
  final TicketClass? ticket;
  final int quantity;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.charcoalCard,
        borderRadius: AppTheme.radiusLarge,
        border: Border.all(color: AppTheme.charcoalBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(event.name.text,
            style: const TextStyle(
                color: AppTheme.pureWhite,
                fontWeight: FontWeight.w700,
                fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.charcoalBorder),
        const SizedBox(height: 16),
        if (ticket != null) ...[
          _Row(label: 'Ticket type', value: ticket!.name),
          const SizedBox(height: 10),
          _Row(label: 'Quantity', value: '$quantity'),
          const SizedBox(height: 10),
          _Row(
            label: 'Price per ticket',
            value: ticket!.free ? 'Free' : (ticket!.cost?.display ?? '—'),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.charcoalBorder),
          const SizedBox(height: 16),
          _Row(
            label: 'Total',
            value: ticket!.free
                ? 'Free'
                : ticket!.cost != null
                    ? '${ticket!.cost!.currency} ${(totalCents / 100).toStringAsFixed(2)}'
                    : '—',
            isTotal: true,
          ),
        ],
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isTotal = false});
  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: TextStyle(
              color: isTotal ? AppTheme.pureWhite : AppTheme.subtleGrey,
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              color: isTotal ? AppTheme.electricIndigo : AppTheme.offWhite,
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500)),
    ]);
  }
}

// ── Payment Info ──────────────────────────────────────────────────────────────

class _PaymentInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.charcoalCard,
        borderRadius: AppTheme.radiusLarge,
        border: Border.all(color: AppTheme.charcoalBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.credit_card_rounded,
              color: AppTheme.electricIndigo, size: 20),
          const SizedBox(width: 10),
          Text('Stripe Checkout',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppTheme.pureWhite)),
        ]),
        const SizedBox(height: 12),
        const Text(
          'You will be presented with Stripe\'s secure payment sheet to enter your card details.',
          style:
              TextStyle(color: AppTheme.subtleGrey, fontSize: 13, height: 1.5),
        ),
      ]),
    );
  }
}

// ── WebView Fallback ──────────────────────────────────────────────────────────

class _WebViewScreen extends StatefulWidget {
  const _WebViewScreen({required this.url, required this.event});
  final String url;
  final EventModel event;

  @override
  State<_WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<_WebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      appBar: AppBar(
        title: Text(widget.event.name.text,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.charcoal,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          Container(
            color: AppTheme.charcoal.withOpacity(0.92),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                      color: AppTheme.electricIndigo, strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                Text('Loading Eventbrite checkout…',
                    style: Theme.of(context).textTheme.titleMedium),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ── Success Sheet ─────────────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({required this.state});
  final BookingSuccess state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewPadding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.successGreen.withOpacity(0.4), width: 2),
          ),
          child: const Icon(Icons.check_rounded,
              color: AppTheme.successGreen, size: 36),
        ),
        const SizedBox(height: 20),
        Text('Booking Confirmed!',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(state.event.name.text,
            style: const TextStyle(color: AppTheme.subtleGrey, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('${state.quantity} × ${state.selectedTicket.name}',
            style: const TextStyle(
                color: AppTheme.electricIndigo,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 32),
        AdaptiveButton(
          label: 'Done',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ]),
    );
  }
}
