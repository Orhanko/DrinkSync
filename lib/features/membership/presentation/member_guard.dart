import 'package:flutter/material.dart';
import '../../membership/data/membership_repository.dart';

class MemberGuard extends StatelessWidget {
  final String cafeId;
  final Widget Function(BuildContext, String? role) builder;
  const MemberGuard({super.key, required this.cafeId, required this.builder});

  @override
  Widget build(BuildContext context) {
    final repo = MembershipRepository();
    return StreamBuilder<String?>(
      stream: repo.roleStream(cafeId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: Text('Nemate pristup ovom kafiću.')));
        }
        return builder(context, snap.data);
      },
    );
  }
}
