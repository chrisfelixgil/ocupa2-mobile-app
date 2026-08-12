import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../viewmodels/make_payment_status.dart';
import '../viewmodels/make_payment_view_model.dart';

/// AJUSTAR: se asume que se llega a esta vista ya con un `offerId`
/// (por ejemplo desde el detalle de una oferta). Si necesitas elegir la
/// oferta desde aquí, agrega un selector.
///
/// NOTA: no se usan AppTextField / AppErrorMessage / PrimaryButton de
/// core/widgets porque esos archivos existen vacíos (son de otros
/// integrantes, pendientes de implementar). Se usan widgets nativos de
/// Flutter mientras tanto.
class MakePaymentView extends StatefulWidget {
  final String offerId;

  const MakePaymentView({super.key, required this.offerId});

  @override
  State<MakePaymentView> createState() => _MakePaymentViewState();
}

class _MakePaymentViewState extends State<MakePaymentView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController(text: 'DOP');

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<MakePaymentViewModel>();
    final ok = await viewModel.pay(
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      currency: _currencyController.text.trim(),
      cardNumber: '4242424242424242',
      cvv: '123',
      expMonth: 12,
      expYear: 2030,
      cardholder: 'Proveedor',
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago simulado realizado')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MakePaymentViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Realizar pago')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currencyController,
                decoration: const InputDecoration(
                  labelText: 'Moneda',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              if (viewModel.status == MakePaymentStatus.error &&
                  viewModel.errorMessage != null)
                Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 12),
              if (viewModel.isSubmitting)
                Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Pagar'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
