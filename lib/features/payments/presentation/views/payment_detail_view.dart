import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/payments/data/models/payment.dart';
import 'package:ocupa2/features/payments/data/models/payment_status.dart';

const Color _successGreen = Color(0xFF16A34A);
const Color _discardRed = Color(0xFFEF4444);

class PaymentDetailView extends StatelessWidget {
  const PaymentDetailView({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final String concept = (payment.concept ?? '').trim().isNotEmpty
        ? payment.concept!.trim()
        : 'Pago';
    final String? last4 = payment.cardLast4?.trim();
    final String? cardholder = payment.cardholder?.trim();
    final String? reference = payment.reference?.trim();
    final String? declineReason = payment.declineReason?.trim();

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const _PaymentsBottomNav(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: <Widget>[
                  Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.chevron_left,
                          size: 16,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Detalle del pago',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Ocupa2',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: <Widget>[
                          _StatusStamp(status: payment.status),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          _MetaRow(label: 'Concepto', value: concept),
                          const SizedBox(height: 14),
                          _MetaRow(
                            label: 'Estado',
                            child: _StatusBadge(status: payment.status),
                          ),
                          const SizedBox(height: 14),
                          _MetaRow(
                            label: 'Monto total',
                            value: _amountLabel(payment),
                            valueColor: AppColors.primary,
                            valueWeight: AppTypography.bold,
                          ),
                          const SizedBox(height: 14),
                          _MetaRow(
                            label: 'Fecha de pago',
                            value: _listDateLabel(payment.createdAt),
                          ),
                          if (last4 != null && last4.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 14),
                            _MetaRow(
                              label: 'Método de pago',
                              value: 'Tarjeta ···· $last4',
                            ),
                          ],
                          if (cardholder != null &&
                              cardholder.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 14),
                            _MetaRow(label: 'Titular', value: cardholder),
                          ],
                          if (reference != null &&
                              reference.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 14),
                            _MetaRow(
                              label: 'Número de referencia',
                              value: reference,
                            ),
                          ],
                          const SizedBox(height: 14),
                          const _MetaRow(label: 'Emisor', value: 'Ocupa2'),
                          if (declineReason != null &&
                              declineReason.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 14),
                            _MetaRow(
                              label: 'Motivo de rechazo',
                              value: declineReason,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStamp extends StatelessWidget {
  const _StatusStamp({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    switch (status) {
      case PaymentStatus.completed:
        color = _successGreen;
        icon = Icons.verified;
        title = '¡Pago exitoso!';
        subtitle = 'La transacción ha sido completada';
      case PaymentStatus.pending:
        color = AppColors.primary;
        icon = Icons.schedule;
        title = 'Pago pendiente';
        subtitle = 'La transacción está en proceso';
      case PaymentStatus.failed:
        color = _discardRed;
        icon = Icons.cancel;
        title = 'Pago rechazado';
        subtitle = 'La transacción no pudo completarse';
      case PaymentStatus.unknown:
        color = AppColors.text;
        icon = Icons.info_outline;
        title = 'Pago';
        subtitle = 'Estado no disponible';
    }

    return Column(
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 24,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: AppTypography.regular,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    this.value,
    this.child,
    this.valueColor,
    this.valueWeight,
  });

  final String label;
  final String? value;
  final Widget? child;
  final Color? valueColor;
  final FontWeight? valueWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: AppTypography.regular,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child:
                child ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: valueColor ?? AppColors.text,
                    fontSize: 14,
                    fontWeight: valueWeight ?? AppTypography.medium,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class _PaymentsBottomNav extends StatelessWidget {
  const _PaymentsBottomNav();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                onTap: () => context.goNamed(AppRouteNames.home),
              ),
              _NavItem(
                icon: Icons.search,
                label: 'Explorar',
                onTap: () => context.pushNamed(AppRouteNames.jobSearchExplore),
              ),
              _NavItem(
                icon: Icons.add,
                label: 'Publicar',
                prominent: true,
                onTap: () => context.pushNamed(AppRouteNames.jobPostingCreate),
              ),
              _NavItem(
                icon: Icons.history,
                label: 'Actividad',
                onTap: () => context.pushNamed(AppRouteNames.activityHub),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                selected: true,
                onTap: () => context.goNamed(AppRouteNames.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.prominent = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool prominent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.text;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (prominent)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, size: 24, color: AppColors.onPrimary),
              )
            else
              Icon(icon, size: 22, color: color),
            if (!prominent) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : AppTypography.medium,
                ),
              ),
            ],
          ],
        ),
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
