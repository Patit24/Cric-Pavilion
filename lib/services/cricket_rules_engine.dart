import '../models/models.dart';

class CricketRulesEngine {
  /// Format legal balls into standard cricket notation (e.g., 86 balls -> "14.2")
  static String formatOvers(int legalBalls) {
    final completedOvers = legalBalls ~/ 6;
    final ballsInOver = legalBalls % 6;
    return '$completedOvers.$ballsInOver';
  }

  /// Check if the bowler is eligible according to ICC Law 17.8 and quotas
  static BowlerEligibilityResult validateBowler({
    required String bowlerId,
    required String? previousOverBowlerId,
    required List<Delivery> deliveries,
    required String inningsId,
    required int maxOversPerBowler,
  }) {
    // Law 17.8: No consecutive overs
    if (previousOverBowlerId != null && bowlerId == previousOverBowlerId) {
      return BowlerEligibilityResult(
        isEligible: false,
        reason: 'Law 17.8: Cannot bowl consecutive overs',
      );
    }

    // Quota check: max overs per bowler
    int legalBallsBowled = 0;
    for (final d in deliveries) {
      if (d.inningsId == inningsId && d.bowlerId == bowlerId && d.isLegal && !d.isUndone) {
        legalBallsBowled++;
      }
    }

    final oversCompleted = legalBallsBowled ~/ 6;
    if (oversCompleted >= maxOversPerBowler) {
      return BowlerEligibilityResult(
        isEligible: false,
        reason: 'Max quota reached ($maxOversPerBowler ov)',
        ballsBowled: legalBallsBowled,
      );
    }

    return BowlerEligibilityResult(
      isEligible: true,
      ballsBowled: legalBallsBowled,
    );
  }

  /// Get the ID of the bowler who bowled the most recently completed over
  static String? getPreviousOverBowlerId({
    required List<Delivery> deliveries,
    required String inningsId,
    required int legalBalls,
  }) {
    if (legalBalls < 6) return null;
    final completedOverIndex = (legalBalls ~/ 6) - 1;
    if (completedOverIndex < 0) return null;

    final overDeliveries = deliveries
        .where((d) => d.inningsId == inningsId && d.overNumber == completedOverIndex && !d.isUndone)
        .toList();

    if (overDeliveries.isNotEmpty) {
      return overDeliveries.last.bowlerId;
    }
    return null;
  }

  /// Filter out batsmen who have already been dismissed or are currently on crease
  static List<Player> getAvailableIncomingBatsmen({
    required List<Player> teamPlayers,
    required List<Delivery> deliveries,
    required String inningsId,
    required String? currentStrikerId,
    required String? currentNonStrikerId,
    String? dismissedPlayerId,
  }) {
    final dismissedPlayerIds = <String>{};
    if (dismissedPlayerId != null) dismissedPlayerIds.add(dismissedPlayerId);

    for (final d in deliveries) {
      if (d.inningsId == inningsId && d.isWicket && !d.isUndone && d.dismissedPlayerId != null) {
        dismissedPlayerIds.add(d.dismissedPlayerId!);
      }
    }

    return teamPlayers.where((p) {
      if (dismissedPlayerIds.contains(p.id)) return false;
      if (p.id == currentStrikerId && p.id != dismissedPlayerId) return false;
      if (p.id == currentNonStrikerId && p.id != dismissedPlayerId) return false;
      return true;
    }).toList();
  }
}

class BowlerEligibilityResult {
  final bool isEligible;
  final String? reason;
  final int ballsBowled;

  BowlerEligibilityResult({
    required this.isEligible,
    this.reason,
    this.ballsBowled = 0,
  });

  String get oversStr => CricketRulesEngine.formatOvers(ballsBowled);
}
