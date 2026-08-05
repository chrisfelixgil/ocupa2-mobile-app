import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(icon, size: 42, color: AppColors.cream),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: child,
                    ),
                    if (footer != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
