import 'package:flutter/material.dart';
import 'account_auth_pill.dart';

/// RoleSwitcherChip is now unified into AccountAuthPill.
/// Users cannot arbitrarily spoof roles; real accounts & permissions are enforced.
class RoleSwitcherChip extends StatelessWidget {
  final bool compact;

  const RoleSwitcherChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return AccountAuthPill(compact: compact);
  }
}
