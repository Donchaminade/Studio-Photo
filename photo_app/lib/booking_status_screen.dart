import 'package:Picon/api_service.dart';
import 'package:Picon/models/booking.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:Picon/widgets/picon_premium.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookingStatusScreen extends StatefulWidget {
  const BookingStatusScreen({super.key});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = ApiService.fetchUserBookings();
  }

  Future<void> _refreshBookings() async {
    setState(() {
      _bookingsFuture = ApiService.fetchUserBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final bookings = snapshot.data ?? const <Booking>[];
        int count(String s) => bookings.where((b) => b.status.name.toUpperCase() == s).length;
        Widget body;
        if (loading) {
          body = const PiconSkeletonList(count: 4);
        } else if (snapshot.hasError) {
          body = SizedBox(height: 460, child: AppInlineError(error: snapshot.error!, onRetry: _refreshBookings));
        } else if (bookings.isEmpty) {
          body = PiconCard(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Column(children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.event_busy_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('Aucune réservation',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text("Vous n'avez pas encore de réservations prévues.",
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        } else {
          body = Column(
            children: [for (var i = 0; i < bookings.length; i++) _premiumCard(bookings[i], i)],
          );
        }
        return PiconHeroScaffold(
          title: 'Mes réservations',
          subtitle: 'Suivez le statut de vos séances au studio.',
          icon: Icons.event_note_rounded,
          onRefresh: _refreshBookings,
          headerExtra: Row(children: [
            _stat('Total', loading ? '–' : '${bookings.length}'),
            _stat('En attente', loading ? '–' : '${count('PENDING')}'),
            _stat('Confirmées', loading ? '–' : '${count('CONFIRMED')}'),
          ]),
          child: body,
        );
      },
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5)),
          ]),
        ),
      );

  Widget _premiumCard(Booking booking, int index) {
    final info = _getStatusInfo(booking.status.name.toUpperCase());
    return Reveal(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: PiconCard(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 74,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(DateFormat('dd').format(booking.startTime),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  Text(const ['JANV', 'FÉVR', 'MARS', 'AVR', 'MAI', 'JUIN', 'JUIL', 'AOÛT', 'SEPT', 'OCT', 'NOV', 'DÉC'][booking.startTime.month - 1],
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(DateFormat('HH:mm').format(booking.startTime),
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      _statusBadge(info),
                      const Spacer(),
                      Text('#${booking.id}',
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 10),
                    Text(booking.title,
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    if (booking.description != null && booking.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(booking.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                    const SizedBox(height: 10),
                    Row(children: [
                      Flexible(child: _infoItem(Icons.style_rounded, booking.type.name.replaceAll('_', ' '))),
                      const SizedBox(width: 8),
                      Text('${booking.amount?.toStringAsFixed(0) ?? '0'} FCFA',
                          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // Ancienne mise en page (v2), conservée.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GeometricBackground(),
          RefreshIndicator(
            onRefresh: _refreshBookings,
            color: AppColors.primary,
            child: FutureBuilder<List<Booking>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const PiconSkeletonList(count: 4);
                }
                
                if (snapshot.hasError) {
                  return AppInlineError(
                    error: snapshot.error!,
                    onRetry: _refreshBookings,
                  );
                }

                final bookings = snapshot.data ?? [];
                if (bookings.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    return _buildBookingCard(bookings[index], index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBookingCard(Booking booking, int index) {
    final statusInfo = _getStatusInfo(booking.status.name.toUpperCase());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.primary.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statusBadge(statusInfo),
                  Text(
                    '#${booking.id}',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                booking.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (booking.description != null && booking.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  booking.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(child: _infoItem(Icons.calendar_today, DateFormat('dd MMM yyyy').format(booking.startTime))),
                  const SizedBox(width: 10),
                  Flexible(child: _infoItem(Icons.access_time, DateFormat('HH:mm').format(booking.startTime))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _infoItem(Icons.style, booking.type.name.replaceAll('_', ' '))),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${booking.amount?.toStringAsFixed(0) ?? '0'} FCFA',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _statusBadge(Map<String, dynamic> info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (info['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (info['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info['icon'] as IconData, color: info['color'] as Color, size: 16),
          const SizedBox(width: 6),
          Text(
            info['text'] as String,
            style: TextStyle(
              color: info['color'] as Color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary.withOpacity(0.6)),
        const SizedBox(width: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 100, color: AppColors.primary.withOpacity(0.1)),
              const SizedBox(height: 24),
              const Text(
                'Aucune réservation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous n\'avez pas encore de réservations prévues.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'CONFIRMED':
        return {'text': 'Confirmée', 'color': AppColors.success, 'icon': Icons.check_circle};
      case 'PENDING':
        return {'text': 'En attente', 'color': AppColors.warning, 'icon': Icons.hourglass_top};
      case 'CANCELLED':
        return {'text': 'Annulée', 'color': AppColors.error, 'icon': Icons.cancel};
      case 'COMPLETED':
        return {'text': 'Terminée', 'color': AppColors.primary, 'icon': Icons.task_alt};
      default:
        return {'text': status, 'color': AppColors.textSecondary, 'icon': Icons.help_outline};
    }
  }
}
