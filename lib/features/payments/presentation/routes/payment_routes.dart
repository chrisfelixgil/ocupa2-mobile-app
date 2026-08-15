import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/payment_repository.dart';
import '../viewmodels/make_payment_view_model.dart';
import '../viewmodels/my_payments_view_model.dart';
import '../views/make_payment_view.dart';
import '../views/my_payments_view.dart';

/// Requiere que app_routes.dart (AppRouteNames) tenga agregado:
///   static const String paymentsMyPayments = 'payments-my-payments';
///   static const String paymentsPay = 'payments-pay';
class PaymentRoutes {
  static const myPaymentsPath = '/my-payments';
  static const payPath = '/pay/:offerId';

  static List<RouteBase> get routes => [
        GoRoute(
          path: myPaymentsPath,
          name: AppRouteNames.paymentsMyPayments,
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => MyPaymentsViewModel(
              paymentRepository: context.read<PaymentRepository>(),
            ),
            child: const MyPaymentsView(),
          ),
        ),
        GoRoute(
          path: payPath,
          name: AppRouteNames.paymentsPay,
          builder: (context, state) {
            final offerId = state.pathParameters['offerId']!;
            return ChangeNotifierProvider(
              create: (context) => MakePaymentViewModel(
                paymentRepository: context.read<PaymentRepository>(),
              ),
              child: MakePaymentView(offerId: offerId),
            );
          },
        ),
      ];
}
