import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';

const Color _successGreen = Color(0xFF16A34A);
const Color _discardRed = Color(0xFFEF4444);

class ContractListCard extends StatelessWidget {
  const ContractListCard({
    required this.contract,
    this.onTap,
    super.key,
  });

  final Contract contract;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String partyLabel = _partyLabel(contract);

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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          contract.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (partyLabel.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            partyLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: AppTypography.regular,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(contract: contract),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _dateLabel(contract),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 11,
                            fontWeight: AppTypography.regular,
                          ),
                        ),
                        Text(
                          _paymentLabel(contract),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
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
                        size: 16,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final String key = contract.isCancelled
        ? 'cancelled'
        : contract.isRejected
            ? 'rejected'
            : contract.isActive
                ? 'active'
                : 'pending';
    final (Color background, Color foreground) = switch (key) {
      'active' => (
          _successGreen.withValues(alpha: 0.08),
          _successGreen,
        ),
      'pending' => (
          AppColors.primary.withValues(alpha: 0.08),
          AppColors.primary,
        ),
      'rejected' => (
          _discardRed.withValues(alpha: 0.08),
          _discardRed,
        ),
      _ => (AppColors.border, AppColors.text),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        contract.displayStatusLabel,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}

String _partyLabel(Contract contract) {
  final String? name = contract.otherParty?.nombre.trim();
  if (name == null || name.isEmpty) {
    return '';
  }
  return contract.isContratante ? 'Contratado: $name' : 'Contratante: $name';
}

String _dateLabel(Contract contract) {
  final DateTime? date = contract.startDate ?? contract.createdAt;
  if (date == null) {
    return 'Fecha: Sin fecha';
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

  return 'Fecha: ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _paymentLabel(Contract contract) {
  if (contract.salary == null) {
    return 'A convenir';
  }

  final String amount = _group(contract.salary!.round());
  final String currency = (contract.currency ?? 'DOP').toUpperCase();
  if (currency == 'USD' || currency == 'US\$') {
    return 'US\$$amount';
  }
  return 'RD\$$amount';
}

String _group(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final int remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  if (value < 0) {
    return '-$buffer';
  }
  return buffer.toString();
}
