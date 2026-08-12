import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../viewmodels/my_payments_status.dart';
import '../viewmodels/my_payments_view_model.dart';
import '../widgets/payment_card.dart';

class MyPaymentsView extends StatefulWidget {
  const MyPaymentsView({super.key});

  @override
  State<MyPaymentsView> createState() => _MyPaymentsViewState();
}

class _MyPaymentsViewState extends State<MyPaymentsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyPaymentsViewModel>().loadMyPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyPaymentsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pagos')),
      body: RefreshIndicator(
        onRefresh: () => context.read<MyPaymentsViewModel>().loadMyPayments(),
        child: Builder(
          builder: (_) {
            switch (viewModel.status) {
              case MyPaymentsStatus.idle:
              case MyPaymentsStatus.loading:
                return Center(child: CircularProgressIndicator());
              case MyPaymentsStatus.error:
                return ListView(
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        viewModel.errorMessage ?? 'Error al cargar pagos',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              case MyPaymentsStatus.loaded:
                if (viewModel.payments.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 40),
                      Center(child: Text('Aún no tienes pagos')),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.payments.length,
                  itemBuilder: (context, index) {
                    return PaymentCard(payment: viewModel.payments[index]);
                  },
                );
            }
          },
        ),
      ),
    );
  }
}
