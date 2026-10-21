import 'package:Picon/api_service.dart';
import 'package:Picon/models/booking.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_ui.dart';
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
        return {'text': 'Confirmée', 'color': Colors.green.shade700, 'icon': Icons.check_circle};
      case 'PENDING':
        return {'text': 'En attente', 'color': Colors.orange.shade700, 'icon': Icons.hourglass_top};
      case 'CANCELLED':
        return {'text': 'Annulée', 'color': Colors.red.shade700, 'icon': Icons.cancel};
      case 'COMPLETED':
        return {'text': 'Terminée', 'color': AppColors.primary, 'icon': Icons.task_alt};
      default:
        return {'text': status, 'color': Colors.grey.shade700, 'icon': Icons.help_outline};
    }
  }
}
