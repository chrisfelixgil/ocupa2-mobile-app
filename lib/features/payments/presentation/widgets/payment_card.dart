import 'package:flutter/material.dart';

import '../../data/models/payment.dart';
import '../../data/models/payment_status.dart';

class PaymentCard extends StatelessWidget {
  final Payment payment;

  const PaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text('${payment.amount} ${payment.currency}'),
        trailing: Chip(label: Text(payment.status.label)),
      ),
    );
  }
}
