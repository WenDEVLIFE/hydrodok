import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

// ── Data Model ─────────────────────────────────────────────────────────────

enum AccountStatus { flagged, underReview, cleared }

class ModeratedAccount {
  final String id;
  final String initials;
  final Color avatarColor;
  final String name;
  final String handle;
  final String role; // Farmer or Consumer
  final String flaggedReason;
  final int reportCount;
  final AccountStatus status;

  const ModeratedAccount({
    required this.id,
    required this.initials,
    required this.avatarColor,
    required this.name,
    required this.handle,
    required this.role,
    required this.flaggedReason,
    required this.reportCount,
    required this.status,
  });
}

const _accounts = <ModeratedAccount>[
  ModeratedAccount(
    id: '1',
    initials: 'J',
    avatarColor: Color(0xFF2979FF),
    name: 'J. Villanueva',
    handle: '@consumer_jv22',
    role: 'Consumer',
    flaggedReason: 'Flagged: did not pay after pickup (2 reports)',
    reportCount: 3,
    status: AccountStatus.flagged,
  ),
  ModeratedAccount(
    id: '2',
    initials: '"',
    avatarColor: ColorUtils.forestGreen,
    name: '"GreenHarvest Co-op"',
    handle: '@greenharvest_ph',
    role: 'Farmer',
    flaggedReason: 'Flagged: fake farm listing, no verified location',
    reportCount: 5,
    status: AccountStatus.flagged,
  ),
  ModeratedAccount(
    id: '3',
    initials: 'R',
    avatarColor: Color(0xFF2979FF),
    name: 'R. Domingo',
    handle: '@rdomingo_buyer',
    role: 'Consumer',
    flaggedReason: 'Flagged: harassment in community forum',
    reportCount: 1,
    status: AccountStatus.underReview,
  ),
  ModeratedAccount(
    id: '4',
    initials: 'M',
    avatarColor: ColorUtils.forestGreen,
    name: 'M. Espiritu',
    handle: '@mespiritu_farm',
    role: 'Farmer',
    flaggedReason: 'Cleared — verified real farm, no action taken',
    reportCount: 0,
    status: AccountStatus.cleared,
  ),
];

// ── Screen Widget ──────────────────────────────────────────────────────────

class AccountModerationScreen extends StatelessWidget {
  const AccountModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title & Subtitle ──────────────────────────────────────────
          Text(
            'Account Moderation',
            style: AppTypography.heading2(
              color: ColorUtils.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review flagged accounts and remove confirmed scams',
            style: AppTypography.bodyMedium(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // ── Warning Banner ────────────────────────────────────────────
          _buildWarningBanner(),
          const SizedBox(height: 24),

          // ── Accounts List ──────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              itemCount: _accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return _AccountCard(account: _accounts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light amber/orange
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ColorUtils.terracotta,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorUtils.terracotta.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              LucideIcons.alertTriangle,
              color: ColorUtils.terracotta,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3 accounts flagged by farmers this week for suspected scam activity',
                  style: AppTypography.subtitle2(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review evidence before removing an account — action cannot be undone',
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Account Card Widget ────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final ModeratedAccount account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: account.avatarColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              account.initials,
              style: AppTypography.heading4(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name, Role, Handle, Flagged Reason
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      account.name,
                      style: AppTypography.subtitle1(
                        color: ColorUtils.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        account.role,
                        style: AppTypography.caption(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  account.handle,
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  account.flaggedReason,
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Status & Report Count Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStatusBadge(account.status),
                if (account.reportCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${account.reportCount} ${account.reportCount == 1 ? 'report' : 'reports'}',
                    style: AppTypography.caption(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions Column
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildActionButtons(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AccountStatus status) {
    final (String label, Color bg) = switch (status) {
      AccountStatus.flagged => ('Flagged', ColorUtils.terracotta),
      AccountStatus.underReview => ('Under Review', const Color(0xFF2979FF)),
      AccountStatus.cleared => ('Cleared', ColorUtils.forestGreen),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.caption(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (account.status) {
      case AccountStatus.flagged:
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: Investigate action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                elevation: 0,
              ),
              child: Text(
                'Investigate',
                style: AppTypography.button(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Delete account action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84040),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                elevation: 0,
              ),
              child: Text(
                'Delete Account',
                style: AppTypography.button(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      case AccountStatus.underReview:
        return ElevatedButton(
          onPressed: () {
            // TODO: View case action
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2979FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 10,
            ),
            elevation: 0,
          ),
          child: Text(
            'View Case',
            style: AppTypography.button(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        );
      case AccountStatus.cleared:
        return Text(
          'No action needed',
          style: AppTypography.bodySmall(
            color: Colors.grey.shade500,
          ).copyWith(fontStyle: FontStyle.italic),
        );
    }
  }
}
