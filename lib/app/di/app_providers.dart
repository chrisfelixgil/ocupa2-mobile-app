import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final List<SingleChildWidget> providers = <SingleChildWidget>[
      // Registrar providers globales aqui (SessionViewModel, AuthViewModel, etc.)
    ];

    if (providers.isEmpty) {
      return child;
    }

    return MultiProvider(providers: providers, child: child);
  }
}
