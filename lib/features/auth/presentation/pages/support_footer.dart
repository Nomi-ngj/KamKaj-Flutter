import 'package:flutter/material.dart';

import '../../../../design_system/components/components.dart';
import '../widgets/auth_widgets.dart';

/// "Need help? Contact Support".
class SupportFooter extends StatelessWidget {
  const SupportFooter({super.key});

  static const supportEmail = 'support@kamkaj.example';

  @override
  Widget build(BuildContext context) {
    return AuthFooterLink(
      prompt: 'Need help?',
      action: 'Contact Support',
      onTap: () => AppToast.show(context, 'Email us at $supportEmail'),
    );
  }
}
