// views/payment_detail_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ocupa2/features/payments/data/models/payment.dart';

class PaymentDetailView extends StatelessWidget {
  final Payment payment;

  const PaymentDetailView({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final formattedDate = payment.createdAt != null
        ? DateFormat('dd/MM/yyyy hh:mm a').format(payment.createdAt!)
        : 'No disponible';
    final formattedAmount =
        '${payment.amount.toStringAsFixed(2)} ${payment.currency}';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailRow(label: 'Concepto', value: payment.concept ?? '-'),
          _DetailRow(label: 'Monto', value: formattedAmount),
          _DetailRow(label: 'Estado', value: payment.status.name),
          _DetailRow(label: 'Fecha', value: formattedDate),
          _DetailRow(
            label: 'Tarjeta',
            value: payment.cardLast4 != null
                ? '**** ${payment.cardLast4}'
                : 'No disponible',
          ),
          _DetailRow(
            label: 'Titular',
            value: payment.cardholder ?? 'No disponible',
          ),
          _DetailRow(
            label: 'Referencia',
            value: payment.reference ?? 'No disponible',
          ),
          if (payment.declineReason != null)
            _DetailRow(
              label: 'Motivo de rechazo',
              value: payment.declineReason!,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}