import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../core/auth/family_auth.dart';

/// The signed-in Google account: picture (or initial), name and e-mail,
/// with a small Premium badge.
class AccountHeader extends StatelessWidget {
  final FamilyAccount account;
  final bool premium;
  const AccountHeader({super.key, required this.account, this.premium = false});

  @override
  Widget build(BuildContext context) {
    final name = account.name?.trim();
    final email = account.email;
    final initial = (name?.isNotEmpty ?? false)
        ? name!.characters.first.toUpperCase()
        : (email?.isNotEmpty ?? false)
        ? email!.characters.first.toUpperCase()
        : '?';
    final photo = account.photoUrl;
    return Row(
      key: const ValueKey('account-header'),
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: SegColors.primarySoft,
              foregroundImage: photo == null ? null : NetworkImage(photo),
              child: Text(
                initial,
                style: SegText.heading.copyWith(color: SegColors.primaryDeep),
              ),
            ),
            if (premium)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 18,
                    color: SegColors.accentStrong,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: SegSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name != null && name.isNotEmpty)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SegText.heading.copyWith(color: SegColors.ink),
                ),
              if (email != null)
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SegText.caption.copyWith(color: SegColors.inkSoft),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
