import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/payments/data/models/payment.dart';
import 'package:ocupa2/features/payments/data/models/payment_status.dart';

const Color _successGreen = Color(0xFF16A34A);
const Color _discardRed = Color(0xFFEF4444);

class PaymentCard extends StatelessWidget {
  const PaymentCard({
    required this.payment,
    this.onTap,
    super.key,
  });

  final Payment payment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String concept = (payment.concept ?? '').trim().isNotEmpty
        ? payment.concept!.trim()
        : 'Pago';
    final String? reference = payment.reference?.trim();

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _amountLabel(payment),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(status: payment.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                concept,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (reference != null && reference.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  'ID de Ref: $reference',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _listDateLabel(payment.createdAt),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                      ),
                    ),
                  ),
                  const Row(
                    children: <Widget>[
                      Text(
                        'Ver detalle',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      PaymentStatus.completed => _successGreen,
      PaymentStatus.failed => _discardRed,
      PaymentStatus.pending => AppColors.primary,
      PaymentStatus.unknown => AppColors.text,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _amountLabel(Payment payment) {
  final String amount = payment.amount.toStringAsFixed(2);
  final String currency = payment.currency.toUpperCase();
  if (currency == 'USD' || currency == 'US\$') {
    return 'US\$$amount';
  }
  if (currency == 'DOP' || currency == 'RD' || currency == 'RD\$') {
    return 'RD\$$amount';
  }
  return '$currency $amount';
}

String _listDateLabel(DateTime? value) {
  if (value == null) {
    return 'Sin fecha';
  }

  final DateTime local = value.isUtc ? value.toLocal() : value;
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(local.year, local.month, local.day);
  final String time = _timeLabel(local);

  if (day == today) {
    return 'Hoy, $time';
  }
  if (day == today.subtract(const Duration(days: 1))) {
    return 'Ayer, $time';
  }

  const List<String> months = <String>[
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  return '${local.day} de ${months[local.month - 1]}, ${local.year}';
}

String _timeLabel(DateTime local) {
  final int hour = local.hour > 12
      ? local.hour - 12
      : (local.hour == 0 ? 12 : local.hour);
  final String minute = local.minute.toString().padLeft(2, '0');
  final String suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
